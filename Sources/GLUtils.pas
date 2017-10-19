{$mode objfpc}
{$modeswitch advancedrecords}

unit GLUtils;
interface
uses
	Classes,
	GLTypes, GL, GLExt, SysUtils, StrUtils, Math,
	UArray, UGeometry, UDictionary, UTypes, UObject;

type
	TShader = class (TObject)
		public
			programID: GLuint;
		public
			constructor Create (vertexShaderPath, fragmentShaderPath: string);
			procedure Compile;
			procedure Use;
			
			{ Uniforms }
			procedure SetUniformMat4 (name: pchar; value: pointer); inline;
			procedure SetUniformVec3 (name: pchar; value: pointer); inline; overload;
			procedure SetUniformVec3 (name: pchar; value: TVec3); inline; overload;
			procedure SetUniformFloat (name: pchar; value: GLfloat); inline;
			procedure SetUniformInt (name: pchar; value: GLint); inline;
			
		protected
			procedure Deallocate; override;
		private type TUniformDictionary = specialize TGenericDictionary<GLint>;
		private
			vertexShaderID: GLuint;
			fragmentShaderID: GLuint;
			uniforms: TUniformDictionary;
			function GetUniformLocation (name: pchar): GLint; inline;
	end;

type
	TBitmapImage = class (TObject)
		public
			width: integer;
			height: integer;
		public
			constructor Create (path: string);
		protected
			procedure Deallocate; override;
		private
			bytes: pointer;
	end;
	
type
	TTextureBase = class (TObject)
		public
			texture: GLuint;
		public
			procedure Bind (textureUnit: integer = 0); virtual;
		protected
			procedure Deallocate; override;
	end;	
	TTextureList = specialize TDynamicList<TTextureBase>;
	
type
	TTexture2D = class (TTextureBase)
		public
			constructor Create (path: string; filter: GLint = GL_NEAREST; mipMap: boolean = true);
			procedure Bind (textureUnit: integer = 0); override;
		protected
			procedure Deallocate; override;
		private
			image: TBitmapImage;
	end;
	
type
	TTextureCubeMap = class (TTextureBase)
		public
			constructor Create (directory: string; names: array of string; filter: GLint = GL_NEAREST);
			procedure Bind (textureUnit: integer = 0); override;
		protected
			procedure Deallocate; override;
		private
			images: TArray;
	end;

type
	generic TGenericVertex<P, T, N> = record
		pos: P;
		col: TVec3;
		tex: T;
		nrm: N;
		tan: TVec3;
	end;
	TVertex2 = specialize TGenericVertex<TVec2, TVec2, TVec2>;
	TVertex3 = specialize TGenericVertex<TVec3, TVec2, TVec3>;
	TVertexCubeMap = specialize TGenericVertex<TVec3, TVec3, TVec3>;

type
	TMesh = record
		public const TIndexType = GL_UNSIGNED_INT;
		public type TVertexIndex = GLuint;
		public type TVertexType = GLfloat;
		public type TVertexAttribType = integer;
		public
			vertexAttribs: array of TVertexAttribType;
			vertexSize: integer;
			v: array of TVertexType;
			ind: array of TVertexIndex;
		public
			{class function MakeCube: TMesh; static; inline;
			class function MakePlane: TMesh; static; inline;
			class function MakeFlatPlane: TMesh; static; inline;
			class function MakeQuad (rect: TRect): TMesh; static; inline;}
			
			{ Constructors }
			class function LoadOBJModel (path: string; normalMap: boolean = false): TMesh; static;
			
			constructor Create (attribs: array of TVertexAttribType);
			
			{ Building }
			procedure AddVertexAttribute (value: TVec2); overload;
			procedure AddVertexAttribute (value: TVec3); overload;			
			
			procedure AddVertex (vertex: TVertex3);
			procedure AddIndex (index: TVertexIndex);
			procedure SetIndicies (count: integer);
				
			{ Getters }		
			function VerticiesByteSize: GLsizeiptr; 
			function IndiciesByteSize: GLsizeiptr; 
			function Elements: TVertexIndex;
			function VertexPtr: Pointer; 
			function IndexPtr: Pointer; 
		private
			function GetVertex(const pIndex:integer):TVertexType; inline;
		public
			property Verticies[const pIndex:integer]:TVertexType read GetVertex; default;
	end;
	
type
	TMaterial = record
		public
			shineDamper: TScalar;
			reflectivity: TScalar;
			textures: TTextureList;
			color: TVec3;
		private
			id: integer;
		public
			constructor Create (_shineDamper: TScalar; _reflectivity: TScalar; _textures: array of TTextureBase);
			class operator = (a, b: TMaterial): boolean; 
			procedure AddTexture (texture: TTextureBase);
	end;	
	TMaterialPtr = ^TMaterial;
	
type
	TModel = class (TObject)
		public
			mesh: TMesh;
			material: TMaterial;
			shader: TShader;
			id: integer;
		public
			constructor Create (_mesh: TMesh; _material: TMaterial; _shader: TShader; _id: integer = -1); overload;
			procedure Prepare;
			procedure Draw;
			procedure Bind;
			procedure Unbind;
		protected
			procedure Deallocate; override;
		private
			vertexBufferID: GLuint;
			indexArrayBufferID: GLuint;
			vao: GLuint;
			function AddVertexAttribPointer (attrib: integer; count, size, kind: integer; var offset: pointer): integer;
	end;
	
type
	TCamera = record
		private
			const MOVEMENT_SPEED = 0.3;
			const ROTATIONAL_SPEED = 0.005;
		private
			m_position: TVec3;
			m_worldToViewMatrix: TMat4;
			procedure SetPosition (newValue: TVec3);
		public
			property position: TVec3 read m_position write SetPosition;
			property worldToViewMatrix: TMat4 read m_worldToViewMatrix;
		public
			procedure Reset;
			procedure MouseUpdate (newMousePosition: TVec2);
			procedure ZoomBy (amount: TScalar);
			
			procedure MoveForward;
			procedure MoveBackward;
			procedure StrafeLeft;
			procedure StrafeRight;
			procedure MoveUp;
			procedure MoveDown;
			procedure RotateLeft;
			procedure RotateRight;
			
		private
			oldMousePosition: TVec2;
			strafeDirection: TVec3;
			viewDirection: TVec3;
			
			procedure UpdateMatrix;
	end;

