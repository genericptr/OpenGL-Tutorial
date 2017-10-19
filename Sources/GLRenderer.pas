{$mode objfpc}

unit GLRenderer;
interface
uses
	UArray,
	GLEntity, GLTypes, GLUtils, SDLUtils, SDL,
	UObject;

type
	TRenderer = class (TObject)
		public
			constructor Create;
			procedure AddEntity (entity: TEntity);
			procedure Render (camera: TCamera);
		private type TEntityArray = specialize TGenericFixedArray<TArray>;
		private
			entities: TEntityArray;
	end;

implementation

constructor TRenderer.Create;
begin
	entities := TEntityArray.Create(4);
	Initialize;
end;

procedure TRenderer.AddEntity (entity: TEntity);
begin
	// TODO: we probably need quad trees for this so just hack this now
	if entities[entity.model.id] = nil then
		entities[entity.model.id] := TArray.WeakInstance;
	entities[entity.model.id].AddValue(entity);
end;

procedure TRenderer.Render (camera: TCamera);
var
	viewTransform: TMat4;
	modelTransform: TMat4;
	lightPosition: TVec3;
	entity: TEntity;
	model: TModel;
	list: TArray;
	shader: TShader;
	i: integer;
begin
	viewTransform := camera.WorldToViewMatrix;
	shader := nil;
	
	for pointer(list) in entities do
		begin
			// reached end of list
			if list = nil then
				continue;
				
			model := TEntity(list[0]).model;
			
			// setup camera properties for current shader
			if model.shader <> shader then
				begin
					shader := model.shader;
					shader.Use;
					shader.SetUniformMat4('viewTransform', viewTransform.Ptr);
				end;
			
			// prepare model
			//glEnable(GL_CULL_FACE);
			//glCullFace(GL_BACK);
			
			model.Bind;
			model.shader.SetUniformFloat('shineDamper', model.material.shineDamper);
			model.shader.SetUniformFloat('reflectivity', model.material.reflectivity);
			
			model.shader.SetUniformInt('sampleTexture', 0);
			model.shader.SetUniformInt('normalMap', 1);

			for i := 0 to list.Count - 1 do
				begin
					entity := list[i] as TEntity;
					//entity.rotation := Vec3(0, entity.rotation.y + 1, 0);
					model.shader.SetUniformMat4('modelTransform', entity.modelMatrix.Ptr);
					entity.model.Draw;
				end;
			
			// unbind model
			model.Unbind;
			//glDisable(GL_CULL_FACE);
		end;
end;

end.