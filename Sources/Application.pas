{$mode objfpc}
{$modeswitch advancedrecords}

unit Application;
interface
uses
	Terrain,
	UArray,
	GLRenderer, GLEntity, GLUtils, SDLUtils, SDL;

type
	TGameWindow = class (TSDLOpenGLWindow)
		private
			camera: TCamera;
		private
			renderer: TRenderer;
			terrain: TTerrain;
			skyBox: TModel;
			skyRotation: single;
			
			procedure HandleEvent (event: TSDL_Event); override;
			procedure Reshape (width, height: integer); override;
			procedure Prepare; override;
			procedure Update; override;
	end;

implementation
uses
	GLTypes, Math,
	GL, GLExt, BeRoPNG, UObject, Classes,
	UGeometry;

function GetRandomNumber (min, max: longint): longint;
var
	zero: boolean = false;
begin
	if min = 0 then	
		begin
			//Fatal('GetRandomNumber 0 min value is invalid.');
			min += 1;
			max += 1;
			zero := true;
		end;
		
	if (min < 0) and (max > 0) then
		max += abs(min);
	
	result := System.Random(max) mod ((max - min) + 1);
	
	if result < 0 then
		result := abs(result);
		
	if zero then
		min -= 1;
	result += min;
end;

procedure UpdateCameraKeys (var camera: TCamera); 
begin
	if SystemKeysDown[SDLK_w] then
		camera.MoveForward
	else if SystemKeysDown[SDLK_S] then
		camera.MoveBackward;
	
	if SystemKeysDown[SDLK_A] then
		camera.RotateLeft
	else if SystemKeysDown[SDLK_D] then
		camera.RotateRight;

	if SystemKeysDown[SDLK_Q] then
		camera.StrafeLeft
	else if SystemKeysDown[SDLK_E] then
		camera.StrafeRight;
		
	if SystemKeysDown[SDLK_R] then
		camera.MoveUp
	else if SystemKeysDown[SDLK_F] then
		camera.MoveDown;
end;

procedure TGameWindow.Update;
var
	model: TModel;
	modelTransform: TMat4;
	viewTransform: TMat4;
begin
	glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT);
	
	UpdateCameraKeys(camera);
	renderer.Render(camera);
	
	// TODO: does this need to be part of a renderer class?
	model := terrain.model;
	model.Bind;
	
	// TODO: terrain needs to a model matrix with world coords (entity subclass?)
	modelTransform := TMat4.Translate(0, 0, 0);
	
	model.shader.Use;
	model.shader.SetUniformMat4('modelTransform', modelTransform.Ptr);
	model.shader.SetUniformMat4('viewTransform', camera.WorldToViewMatrix.Ptr);
	model.shader.SetUniformFloat('shineDamper', model.material.shineDamper);
	model.shader.SetUniformFloat('reflectivity', model.material.reflectivity);
	model.Draw;
	model.Unbind;
	
	// skybox
	skyBox.Bind;
	skyBox.shader.Use;
	viewTransform := camera.WorldToViewMatrix;
	viewTransform.m30 := 0;
	viewTransform.m31 := 0;
	viewTransform.m32 := 0;
	viewTransform *= TMat4.RotateY(skyRotation);
	skyRotation += (1/60) * 0.01;
	skyBox.shader.SetUniformMat4('viewTransform', viewTransform.Ptr);
	skyBox.Draw;
	skyBox.Unbind;
end;

procedure TGameWindow.Reshape (width, height: integer);
begin
	glViewPort(0, 0, Width, Height);
end;

procedure TGameWindow.HandleEvent (event: TSDL_Event);
var
	where: TVec2;
	keycode: UInt32;
begin
	if event.type_ = SDL_MOUSEMOTION then
		begin
			where := Vec2(event.motion.x, event.motion.y);
			camera.MouseUpdate(where);
		end
	else if event.type_ = SDL_MOUSEWHEEL then
		begin
			//camera.ZoomBy(event.wheel.y/10);
		end;