procedure GLFatal (messageString: string = 'Fatal OpenGL error'); 

implementation
uses
	BeRoPNG;

var
	CurrentShaderProgram: GLuint = -1;

{=============================================}
{@! ___UTILS___ } 
{=============================================}
		
procedure GLFatal (messageString: string = 'Fatal OpenGL error'); 
var
	error: GLenum;
begin
	error := glGetError();
	if error <> GL_NO_ERROR then
		Fatal(messageString+' '+IntToStr(error));
end;

{=============================================}
{@! ___BITMAP IMAGE___ } 
{=============================================}
constructor TBitmapImage.Create (path: string);
type
	TPNGDataArray = array[0..0] of TPNGPixel;
	PPNGDataArray = ^TPNGDataArray;
var
	f: file;
	buffer: pointer;
	i: integer;
begin
	try
		AssignFile(f, path);
		FileMode := fmOpenRead;
	  Reset(f, 1);
	  buffer := GetMem(FileSize(f));
	  BlockRead(f, buffer^, FileSize(f));
	  CloseFile(f);
		writeln('loaded ', path, ' = ', MemSize(buffer));
		if not LoadPNG(buffer, MemSize(buffer), bytes, width, height, false) then
			raise Exception.Create('LoadPNG: failed to load bytes.');
		FreeMem(buffer);
  except
    on E:Exception do
			raise Exception.Create('LoadPNG: '+E.Message+' ('+path+')');
  end;
	Initialize;
end;

procedure TBitmapImage.Deallocate;
begin
	FreeMem(bytes);
	inherited Deallocate;
end;

{=============================================}
{@! ___TEXTURES___ } 
{=============================================}
procedure TTextureBase.Bind (textureUnit: integer = 0);
begin
	case textureUnit of
		0: 
			glActiveTexture(GL_TEXTURE0);
		1: 
			glActiveTexture(GL_TEXTURE1);
		2: 
			glActiveTexture(GL_TEXTURE2);
	end;
end;

procedure TTextureBase.Deallocate;
begin
	glDeleteTextures(1, @texture);
	inherited Deallocate;
end;

procedure TTexture2D.Bind (textureUnit: integer = 0);
begin
	inherited Bind(textureUnit);
	glBindTexture(GL_TEXTURE_2D, texture);
end;

constructor TTexture2D.Create (path: string; filter: GLint = GL_NEAREST; mipMap: boolean = true);
var
	amount: GLfloat = 0;
begin
	image := TBitmapImage.Create(path);
	
	glEnable(GL_TEXTURE_2D);
	glGenTextures(1, @texture);
	Bind;
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image.width, image.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, image.bytes);
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
	
	if mipMap then
		begin
			//https://www.youtube.com/watch?v=Pdn13TRWEM0&index=41&list=PLRIWtICgwaX0u7Rf9zkZhLoLuZVfUksDP
			glGenerateMipmap(GL_TEXTURE_2D);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);

			// TODO: why doesn't load work? the float returns 16 so does it work?
			if {Load_GL_EXT_texture_filter_anisotropic}true then
				begin
					glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, @amount);
					amount := Min(4, amount);
					glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, amount);
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_LOD_BIAS, 0);
				end
			else
				begin
					//writeln('failed to load Load_GL_EXT_texture_filter_anisotropic');
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_LOD_BIAS, -1);
				end;
		end
	else
		begin
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
		end;
	
		
	Initialize;
end;

procedure TTexture2D.Deallocate;
begin
	glDeleteTextures(1, @texture);
	image.Release;
	inherited Deallocate;
end;

procedure TTextureCubeMap.Bind (textureUnit: integer = 0);
begin
	inherited Bind(textureUnit);
	glBindTexture(GL_TEXTURE_CUBE_MAP, texture);
end;

constructor TTextureCubeMap.Create (directory: string; names: array of string; filter: GLint = GL_NEAREST);
var
	i: integer;
	image: TBitmapImage;
begin
	images := TArray.Create;
	
	glEnable(GL_TEXTURE_CUBE_MAP);
	glGenTextures(1, @texture);
	Bind;
	
	for i := 0 to length(names) - 1 do
		begin
			image := TBitmapImage.Create(directory+'/'+names[i]);
			glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGBA, image.width, image.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, image.bytes);
			images += image;
			image.Release;
		end;
		
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, filter);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, filter);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
end;	

procedure TTextureCubeMap.Deallocate;
begin
	images.Release;
	inherited Deallocate;
end;

{=============================================}
{@! ___MATERIAL___ } 
{=============================================}
var
	GlobalMaterialIDIndex: integer = 1;

procedure TMaterial.AddTexture (texture: TTextureBase);
begin
	textures += texture;
end;	
	
class operator TMaterial.= (a, b: TMaterial): boolean;
begin
	result := a.id = b.id;
end;

constructor TMaterial.Create (_shineDamper: TScalar; _reflectivity: TScalar; _textures: array of TTextureBase);
var
	texture: TTextureBase;
begin
	shineDamper := _shineDamper;
	reflectivity := _reflectivity;
	textures := TTextureList.Make;
	for pointer(texture) in _textures do
		textures += texture;
	color := Vec3(1, 1, 1);
	id := GlobalMaterialIDIndex;
	GlobalMaterialIDIndex += 1;
end;

{=============================================}
{@! ___MODEL___ } 
{=============================================}

procedure TModel.Draw; 
begin
	glDrawElements(GL_TRIANGLES, mesh.Elements, mesh.TIndexType, nil);
end;

procedure TModel.Bind; 
var
	i: integer;
	texture: TTextureBase;
begin
	glBindVertexArray(vao);
	
	for i := 0 to material.textures.High do
		material.textures[i].Bind(i);
		
	for i := 0 to High(mesh.vertexAttribs) do
		glEnableVertexAttribArray(i);
end;

procedure TModel.Unbind;
var
	i: integer;
begin
	glBindVertexArray(0);
	for i := 0 to High(mesh.vertexAttribs) do
		glDisableVertexAttribArray(i);
end;

