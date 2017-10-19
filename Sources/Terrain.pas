{$mode objfpc}

unit Terrain;
interface
uses
	Noise,
	UMatrix, UArray, UTypes, UObject,
	GLRenderer, GLEntity, GLTypes, GLUtils, SDLUtils, SDL,
	Math;

type
	TWorldCoord = TVec3;
	TWorldGridCoord = TVec3;
	
type
	TTerrain = class (TObject)
		public
			model: TModel;
		private type TVertexCoord = Longint;
		public	
			constructor Create (where: TWorldGridCoord);
			procedure Generate (shader: TShader); 
			function GetHeightAtWorldPosition (worldPos: TVec3): TScalar; 
		private
			worldOrigin: TVec3;
			tileSize: integer;
			noise: TNoise;
			heights: TFloatMatrix;
			
			function GetHeightForVertex (x, y: TVertexCoord): TNoiseFloat; 
			function CalculateNormal (x, y: TVertexCoord): TVec3;
	end;

type
	TTerrainMap = class (TObject)
		private
			matrix: TMatrix;
	end;

implementation
const
	TERRAIN_SIZE = 64;
	VERTEX_COUNT = 64;

function GetNoise (noise: TNoise; x, y: TTerrain.TVertexCoord; mapSize: integer; scale: single; frequency: integer): TNoiseFloat; 
var
	nx, ny: TNoiseFloat;
begin
	nx := x/mapSize - 0.5; 
	ny := y/mapSize - 0.5;
	result := noise.GetValue(nx * scale, ny * scale, 0, frequency, 0.5) / 2 + 0.5;
end;

function BarryCentric (p1, p2, p3: TVec3; pos: TVec2): TScalar; 
var
	det, l1, l2, l3: TScalar;
begin
	det := (p2.z - p3.z) * (p1.x - p3.x) + (p3.x - p2.x) * (p1.z - p3.z);
	l1 := ((p2.z - p3.z) * (pos.x - p3.x) + (p3.x - p2.x) * (pos.y - p3.z)) / det;
	l2 := ((p3.z - p1.z) * (pos.x - p3.x) + (p1.x - p3.x) * (pos.y - p3.z)) / det;
	l3 := 1.0 - l1 - l2;
	result := l1 * p1.y + l2 * p2.y + l3 * p3.y;
end;

function TTerrain.GetHeightAtWorldPosition (worldPos: TVec3): TScalar; 
var
	terrainPos: TVec3;
	gridSquareSize: TScalar;
	gridX, gridZ: integer;
	tileCoord: TVec3;
begin
	terrainPos := Vec3(worldPos.x - worldOrigin.x, 0, worldPos.z - worldOrigin.z);
	
	gridSquareSize := TERRAIN_SIZE / (VERTEX_COUNT - 1);
	gridX := Trunc(terrainPos.x / gridSquareSize);
	gridZ := Trunc(terrainPos.z / gridSquareSize);
	
	// test bounds
	// TODO: heights.IsTileCoordValid
	if (gridX >= VERTEX_COUNT - 1) or (gridZ >= VERTEX_COUNT - 1) or
	   (gridX < 0) or (gridZ < 0) then
		exit(0);
		
	tileCoord.x := FMod(terrainPos.x, gridSquareSize) / gridSquareSize;
	tileCoord.z := FMod(terrainPos.z, gridSquareSize) / gridSquareSize;
	
	if tileCoord.x <= 1-tileCoord.z then
		result := BarryCentric( Vec3(0, heights[gridX, gridZ, 0], 0),
														Vec3(1, heights[gridX + 1, gridZ, 0], 0),
														Vec3(0, heights[gridX, gridZ + 1, 0], 1),
														Vec2(tileCoord.x, tileCoord.z))
	else
		result := BarryCentric( Vec3(1, heights[gridX + 1, gridZ, 0], 0),
														Vec3(1, heights[gridX + 1, gridZ + 1, 0], 1),
														Vec3(0, heights[gridX, gridZ + 1, 0], 1),
														Vec2(tileCoord.x, tileCoord.z));
end;

function TTerrain.GetHeightForVertex (x, y: TVertexCoord): TNoiseFloat; 
begin
	//exit(0);
	result := GetNoise(noise, x, y, VERTEX_COUNT, 4, 3);
	result := Power(result, 5);
	result := Round(result * 24) / 24;
	result := (result * 20) - 6;
	
	// NOTE: same bug as before with memory. something in Noise.Getvalue
	result.str;
end;

function TTerrain.CalculateNormal (x, y: TVertexCoord): TVec3; 
var
	heightL, heightR, heightD, heightU: TNoiseFloat;
begin
	heightL := GetHeightForVertex(x-1, y);
	heightR := GetHeightForVertex(x+1, y);
	heightD := GetHeightForVertex(x, y-1);
	heightU := GetHeightForVertex(x, y+1);
	result := Vec3(heightL-heightR, 2.0, heightD - heightU).Normalize;
end;

procedure TTerrain.Generate (shader: TShader); 
var
	mesh: TMesh;
	material: TMaterial;
	vertex: TVertex3;
	topLeft: integer;
	topRight: integer;
	bottomLeft: integer;
	bottomRight: integer;
	x, y, gz, gx: integer;
begin
	mesh := TMesh.Create([3, 3, 2, 3]);

	noise := TNoise.Create(RandomNoiseSeed(1));
	heights := TFloatMatrix.Create(VERTEX_COUNT, VERTEX_COUNT);
		
	for y := 0 to VERTEX_COUNT - 1 do
	for x := 0 to VERTEX_COUNT - 1 do
		begin			
			vertex.pos.x := x/(VERTEX_COUNT - 1) * TERRAIN_SIZE;
			vertex.pos.y := GetHeightForVertex(x, y);
			vertex.pos.z := y/(VERTEX_COUNT - 1) * TERRAIN_SIZE;
			
			heights[x, y, 0] := vertex.pos.y;
			
			vertex.nrm := CalculateNormal(x, y);
			
			vertex.tex.x := x/(VERTEX_COUNT - 1);
			vertex.tex.y := y/(VERTEX_COUNT - 1);
			
			mesh.AddVertex(vertex);
		end;
	
	for gz := 0 to VERTEX_COUNT - 2 do
	for gx := 0 to VERTEX_COUNT - 2 do
		begin
			topLeft := (gz*VERTEX_COUNT)+gx;
			topRight := topLeft + 1;
			bottomLeft := ((gz+1)*VERTEX_COUNT)+gx;
			bottomRight := bottomLeft + 1;
			
			mesh.AddIndex(topLeft);
			mesh.AddIndex(bottomLeft);
			mesh.AddIndex(topRight);
			mesh.AddIndex(topRight);
			mesh.AddIndex(bottomLeft);
			mesh.AddIndex(bottomRight);
		end;
		
	//mesh := TMesh.MakeFlatPlane;
	material := TMaterial.Create(1, 0, []);
	model := TModel.Create(mesh, material, shader);
	model.Prepare;
end;

constructor TTerrain.Create (where: TWorldGridCoord);
begin
	worldOrigin := where * TERRAIN_SIZE;
	Initialize;
end;

end.