end;

function MakeSkyBox (size: Glfloat = 100): TMesh;
var
	stackIndices: array[0..35] of TMesh.TVertexIndex = (
		0,   1,  2,  0,  2,  3, // Top
		4,   5,  6,  4,  6,  7, // Front
		8,   9, 10,  8, 10, 11, // Right
		12, 13, 14, 12, 14, 15, // Left
		16, 17, 18, 16, 18, 19, // Back
		20, 22, 21, 20, 23, 22 	// Bottom
	);
	i: integer;
	mesh: TMesh;
begin
	mesh := TMesh.Create([3]);
	
	// TODO: if we know the vertex size (3 in this case)
	// we can add an attribute at an index (i * vertexSize) + the offsets
	// mesh.SetVerticies(24)
	// mesh.SetVertexAttribute(0, TVec3.Make(-size, +size, +size));
	// mesh.SetVertexAttribute(1, TVec3.Make(-size, +size, +size));
	// mesh.SetVertexAttribute(2, TVec3.Make(-size, +size, +size));
	// mesh.SetVertexAttribute(3, TVec3.Make(-size, +size, +size));
	
	mesh.AddVertexAttribute(TVec3.Make(-size, +size, +size));
	mesh.AddVertexAttribute(TVec3.Make(+size, +size, +size));
	mesh.AddVertexAttribute(TVec3.Make(+size, +size, -size));
	mesh.AddVertexAttribute(TVec3.Make(-size, +size, -size));
	           
	mesh.AddVertexAttribute(TVec3.Make(-size, +size, -size));
	mesh.AddVertexAttribute(TVec3.Make(+size, +size, -size));
	mesh.AddVertexAttribute(TVec3.Make(+size, -size, -size));
	mesh.AddVertexAttribute(TVec3.Make(-size, -size, -size));
	           
	mesh.AddVertexAttribute(TVec3.Make(+size, +size, -size));
	mesh.AddVertexAttribute(TVec3.Make(+size, +size, +size));
	mesh.AddVertexAttribute(TVec3.Make(+size, -size, +size));
	mesh.AddVertexAttribute(TVec3.Make(+size, -size, -size));
	                                                            
	mesh.AddVertexAttribute(TVec3.Make(-size, +size, +size));
	mesh.AddVertexAttribute(TVec3.Make(-size, +size, -size));
	mesh.AddVertexAttribute(TVec3.Make(-size, -size, -size));
	mesh.AddVertexAttribute(TVec3.Make(-size, -size, +size));
	                                                            
	mesh.AddVertexAttribute(TVec3.Make(+size, +size, +size));
	mesh.AddVertexAttribute(TVec3.Make(-size, +size, +size));
	mesh.AddVertexAttribute(TVec3.Make(-size, -size, +size));
	mesh.AddVertexAttribute(TVec3.Make(+size, -size, +size));
	                                                            
	mesh.AddVertexAttribute(TVec3.Make(+size, -size, -size));
	mesh.AddVertexAttribute(TVec3.Make(-size, -size, -size));
	mesh.AddVertexAttribute(TVec3.Make(-size, -size, +size));
	mesh.AddVertexAttribute(TVec3.Make(+size, -size, +size));
	
	mesh.SetIndicies(length(stackIndices));
	mesh.ind := stackIndices;
	
	result := mesh;
end;

type
	TGLlight = record
		public
			position: TVec3;
			color: TVec3;
			attenuation: TVec3;
		public
	end;

procedure TGameWindow.Prepare; 
const
	kMaxDist = 10;