function TModel.AddVertexAttribPointer (attrib: integer; count, size, kind: integer; var offset: pointer): integer; 
begin
	if size > 0 then
		Inc(offset, size);
	glEnableVertexAttribArray(attrib);
	glVertexAttribPointer(attrib, count, kind, GL_FALSE, mesh.vertexSize, offset);
	result := sizeof(mesh.TVertexType) * count
end;

procedure TModel.Prepare; 
var
	offset: pointer = nil;
	prevSize: integer = 0;
	i: integer;
begin
	glGenVertexArrays(1, @vao);
	glBindVertexArray(vao);
	
	// bind vertex array buffer
	glGenBuffers(1, @vertexBufferID);
	glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
	glBufferData(GL_ARRAY_BUFFER, mesh.VerticiesByteSize, mesh.VertexPtr, GL_STATIC_DRAW);
	
	offset := nil;
	prevSize := 0;
	
	// add vertex attributes from mesh
	for i := 0 to High(mesh.vertexAttribs) do
		prevSize := AddVertexAttribPointer(i, mesh.vertexAttribs[i], prevSize, GL_FLOAT, offset);

	// bind index array buffer
	glGenBuffers(1, @indexArrayBufferID);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexArrayBufferID);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, mesh.IndiciesByteSize, mesh.IndexPtr, GL_STATIC_DRAW);		
	
	Unbind;
end;

procedure TModel.Deallocate;
begin
	glDeleteBuffers(1, @indexArrayBufferID);
	glDeleteBuffers(1, @vertexBufferID);
	glDeleteVertexArrays(1, @vao);
	
	inherited Deallocate;
end;

var
	GlobalModelIDIndex: integer = 0;

constructor TModel.Create (_mesh: TMesh; _material: TMaterial; _shader: TShader; _id: integer = -1);
begin
	mesh := _mesh;
	material := _material;
	shader := _shader;
	if _id = -1 then
		begin
			id := GlobalModelIDIndex;
			GlobalModelIDIndex += 1;
			writeln('added model id: ', id);
		end
	else
		id := _id;
	Initialize;
end;

{=============================================}
{@! ___MESH___ } 
{=============================================}
function TMesh.VertexPtr: Pointer; 
begin
	result := @v[0];
end;

function TMesh.IndexPtr: Pointer; 
begin
	result := @ind[0];
end;

function TMesh.Elements: TVertexIndex; 
begin
	result := Length(ind);
end;

function TMesh.VerticiesByteSize: GLsizeiptr; 
begin
	result := sizeof(TVertexType) * length(v);
end;

function TMesh.IndiciesByteSize: GLsizeiptr; 
begin
	result := sizeof(TVertexIndex) * length(ind);
end;

function TMesh.GetVertex(const pIndex:integer): TVertexType;
begin
	result := v[pIndex];
end;

{procedure TMesh.SetVerticies (count: integer); 
begin
	SetLength(v, count);
	FillChar(v[0], Sizeof(TVertexType) * Length(v), 0);
end;}

constructor TMesh.Create (attribs: array of TVertexAttribType);
var
	i: integer;
begin
	SetLength(v, 0);
	SetLength(ind, 0);
	SetLength(vertexAttribs, Length(attribs));
	vertexSize := 0;
	for i := 0 to High(attribs) do
		begin
			vertexAttribs[i] := attribs[i];
			vertexSize += Sizeof(TVertexType) * attribs[i];
		end;
end;

procedure TMesh.AddVertexAttribute (value: TVec2);
var
	index: integer;
begin
	index := Length(v);
	SetLength(v, Length(v) + 2);
	v[index] := value.x;
	v[index + 1] := value.y;
end;

procedure TMesh.AddVertexAttribute (value: TVec3);
var
	index: integer;
begin
	index := Length(v);
	SetLength(v, Length(v) + 3);
	v[index] := value.x;
	v[index + 1] := value.y;
	v[index + 2] := value.z;
end;

procedure TMesh.AddVertex (vertex: TVertex3);
begin
	AddVertexAttribute(vertex.pos);
	AddVertexAttribute(vertex.col);
	AddVertexAttribute(vertex.tex);
	AddVertexAttribute(vertex.nrm);
end;

procedure TMesh.AddIndex (index: TVertexIndex);
begin
	SetLength(ind, Length(ind) + 1);
	ind[High(ind)] := index;
end;

procedure TMesh.SetIndicies (count: integer);
begin
	SetLength(ind, count);
	FillChar(ind[0], Sizeof(TVertexIndex) * Length(ind), 0);
end;

