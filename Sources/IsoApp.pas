{$mode objfpc}
{$modeswitch advancedrecords}

unit IsoApp;
interface
uses
	UArray,
	GLRenderer, GLEntity, GLUtils, SDLUtils, SDL;

type
	TGameWindow = class (TSDLOpenGLWindow)
		private
			renderer: TRenderer;
			rotate: single;

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

procedure TGameWindow.Update;
var
	viewTransform: TMat4;
begin
	glClear(GL_DEPTH_BUFFER_BIT or GL_COLOR_BUFFER_BIT);

	viewTransform := TMat4.Identity;
	//viewTransform *= TMat4.Translate(0, 500, 0);
	viewTransform *= TMat4.RotateY(rotate);
	rotate += 0.01;
	renderer.Render(viewTransform);
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
		end
	else if event.type_ = SDL_MOUSEWHEEL then
		begin
			//camera.ZoomBy(event.wheel.y/10);
		end;
end;

procedure TGameWindow.Prepare; 
const
	kMaxDist = 10;
var
	i: integer;
	mesh: TMesh;
	texture: TTexture2D;
	projTransform: TMat4;
	lightPosition: TVec3;
	material: TMaterial;
	entity: TEntity;
	position: TVec3;
	rotation: TVec3;

	// TODO: environment
	sunColor: TVec3;
	skyColor: TVec3;
	ambientLight: TScalar;
	
	path: string;
	
	shader: TShader;
	
	tree_1: TModel;
	cube: TModel;
	base: string;
begin
	// NOTE: why do we need to do set this now??
	SetBasePath('Resources');

	// prepare opengl
	glClearColor(0, 0.5, 0.5, 1);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);	
	
	// NOTE: isometric projection
	rotation := Vec3(-30, -45, 45);
	projTransform := TMat4.Ortho(0, GetWidth, GetHeight, 0, -10000, 10000);
	projTransform *= TMat4.Translate((GetWidth / 2), 0, 0) * TMat4.RotateX(DegToRad(rotation.x)) * TMat4.RotateY(DegToRad(rotation.y));
	projTransform *= TMat4.Scale(1, 1, 1);
	
	// TODO: TEnvironment
	sunColor := Vec3(1);
	skyColor := Vec3(0.5, 0.7, 0.7) * sunColor;
	ambientLight := 0.3;	
		
	// load shaders
	// TODO: shader subclasses so we can specify uniforms for all shaders
	shader := TShader.Create(GetDataFile('shaders/iso_vertex.glsl'), GetDataFile('shaders/iso_fragment.glsl'));
	shader.Compile;
	shader.Use;
		
	shader.SetUniformMat4('projTransform', projTransform.Ptr);
	shader.SetUniformVec3('skyColor', skyColor);
	shader.SetUniformFloat('ambientLight', ambientLight);
	shader.SetUniformVec3('lightPosition[0]', Vec3(0, 0, -10));
	shader.SetUniformVec3('lightColor[0]', sunColor);
	shader.SetUniformVec3('attenuation[0]', Vec3(1, 0, 0));
	
	base := '/Users/ryanjoseph/Desktop/Projects/Games/OpenGL-Tutorial';
	renderer := TRenderer.Create;

	mesh := TMesh.LoadOBJModel(base+'/Models/Tree_1/Tree_1.obj');
	texture := TTexture2D.Create(base+'/Models/Tree_1/texture.png', GL_LINEAR);	
	material := TMaterial.Create(1, 0.25, [texture]);
	tree_1 := TModel.Create(mesh, material, shader);
	tree_1.Prepare;
	
	// test
	entity := TEntity.Create(tree_1);
	entity.position := Vec3(0, 500, 0);
	entity.scale := 100;
	renderer.AddEntity(entity);
		
	//mesh := TMesh.MakeCube;
	////material := TMaterial.Create(1, 0.25, []);
	//cube := TModel.Create(mesh, material, shader);
	//cube.Prepare;
	//entity := TEntity.Create(cube);
	//entity.position := Vec3(0, 500, 0);
	//entity.scale := 1;
	//renderer.AddEntity(entity);
end;

end.