var
	i: integer;
	mesh: TMesh;
	texture: TTexture2D;
	normalMap: TTexture2D;
	cubemap: TTextureCubeMap;
	projTransform: TMat4;
	lightPosition: TVec3;
	material: TMaterial;
	entity: TEntity;
	position: TVec3;
	
	// TODO: environment
	sunColor: TVec3;
	skyColor: TVec3;
	ambientLight: TScalar;
	
	path: string;
	
	simple_shader: TShader;
	flat_shader: TShader;
	terrain_shader: TShader;
	sky_shader: TShader;
	normalMap_shader: TShader;
	
	tree_1: TModel;
	lamp: TModel;
	stall: TModel;
	dragon: TModel;
	barrel: TModel;
begin
	System.Randomize;
	RandSeed := 1000;

	// NOTE: why do we need to do set this now??
	SetBasePath('Resources');

	// prepare opengl
	glClearColor(0, 0.5, 0.5, 1);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);	
	
	camera.Reset;
	camera.position := Vec3(5, 5, 20);
	projTransform := TMat4.Perspective(60.0, 500 / 500, 0.1, 200.0);
		
	// TODO: TEnvironment
	sunColor := Vec3(1);
	skyColor := Vec3(0.5, 0.7, 0.7) * sunColor;
	ambientLight := 0.3;	
		
	// load shaders
	// TODO: shader subclasses so we can specify uniforms for all shaders
	simple_shader := TShader.Create(GetDataFile('shaders/simple_vertex.glsl'), GetDataFile('shaders/simple_fragment.glsl'));
	simple_shader.Compile;
	simple_shader.Use;
		
	simple_shader.SetUniformMat4('projTransform', projTransform.Ptr);
	simple_shader.SetUniformVec3('skyColor', skyColor);
	simple_shader.SetUniformFloat('ambientLight', ambientLight);
	simple_shader.SetUniformVec3('lightPosition[0]', Vec3(0, 5, -10));
	simple_shader.SetUniformVec3('lightPosition[1]', Vec3(20, 0, 20));
	simple_shader.SetUniformVec3('lightPosition[2]', Vec3(0, 0, 0));
	simple_shader.SetUniformVec3('lightPosition[3]', Vec3(0, 0, 0));
	simple_shader.SetUniformVec3('lightColor[0]', sunColor);
	simple_shader.SetUniformVec3('lightColor[1]', Vec3(3, 0, 3));
	simple_shader.SetUniformVec3('lightColor[2]', Vec3(0, 0, 0));
	simple_shader.SetUniformVec3('lightColor[3]', Vec3(0, 0, 0));
	simple_shader.SetUniformVec3('attenuation[0]', Vec3(1, 0, 0));
	simple_shader.SetUniformVec3('attenuation[1]', Vec3(1, 0.02, 0.03));
	simple_shader.SetUniformVec3('attenuation[2]', Vec3(1, 0, 0));
	simple_shader.SetUniformVec3('attenuation[3]', Vec3(1, 0, 0));
	
	// load shaders
	normalMap_shader := TShader.Create(GetDataFile('shaders/normalMap_vertex.glsl'), GetDataFile('shaders/normalMap_fragment.glsl'));
	normalMap_shader.Compile;
	normalMap_shader.Use;
	
	normalMap_shader.SetUniformMat4('projTransform', projTransform.Ptr);
	normalMap_shader.SetUniformVec3('skyColor', skyColor);
	normalMap_shader.SetUniformFloat('ambientLight', ambientLight);
	normalMap_shader.SetUniformVec3('lightPosition[0]', Vec3(0, 5, -10));
	normalMap_shader.SetUniformVec3('lightPosition[1]', Vec3(20, 0, 20));
	normalMap_shader.SetUniformVec3('lightPosition[2]', Vec3(0, 0, 0));
	normalMap_shader.SetUniformVec3('lightPosition[3]', Vec3(0, 0, 0));
	normalMap_shader.SetUniformVec3('lightColor[0]', sunColor);
	normalMap_shader.SetUniformVec3('lightColor[1]', Vec3(3, 0, 3));
	normalMap_shader.SetUniformVec3('lightColor[2]', Vec3(0, 0, 0));
	normalMap_shader.SetUniformVec3('lightColor[3]', Vec3(0, 0, 0));
	normalMap_shader.SetUniformVec3('attenuation[0]', Vec3(1, 0, 0));
	normalMap_shader.SetUniformVec3('attenuation[1]', Vec3(1, 0.02, 0.03));
	normalMap_shader.SetUniformVec3('attenuation[2]', Vec3(1, 0, 0));
	normalMap_shader.SetUniformVec3('attenuation[3]', Vec3(1, 0, 0));
		
	terrain_shader := TShader.Create(GetDataFile('shaders/terrain_vertex.glsl'), GetDataFile('shaders/terrain_fragment.glsl'));
	terrain_shader.Compile;
	terrain_shader.Use;
	
	terrain_shader.SetUniformMat4('projTransform', projTransform.Ptr);
	terrain_shader.SetUniformVec3('skyColor', skyColor);
	terrain_shader.SetUniformFloat('ambientLight', ambientLight);
	terrain_shader.SetUniformVec3('lightPosition[0]', Vec3(0, 5, -10));
	terrain_shader.SetUniformVec3('lightPosition[1]', Vec3(20, 0, 20));
	terrain_shader.SetUniformVec3('lightPosition[2]', Vec3(0, 0, 0));
	terrain_shader.SetUniformVec3('lightPosition[3]', Vec3(0, 0, 0));
	terrain_shader.SetUniformVec3('lightColor[0]', sunColor);
	terrain_shader.SetUniformVec3('lightColor[1]', Vec3(3, 0, 3));
	terrain_shader.SetUniformVec3('lightColor[2]', Vec3(0, 0, 0));
	terrain_shader.SetUniformVec3('lightColor[3]', Vec3(0, 0, 0));
	terrain_shader.SetUniformVec3('attenuation[0]', Vec3(1, 0, 0));
	terrain_shader.SetUniformVec3('attenuation[1]', Vec3(1, 0.02, 0.03));
	terrain_shader.SetUniformVec3('attenuation[2]', Vec3(1, 0, 0));
	terrain_shader.SetUniformVec3('attenuation[3]', Vec3(1, 0, 0));
	
	sky_shader := TShader.Create(GetDataFile('shaders/skybox_vertex.glsl'), GetDataFile('shaders/skybox_fragment.glsl'));
	sky_shader.Compile;
	sky_shader.Use;
	
	sky_shader.SetUniformMat4('projTransform', projTransform.Ptr);
	sky_shader.SetUniformVec3('skyColor', skyColor);
	
	renderer := TRenderer.Create;
	
	{mesh := TMesh.LoadOBJModel(GetDataFile('dragon.obj'));
	material := TMaterial.Create(1, 0.25, 0);
	dragon := TModel.Create(mesh, material, simple_shader);
	dragon.Prepare;}
	
	{mesh := TMesh.LoadOBJModel('/Users/ryanjoseph/Desktop/Projects/Games/Minecraft/Models/stall/stall.obj');
	texture := TTexture2D.Create(GetDataFile('stallTexture.png'), GL_LINEAR);
	material := TMaterial.Create(1, 0.25, texture.texture);
	stall := TModel.Create(mesh, material, simple_shader);
	stall.Prepare;}

	{mesh := TMesh.LoadOBJModel('/Users/ryanjoseph/Desktop/Projects/Games/Minecraft/Models/Monkey/monkey.obj');
	texture := TTexture2D.Create('/Users/ryanjoseph/Desktop/Projects/Games/Minecraft/Models/Monkey/head_texture_1.png', GL_LINEAR);
	material := TMaterial.Create(1, 0.25, texture.texture);
	monkey := TModel.Create(mesh, material, simple_shader);
	monkey.Prepare;}


	mesh := MakeSkyBox(100);
	cubemap := TTextureCubeMap.Create('/Users/ryanjoseph/Desktop/Projects/Games/Minecraft/res', ['right.png', 'left.png', 'top.png', 'bottom.png', 'back.png', 'front.png'], GL_LINEAR);	
	material := TMaterial.Create(1, 0.25, [cubemap]);
	skybox := TModel.Create(mesh, material, sky_shader);
	skybox.Prepare;

	mesh := TMesh.LoadOBJModel('/Users/ryanjoseph/Desktop/Projects/Games/Minecraft/Models/Tree_1/Tree_1.obj');
	texture := TTexture2D.Create('/Users/ryanjoseph/Desktop/Projects/Games/Minecraft/Models/Tree_1/texture.png', GL_LINEAR);	
	material := TMaterial.Create(1, 0.25, [texture]);
	tree_1 := TModel.Create(mesh, material, simple_shader);
	tree_1.Prepare;

	mesh := TMesh.LoadOBJModel('/Users/ryanjoseph/Desktop/Projects/Games/Minecraft/res/lamp.obj');
	texture := TTexture2D.Create('/Users/ryanjoseph/Desktop/Projects/Games/Minecraft/res/lamp.png', GL_LINEAR);	
	material := TMaterial.Create(1, 0.25, [texture]);
	lamp := TModel.Create(mesh, material, simple_shader);
	lamp.Prepare;

	mesh := TMesh.LoadOBJModel('/Users/ryanjoseph/Desktop/Projects/Games/Minecraft/res/barrel.obj', true);
	texture := TTexture2D.Create('/Users/ryanjoseph/Desktop/Projects/Games/Minecraft/res/barrel.png', GL_LINEAR);	
	normalMap := TTexture2D.Create('/Users/ryanjoseph/Desktop/Projects/Games/Minecraft/res/barrelNormal.png', GL_LINEAR, false);	
	material := TMaterial.Create(1, 0.25, [texture, normalMap]);
	barrel := TModel.Create(mesh, material, normalMap_shader);
	barrel.Prepare;
	
	texture := TTexture2D.Create(GetDataFile('grass.png'), GL_LINEAR);	
	terrain := TTerrain.Create(Vec3(0, 0, 0));
	terrain.Generate(terrain_shader);
	terrain.model.material.AddTexture(texture);
	
	// test
	entity := TEntity.Create(barrel);
	entity.position := Vec3(25, 0, 25);
	entity.scale := 0.25;
	renderer.AddEntity(entity);
	
	// lamps
	entity := TEntity.Create(lamp);
	entity.position := Vec3(20, 0, 20);
	entity.scale := 0.25;
	renderer.AddEntity(entity);
	
	for i := 0 to 60 do
		begin
			entity := TEntity.Create(tree_1);
			position.x := Random(64);
			position.z := Random(64);
			position.y := terrain.GetHeightAtWorldPosition(position) - 0.2;
			entity.position := position;
			entity.scale := (5 + Random(30 - 5)) / 10;
			entity.rotation := Vec3(0, Random(360), 0);
			renderer.AddEntity(entity);
		end;
	{for i := 0 to 10 do
		begin
			entity := TEntity.Create(dragon);
			entity.position := Vec3(GetRandomNumber(-kMaxDist, kMaxDist), GetRandomNumber(0, kMaxDist), GetRandomNumber(-kMaxDist*2, 0));
			renderer.AddEntity(entity);
			entity.Release;
		end;}
	
	// load textures
	//image := LoadTextureFromFile(GetDataFile('gem.png'));	
		
	// setup world
	{cube := TModel.Create(TMesh.MakeCube, image.texture, shader);
	for i := 0 to high(cube.mesh.v) div 4 do
		begin
			cube.mesh.v[(i*4)+0].tex := Vec2(0, 1);
			cube.mesh.v[(i*4)+1].tex := Vec2(1, 1);
			cube.mesh.v[(i*4)+2].tex := Vec2(1, 0);
			cube.mesh.v[(i*4)+3].tex := Vec2(0, 0);
		end;
	cube.Prepare;}
end;

end.