{
class function TMesh.MakeCube: TMesh;
var
	stackIndices: array[0..35] of TVertexIndex = (
		0,   1,  2,  0,  2,  3, // Top
		4,   5,  6,  4,  6,  7, // Front
		8,   9, 10,  8, 10, 11, // Right
		12, 13, 14, 12, 14, 15, // Left
		16, 17, 18, 16, 18, 19, // Back
		20, 22, 21, 20, 23, 22 	// Bottom
	);
	i: integer;
begin
	result.SetVerticies(24);
	
	result.v[0].pos := TVec3.Make(-1.0, +1.0, +1.0);
	result.v[0].col := TVec3.Make(+1.0, +0.0, +0.0);
	result.v[0].nrm := TVec3.Make(+0.0, +1.0, +0.0);
	result.v[1].pos := TVec3.Make(+1.0, +1.0, +1.0);
	result.v[1].col := TVec3.Make(+0.0, +1.0, +0.0);
	result.v[1].nrm := TVec3.Make(+0.0, +1.0, +0.0);
	result.v[2].pos := TVec3.Make(+1.0, +1.0, -1.0);
	result.v[2].col := TVec3.Make(+0.0, +0.0, +1.0);
	result.v[2].nrm := TVec3.Make(+0.0, +1.0, +0.0);
	result.v[3].pos := TVec3.Make(-1.0, +1.0, -1.0);
	result.v[3].col := TVec3.Make(+1.0, +1.0, +1.0);
	result.v[3].nrm := TVec3.Make(+0.0, +1.0, +0.0);
	      
	result.v[4].pos := TVec3.Make(-1.0, +1.0, -1.0);
	result.v[4].col := TVec3.Make(+1.0, +0.0, +1.0);
	result.v[4].nrm := TVec3.Make(+0.0, +0.0, -1.0);
	result.v[5].pos := TVec3.Make(+1.0, +1.0, -1.0);
	result.v[5].col := TVec3.Make(+0.0, +0.5, +0.2);
	result.v[5].nrm := TVec3.Make(+0.0, +0.0, -1.0);
	result.v[6].pos := TVec3.Make(+1.0, -1.0, -1.0);
	result.v[6].col := TVec3.Make(+0.8, +0.6, +0.4);
	result.v[6].nrm := TVec3.Make(+0.0, +0.0, -1.0);
	result.v[7].pos := TVec3.Make(-1.0, -1.0, -1.0);
	result.v[7].col := TVec3.Make(+0.3, +1.0, +0.5);
	result.v[7].nrm := TVec3.Make(+0.0, +0.0, -1.0);
	
	result.v[8].pos := TVec3.Make(+1.0, +1.0, -1.0);
	result.v[8].col := TVec3.Make(+0.2, +0.5, +0.2);
	result.v[8].nrm := TVec3.Make(+1.0, +0.0, +0.0);
	result.v[9].pos := TVec3.Make(+1.0, +1.0, +1.0);
	result.v[9].col := TVec3.Make(+0.9, +0.3, +0.7);
	result.v[9].nrm := TVec3.Make(+1.0, +0.0, +0.0);
	result.v[10].pos := TVec3.Make(+1.0, -1.0, +1.0);
	result.v[10].col := TVec3.Make(+0.3, +0.7, +0.5);
	result.v[10].nrm := TVec3.Make(+1.0, +0.0, +0.0);
	result.v[11].pos := TVec3.Make(+1.0, -1.0, -1.0);
	result.v[11].col := TVec3.Make(+0.5, +0.7, +0.5);
	result.v[11].nrm := TVec3.Make(+1.0, +0.0, +0.0);
	
	result.v[12].pos := TVec3.Make(-1.0, +1.0, +1.0);
	result.v[12].col := TVec3.Make(+0.7, +0.8, +0.2);
	result.v[12].nrm := TVec3.Make(-1.0, +0.0, +0.0);
	result.v[13].pos := TVec3.Make(-1.0, +1.0, -1.0);
	result.v[13].col := TVec3.Make(+0.5, +0.7, +0.3);
	result.v[13].nrm := TVec3.Make(-1.0, +0.0, +0.0);
	result.v[14].pos := TVec3.Make(-1.0, -1.0, -1.0);
	result.v[14].col := TVec3.Make(+0.4, +0.7, +0.7);
	result.v[14].nrm := TVec3.Make(-1.0, +0.0, +0.0);
	result.v[15].pos := TVec3.Make(-1.0, -1.0, +1.0);
	result.v[15].col := TVec3.Make(+0.2, +0.5, +1.0);
	result.v[15].nrm := TVec3.Make(-1.0, +0.0, +0.0);
	
	result.v[16].pos := TVec3.Make(+1.0, +1.0, +1.0);
	result.v[16].col := TVec3.Make(+0.6, +1.0, +0.7);
	result.v[16].nrm := TVec3.Make(+0.0, +0.0, +1.0);
	result.v[17].pos := TVec3.Make(-1.0, +1.0, +1.0);
	result.v[17].col := TVec3.Make(+0.6, +0.4, +0.8);
	result.v[17].nrm := TVec3.Make(+0.0, +0.0, +1.0);
	result.v[18].pos := TVec3.Make(-1.0, -1.0, +1.0);
	result.v[18].col := TVec3.Make(+0.2, +0.8, +0.7);
	result.v[18].nrm := TVec3.Make(+0.0, +0.0, +1.0);
	result.v[19].pos := TVec3.Make(+1.0, -1.0, +1.0);
	result.v[19].col := TVec3.Make(+0.2, +0.7, +1.0);
	result.v[19].nrm := TVec3.Make(+0.0, +0.0, +1.0);
	
	result.v[20].pos := TVec3.Make(+1.0, -1.0, -1.0);
	result.v[20].col := TVec3.Make(+0.8, +0.3, +0.7);
	result.v[20].nrm := TVec3.Make(+0.0, -1.0, +0.0);
	result.v[21].pos := TVec3.Make(-1.0, -1.0, -1.0);
	result.v[21].col := TVec3.Make(+0.8, +0.9, +0.5);
	result.v[21].nrm := TVec3.Make(+0.0, -1.0, +0.0);
	result.v[22].pos := TVec3.Make(-1.0, -1.0, +1.0);
	result.v[22].col := TVec3.Make(+0.5, +0.8, +0.5);
	result.v[22].nrm := TVec3.Make(+0.0, -1.0, +0.0);
	result.v[23].pos := TVec3.Make(+1.0, -1.0, +1.0);
	result.v[23].col := TVec3.Make(+0.9, +1.0, +0.2);
	result.v[23].nrm := TVec3.Make(+0.0, -1.0, +0.0);
	
	SetLength(result.ind, Length(stackIndices));
	result.ind := stackIndices;
end;

class function TMesh.MakeQuad (rect: TRect): TMesh;
var
	stackIndices: array[0..5] of TVertexIndex = (
		0,  1,  2,  0,  2,  3
	);
begin
	result.SetVerticies(4);
	
	result.v[0].pos := TVec3.Make(rect.GetMinX, rect.GetMinY, -1);
	result.v[1].pos := TVec3.Make(rect.GetMaxX, rect.GetMinY, -1);
	result.v[2].pos := TVec3.Make(rect.GetMaxX, rect.GetMaxY, -1);
	result.v[3].pos := TVec3.Make(rect.GetMinX, rect.GetMaxY, -1);
	
	SetLength(result.ind, Length(stackIndices));
	result.ind := stackIndices;
end;

class function TMesh.MakePlane: TMesh;
var
	stackIndices: array[0..5] of TVertexIndex = (
		0,  1,  2,  0,  2,  3
	);
begin
	result.SetVerticies(4);
	
	result.v[0].pos := TVec3.Make(-1.0, +1.0, -1.0);
	result.v[1].pos := TVec3.Make(+1.0, +1.0, -1.0);
	result.v[2].pos := TVec3.Make(+1.0, -1.0, -1.0);
	result.v[3].pos := TVec3.Make(-1.0, -1.0, -1.0);
	
	SetLength(result.ind, Length(stackIndices));
	result.ind := stackIndices;
end;

class function TMesh.MakeFlatPlane: TMesh;
var
	stackIndices: array[0..5] of TVertexIndex = (
		0,  1,  2,  0,  2,  3
	);
begin
	result.SetVerticies(4);
	
	// bottom
	result.v[0].pos := TVec3.Make(+1.0, 0, -1.0);
	result.v[1].pos := TVec3.Make(-1.0, 0, -1.0);
	result.v[2].pos := TVec3.Make(-1.0, 0, +1.0);
	result.v[3].pos := TVec3.Make(+1.0, 0, +1.0);
	
	SetLength(result.ind, Length(stackIndices));
	result.ind := stackIndices;
end;

class function TMesh.MakeCube: TMesh;
var
	stackIndices: array[0..35] of TVertexIndex = (
		0,   1,  2,  0,  2,  3, // Top
		4,   5,  6,  4,  6,  7, // Front
		8,   9, 10,  8, 10, 11, // Right
		12, 13, 14, 12, 14, 15, // Left
		16, 17, 18, 16, 18, 19, // Back
		20, 22, 21, 20, 23, 22 	// Bottom
	);
	i: integer;
begin
	result.SetVerticies(24);
	
	result.v[0].pos := TVec3.Make(-1.0, +1.0, +1.0);
	result.v[0].col := TVec3.Make(+1.0, +0.0, +0.0);
	result.v[0].nrm := TVec3.Make(+0.0, +1.0, +0.0);
	result.v[1].pos := TVec3.Make(+1.0, +1.0, +1.0);
	result.v[1].col := TVec3.Make(+0.0, +1.0, +0.0);
	result.v[1].nrm := TVec3.Make(+0.0, +1.0, +0.0);
	result.v[2].pos := TVec3.Make(+1.0, +1.0, -1.0);
	result.v[2].col := TVec3.Make(+0.0, +0.0, +1.0);
	result.v[2].nrm := TVec3.Make(+0.0, +1.0, +0.0);
	result.v[3].pos := TVec3.Make(-1.0, +1.0, -1.0);
	result.v[3].col := TVec3.Make(+1.0, +1.0, +1.0);
	result.v[3].nrm := TVec3.Make(+0.0, +1.0, +0.0);
	      
	result.v[4].pos := TVec3.Make(-1.0, +1.0, -1.0);
	result.v[4].col := TVec3.Make(+1.0, +0.0, +1.0);
	result.v[4].nrm := TVec3.Make(+0.0, +0.0, -1.0);
	result.v[5].pos := TVec3.Make(+1.0, +1.0, -1.0);
	result.v[5].col := TVec3.Make(+0.0, +0.5, +0.2);
	result.v[5].nrm := TVec3.Make(+0.0, +0.0, -1.0);
	result.v[6].pos := TVec3.Make(+1.0, -1.0, -1.0);
	result.v[6].col := TVec3.Make(+0.8, +0.6, +0.4);
	result.v[6].nrm := TVec3.Make(+0.0, +0.0, -1.0);
	result.v[7].pos := TVec3.Make(-1.0, -1.0, -1.0);
	result.v[7].col := TVec3.Make(+0.3, +1.0, +0.5);
	result.v[7].nrm := TVec3.Make(+0.0, +0.0, -1.0);
	
	result.v[8].pos := TVec3.Make(+1.0, +1.0, -1.0);
	result.v[8].col := TVec3.Make(+0.2, +0.5, +0.2);
	result.v[8].nrm := TVec3.Make(+1.0, +0.0, +0.0);
	result.v[9].pos := TVec3.Make(+1.0, +1.0, +1.0);
	result.v[9].col := TVec3.Make(+0.9, +0.3, +0.7);
	result.v[9].nrm := TVec3.Make(+1.0, +0.0, +0.0);
	result.v[10].pos := TVec3.Make(+1.0, -1.0, +1.0);
	result.v[10].col := TVec3.Make(+0.3, +0.7, +0.5);
	result.v[10].nrm := TVec3.Make(+1.0, +0.0, +0.0);
	result.v[11].pos := TVec3.Make(+1.0, -1.0, -1.0);
	result.v[11].col := TVec3.Make(+0.5, +0.7, +0.5);
	result.v[11].nrm := TVec3.Make(+1.0, +0.0, +0.0);
	
	result.v[12].pos := TVec3.Make(-1.0, +1.0, +1.0);
	result.v[12].col := TVec3.Make(+0.7, +0.8, +0.2);
	result.v[12].nrm := TVec3.Make(-1.0, +0.0, +0.0);
	result.v[13].pos := TVec3.Make(-1.0, +1.0, -1.0);
	result.v[13].col := TVec3.Make(+0.5, +0.7, +0.3);
	result.v[13].nrm := TVec3.Make(-1.0, +0.0, +0.0);
	result.v[14].pos := TVec3.Make(-1.0, -1.0, -1.0);
	result.v[14].col := TVec3.Make(+0.4, +0.7, +0.7);
	result.v[14].nrm := TVec3.Make(-1.0, +0.0, +0.0);
	result.v[15].pos := TVec3.Make(-1.0, -1.0, +1.0);
	result.v[15].col := TVec3.Make(+0.2, +0.5, +1.0);
	result.v[15].nrm := TVec3.Make(-1.0, +0.0, +0.0);
	
	result.v[16].pos := TVec3.Make(+1.0, +1.0, +1.0);
	result.v[16].col := TVec3.Make(+0.6, +1.0, +0.7);
	result.v[16].nrm := TVec3.Make(+0.0, +0.0, +1.0);
	result.v[17].pos := TVec3.Make(-1.0, +1.0, +1.0);
	result.v[17].col := TVec3.Make(+0.6, +0.4, +0.8);
	result.v[17].nrm := TVec3.Make(+0.0, +0.0, +1.0);
	result.v[18].pos := TVec3.Make(-1.0, -1.0, +1.0);
	result.v[18].col := TVec3.Make(+0.2, +0.8, +0.7);
	result.v[18].nrm := TVec3.Make(+0.0, +0.0, +1.0);
	result.v[19].pos := TVec3.Make(+1.0, -1.0, +1.0);
	result.v[19].col := TVec3.Make(+0.2, +0.7, +1.0);
	result.v[19].nrm := TVec3.Make(+0.0, +0.0, +1.0);
	
	result.v[20].pos := TVec3.Make(+1.0, -1.0, -1.0);
	result.v[20].col := TVec3.Make(+0.8, +0.3, +0.7);
	result.v[20].nrm := TVec3.Make(+0.0, -1.0, +0.0);
	result.v[21].pos := TVec3.Make(-1.0, -1.0, -1.0);
	result.v[21].col := TVec3.Make(+0.8, +0.9, +0.5);
	result.v[21].nrm := TVec3.Make(+0.0, -1.0, +0.0);
	result.v[22].pos := TVec3.Make(-1.0, -1.0, +1.0);
	result.v[22].col := TVec3.Make(+0.5, +0.8, +0.5);
	result.v[22].nrm := TVec3.Make(+0.0, -1.0, +0.0);
	result.v[23].pos := TVec3.Make(+1.0, -1.0, +1.0);
	result.v[23].col := TVec3.Make(+0.9, +1.0, +0.2);
	result.v[23].nrm := TVec3.Make(+0.0, -1.0, +0.0);
	
	SetLength(result.ind, Length(stackIndices));
	result.ind := stackIndices;
end;

}

//https://www.youtube.com/watch?v=YKFYtekgnP8&list=PLRIWtICgwaX0u7Rf9zkZhLoLuZVfUksDP&index=10
//https://pastebin.com/b5EuEyxj
//https://en.wikipedia.org/wiki/Wavefront_.obj_file

type
	TMaterialDictionary = specialize TGenericDictionary<TMaterial>;

function LoadMTL (path: string): TMaterialDictionary; 
var
	line: string;
	lines: TStringList;
	parts: TDynamicStringList;
	name: string;
	material: TMaterial;
	materials: TMaterialDictionary = nil;
begin
	try
		writeln('load mtl ', path);
		lines := TStringList.Create;
	  lines.LoadFromFile(path);
		materials := TMaterialDictionary.Create;

		for line in lines do
			begin
				parts := line.Split(' ');
				if parts.Count = 0 then
					continue;
				if parts[0] = 'newmtl' then
					begin
						material := TMaterial.Create(0, 0, []);
						name := Copy(line, length('newmtl') + 2, length(line));
					end
				else if parts[0] = 'Kd' then
					material.color := Vec3(parts[1].Single, parts[2].Single, parts[3].Single)
				else if parts[0] = 'illum' then
					begin
						writeln('output material ', name, ' ', material.color.str);
						materials.SetValue(name, material);
					end;
			end;
		lines.Free;
  except
    on E:Exception do
			raise Exception.Create('LoadMTL: '+E.Message+' ('+path+')');
  end;

	result := materials;
end;

type
	TOBJVertex = class(TObject)
		private const NO_INDEX = -1;
		private type TVec3List = specialize TDynamicList<TVec3>;
		public
			position: TVec3;
			textureIndex: integer;
			normalIndex: integer;
			duplicateVertex: TOBJVertex;
			index: integer;
			tangents: TVec3List;
			averagedTangent: TVec3;
		public
			constructor Create (_index: integer; _position: TVec3);
			function IsSet: boolean;
			function HasSameTextureAndNormal (textureIndexOther, normalIndexOther: integer): boolean; 
			function Duplicate (newIndex: integer): TOBJVertex;
			procedure AddTangent (tangent: TVec3);
			procedure AverageTangents;
	end;
	TOBJVertexArray = specialize TGenericArray<TOBJVertex>;

procedure TOBJVertex.AddTangent (tangent: TVec3);
begin
	tangents += tangent;
end;

function TOBJVertex.Duplicate (newIndex: integer): TOBJVertex; 
begin
	result := TOBJVertex.Create(newIndex, position);
	result.tangents := tangents;
end;	
 
procedure TOBJVertex.AverageTangents;
var
	tangent: TVec3;
	i: integer;
begin
	if tangents.Empty then
		exit;
	averagedTangent := Vec3(0, 0, 0);
	for i := 0 to tangents.High do
		averagedTangent += tangents[i];
	averagedTangent := averagedTangent.Normalize;
end;
	
constructor TOBJVertex.Create (_index: integer; _position: TVec3);
begin
	index := _index;
	position := _position;
	textureIndex := NO_INDEX;
	normalIndex := NO_INDEX;
	duplicateVertex := nil;
	tangents := TVec3List.Make;
	averagedTangent := Vec3(0, 0, 0);
	Initialize;
end;

function TOBJVertex.IsSet: boolean;
begin
	result := (textureIndex <> NO_INDEX) and (normalIndex <> NO_INDEX);
end;

function TOBJVertex.HasSameTextureAndNormal (textureIndexOther, normalIndexOther: integer): boolean; 
begin
	result := (textureIndexOther = textureIndex) and (normalIndexOther = normalIndex);
end;

class function TMesh.LoadOBJModel (path: string; normalMap: boolean = false): TMesh; 

function DealWithAlreadyProcessedVertex (previousVertex: TOBJVertex; newTextureIndex, newNormalIndex: integer; indices: TIntegerArray; vertices: TOBJVertexArray): TOBJVertex;
var
	duplicateVertex: TOBJVertex;
	anotherVertex: TOBJVertex;
begin
	if previousVertex.HasSameTextureAndNormal(newTextureIndex, newNormalIndex) then
		begin
			indices += previousVertex.index;
			result := previousVertex;
		end
	else
		begin
			anotherVertex := previousVertex.duplicateVertex;
			if anotherVertex <> nil then
				result := DealWithAlreadyProcessedVertex(anotherVertex, newTextureIndex, newNormalIndex, indices, vertices)
			else
				begin
					duplicateVertex := TOBJVertex.Create(vertices.Count, previousVertex.position);
          duplicateVertex.textureIndex := newTextureIndex;
          duplicateVertex.normalIndex := newNormalIndex;
          previousVertex.duplicateVertex := duplicateVertex;
          vertices.AddValue(duplicateVertex);
          indices += duplicateVertex.index;
					duplicateVertex.Release;
					result := duplicateVertex;
				end;
		end;
end;

procedure CalculateTangents (var v0, v1, v2: TOBJVertex; textures: TVec2Array); 
var
	delatPos1, delatPos2: TVec3;
	uv0, uv1, uv2: TVec2;
	deltaUv1, deltaUv2: TVec2;
	r: TScalar;
	tangent: TVec3;
begin
	delatPos1 := v1.position - v0.position;
	delatPos2 := v2.position - v0.position;
	uv0 := textures[v0.textureIndex];
  uv1 := textures[v1.textureIndex];
  uv2 := textures[v2.textureIndex];
  deltaUv1 := uv1 - uv0;
  deltaUv2 := uv2 - uv0;
	
	r := 1.0 / (deltaUv1.x * deltaUv2.y - deltaUv1.y * deltaUv2.x);
	delatPos1 *= deltaUv2.y;
	delatPos2 *= deltaUv1.y;
	tangent := (delatPos1 - delatPos2) * r;

	v0.AddTangent(tangent);
	v1.AddTangent(tangent);
	v2.AddTangent(tangent);
end;

function ProcessFace (vertices: TOBJVertexArray; indices: TIntegerArray; face: TDynamicStringList): TOBJVertex;
var
	index: integer;
	textureIndex: integer;
	normalIndex: integer;
	currentVertex: TOBJVertex;
begin
	index := face[0].Int - 1;
	currentVertex := vertices[index];
	textureIndex := face[1].Int - 1;
	normalIndex := face[2].Int - 1;
	if not currentVertex.IsSet then
		begin
			currentVertex.textureIndex := textureIndex;
			currentVertex.normalIndex := normalIndex;
			indices += index;
			result := currentVertex;
		end
	else
		result := DealWithAlreadyProcessedVertex(currentVertex, textureIndex, normalIndex, indices, vertices);
end;

var
	lines: TStringList;
	line: string;
	
	vertices: TOBJVertexArray;
	textures: TVec2Array;
	normals: TVec3Array;
	indices: TIntegerArray;
	
	parts: TDynamicStringList;
	face: TDynamicStringList;
	vertex: TOBJVertex;
	newVertex: TVertex3;
	
	pos: TVec3;
	i: integer;
	mesh: TMesh;
	name, directory: string;
	material: TMaterial;
	materials: TMaterialDictionary = nil;
	v0, v1, v2: TOBJVertex;
begin	
	
	// pos3/color3/tex2/normal3
	if normalMap then
		mesh := TMesh.Create([3, 3, 2, 3, 3])
	else
		mesh := TMesh.Create([3, 3, 2, 3]);
	
	vertices := TOBJVertexArray.Create;
	textures := TVec2Array.Create;
	normals := TVec3Array.Create;
	indices := TIntegerArray.Create;
	
	material := Default(TMaterial);
	
	lines := TStringList.Create;
  lines.LoadFromFile(path);
	
	// process vertex data
	for line in lines do
		begin
			parts := line.Split(' ');
			if line.HasPrefix('mtllib ') then
				begin
					directory := ExtractFilePath(ExcludeTrailingPathDelimiter(path));
					name := System.Copy(line, length('mtllib') + 2, length(line));
					materials := LoadMTL(directory+name);
				end
			else if line.HasPrefix('v ') then
				begin
					vertex := TOBJVertex.Create(vertices.Count, Vec3(parts[1].Single, parts[2].Single, parts[3].Single));
					vertices.AddValue(vertex);
					vertex.Release;
				end
			else if line.HasPrefix('vt ') then
				// flip y-coord
				textures.AddValue(Vec2(parts[1].Single, 1-parts[2].Single))
			else if line.HasPrefix('vn ') then
				normals.AddValue(Vec3(parts[1].Single, parts[2].Single, parts[3].Single))
			else if line.HasPrefix('f ') then
				begin
					// TODO: start from this location instead of finding it again in the next loop
          break;
				end;
		end;

	// process faces
	for line in lines do
		begin
			// face
			if line.HasPrefix('usemtl ') and (materials <> nil) then
				begin
					name := System.Copy(line, length('usemtl') + 2, length(line));
					material := materials[name];
				end
			else if line.HasPrefix('f ') then
				begin
					parts := line.Split(' '); 
					v0 := ProcessFace(vertices, indices, parts[1].Split('/'));
					v1 := ProcessFace(vertices, indices, parts[2].Split('/'));
					v2 := ProcessFace(vertices, indices, parts[3].Split('/'));
					if normalMap then
						CalculateTangents(v0, v1, v2, textures);
				end;
		end;
	
	// remove unused vertices
	for vertex in vertices do
		begin
			if normalMap then
				vertex.AverageTangents;
			if not vertex.IsSet then
				begin
					vertex.textureIndex := 0;
					vertex.normalIndex := 0;
				end;
		end;
	
	for vertex in vertices do
		begin
			newVertex := Default(TVertex3);
			newVertex.pos := vertex.position;
			newVertex.tex := textures[vertex.textureIndex];
			newVertex.nrm := normals[vertex.normalIndex];
			newVertex.tan := vertex.averagedTangent;
			mesh.AddVertex(newVertex);	
			
			if normalMap then
				mesh.AddVertexAttribute(newVertex.tan);
		end;
	
	for i in indices do
		mesh.AddIndex(i);
			
	// cleanup
	ReleaseObject(materials);
	vertices.Release;
	textures.Release;
	normals.Release;
	indices.Release;
	lines.Free;
	
	result := mesh;
end;

{=============================================}
{@! ___CAMERA___ } 
{=============================================}

procedure TCamera.Reset;
begin
	viewDirection := Vec3(0, 0, -1);
	m_position := Vec3(0, 0, 0);
	UpdateMatrix;
end;

procedure TCamera.SetPosition (newValue: TVec3); 
begin
	m_position := newValue;
	UpdateMatrix;
end;

procedure TCamera.UpdateMatrix; 
begin
	m_worldToViewMatrix := TMat4.LookAt(position, position + viewDirection, TVec3.Up);
end;

procedure TCamera.ZoomBy (amount: TScalar);
begin
	m_position += viewDirection * amount;
	UpdateMatrix;
end;

procedure TCamera.MouseUpdate (newMousePosition: TVec2); 	
var
	mouseDelta: TVec2;
	rotator: TMat4;
begin
	mouseDelta := newMousePosition - oldMousePosition;

	if abs(mouseDelta.Magnitude) > 50.0 then
		begin
			oldMousePosition := newMousePosition;
			exit;
		end;
	
	strafeDirection := viewDirection.Cross(TVec3.Up);
	rotator := rotator.Rotate(-mouseDelta.x * ROTATIONAL_SPEED, TVec3.Up) *
						 rotator.Rotate(-mouseDelta.y * ROTATIONAL_SPEED, strafeDirection);
	viewDirection := TMat3.Create(rotator) * viewDirection;
	oldMousePosition := newMousePosition;
	UpdateMatrix;
end;

procedure TCamera.RotateLeft;
var
	rotator: TMat4;
begin
	strafeDirection := viewDirection.Cross(TVec3.Up);
	rotator := TMat4.Identity;
	rotator := rotator.Rotate(0.1 * MOVEMENT_SPEED, TVec3.Up);
	viewDirection := TMat3.Create(rotator) * viewDirection;
	UpdateMatrix;
end;

procedure TCamera.RotateRight;
var
	rotator: TMat4;
begin
	strafeDirection := viewDirection.Cross(TVec3.Up);
	rotator := TMat4.Identity;
	rotator := rotator.Rotate(-0.1 * MOVEMENT_SPEED, TVec3.Up);
	viewDirection := TMat3.Create(rotator) * viewDirection;
	UpdateMatrix;
end;

procedure TCamera.MoveForward;
begin
	m_position += viewDirection * MOVEMENT_SPEED;
	UpdateMatrix;
end;

procedure TCamera.MoveBackward;
begin
	m_position += viewDirection * -MOVEMENT_SPEED;
	UpdateMatrix;
end;

procedure TCamera.StrafeLeft;
begin
	m_position += strafeDirection * -MOVEMENT_SPEED;
	UpdateMatrix;
end;

procedure TCamera.StrafeRight;
begin
	m_position += strafeDirection * MOVEMENT_SPEED;
	UpdateMatrix;
end;

procedure TCamera.MoveUp;
begin
	m_position += TVec3.Up * MOVEMENT_SPEED;
	UpdateMatrix;
end;

procedure TCamera.MoveDown;
begin
	m_position += TVec3.Up * -MOVEMENT_SPEED;
	UpdateMatrix;
end;

{=============================================}
{@! ___SHADER___ } 
{=============================================}

function TShader.GetUniformLocation (name: pchar): GLint;
const
	kBaseIndex = 5000;
begin
	if uniforms = nil then
		uniforms := TUniformDictionary.Create;
	result := uniforms[name];
	if result = 0 then
		begin
			result := glGetUniformLocation(programID, name);
			uniforms[name] := result+kBaseIndex;
			exit;
		end;
	result -= kBaseIndex;
end;

procedure TShader.SetUniformMat4 (name: pchar; value: pointer);
begin	
	glUniformMatrix4fv(GetUniformLocation(name), 1, GL_FALSE, value);
end;

procedure TShader.SetUniformVec3 (name: pchar; value: pointer);
begin	
	glUniform3fv(GetUniformLocation(name), 1, value);
end;

procedure TShader.SetUniformVec3 (name: pchar; value: TVec3);
begin	
	glUniform3fv(GetUniformLocation(name), 1, @value);
end;

procedure TShader.SetUniformFloat (name: pchar; value: GLfloat);
begin
	glUniform1f(GetUniformLocation(name), value);
end;

procedure TShader.SetUniformInt (name: pchar; value: GLint);
begin
	glUniform1i(GetUniformLocation(name), value);
end;

procedure TShader.Deallocate;
begin
	ReleaseObject(uniforms);
	inherited Deallocate;
end;

constructor TShader.Create (vertexShaderPath, fragmentShaderPath: string);
var
	strings: TStringList;
	vertexShaderSource: PGLchar;
	fragmentShaderSource: PGLchar;
begin	
	Initialize;
	// install shader
	// http://www.freepascal-meets-sdl.net/category/tutorial/
	vertexShaderID := glCreateShader(GL_VERTEX_SHADER);
	fragmentShaderID := glCreateShader(GL_FRAGMENT_SHADER);
	
	// vertex shader
	strings := TStringList.Create;
  strings.LoadFromFile(vertexShaderPath);
	vertexShaderSource := strings.GetText;
	strings.Free;
	glShaderSource(vertexShaderID, 1, @vertexShaderSource, nil);
	
	strings := TStringList.Create;
  strings.LoadFromFile(fragmentShaderPath);
	fragmentShaderSource := strings.GetText;
	strings.Free;
	glShaderSource(fragmentShaderID, 1, @fragmentShaderSource, nil);	
end;

procedure TShader.Compile; 
var
	success: GLint;
	source: array[0..0] of pchar;
	logLength: GLint;
	logArray: array of GLChar;
	i: integer;
begin
	glCompileShader(vertexShaderID);
	glGetShaderiv(vertexShaderID, GL_COMPILE_STATUS, @success);
	glGetShaderiv(vertexShaderID, GL_INFO_LOG_LENGTH, @logLength);
	if success = GL_FALSE then
	  begin
	    SetLength(logArray, logLength+1);
	    glGetShaderInfoLog(vertexShaderID, logLength, nil, @logArray[0]);
	    for i := 0 to logLength do
				write(logArray[i]);
	    Fatal(success = GL_FALSE, 'Vertex shader failed to compile');
	  end;
  
	glCompileShader(fragmentShaderID);
	glGetShaderiv(fragmentShaderID, GL_COMPILE_STATUS, @success);
	glGetShaderiv(fragmentShaderID, GL_INFO_LOG_LENGTH, @logLength);
	if success = GL_FALSE then
	  begin
	    SetLength(logArray, logLength+1);
	    glGetShaderInfoLog(fragmentShaderID, logLength, nil, @logArray[0]);
	    for i := 0 to logLength do
				write(logArray[i]);
			Fatal(success = GL_FALSE, 'Fragment shader failed to compile');
	  end;
		
	// create problem
	programID := glCreateProgram();
  glAttachShader(programID, vertexShaderID);
  glAttachShader(programID, fragmentShaderID);

  glLinkProgram(programID);
	glGetProgramiv(programID, GL_LINK_STATUS, @success);
	Fatal(success = GL_FALSE, 'Error with linking shader program');	
end;

procedure TShader.Use; 
begin
	if CurrentShaderProgram <> programID then
		begin
			glUseProgram(programID);
			CurrentShaderProgram := programID;
		end;
end;

end.
