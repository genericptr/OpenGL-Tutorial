{$mode objfpc}

unit GLEntity;
interface
uses
	GLUtils, GLTypes, UObject,
	Math;


type
	TEntity = class (TObject)
		private
			m_position: TVec3;
			m_rotation: TVec3;
			m_scale: TScalar;
			
			procedure SetPosition (newValue: TVec3);
			procedure SetRotation (newValue: TVec3);
			procedure SetScale (newValue: TScalar);
		public
			modelMatrix: TMat4;
			model: TModel;
		public	
			property Rotation: TVec3 read m_rotation write SetRotation;
			property Position: TVec3 read m_position write SetPosition;
			property Scale: TScalar read m_scale write SetScale;
		public
			constructor Create (_model: TModel);
		protected
			procedure Initialize; override;
			procedure Deallocate; override;
		private			
			procedure UpdateModelMatrix;
	end;

implementation

procedure TEntity.SetPosition (newValue: TVec3);
begin
	m_position := newValue;
	UpdateModelMatrix;
end;

procedure TEntity.SetRotation (newValue: TVec3);
begin
	m_rotation := newValue;
	UpdateModelMatrix;
end;

procedure TEntity.SetScale (newValue: TScalar);
begin
	m_scale := newValue;
	UpdateModelMatrix;
end;

procedure TEntity.UpdateModelMatrix; 
begin
	modelMatrix := TMat4.Translate(position.x, position.y, position.z);
	
	// TODO: this all needs to happen in one call
	if rotation.x <> 0 then
		modelMatrix := modelMatrix * TMat4.RotateX(DegToRad(rotation.x));
	if rotation.y <> 0 then
		modelMatrix := modelMatrix * TMat4.RotateY(DegToRad(rotation.y));
	if rotation.z <> 0 then
		modelMatrix := modelMatrix * TMat4.RotateZ(DegToRad(rotation.z));
	
	if scale <> 0 then
		modelMatrix := modelMatrix * TMat4.Scale(scale, scale, scale);
end;

procedure TEntity.Deallocate; 
begin
	ReleaseObject(model);
	
	inherited Deallocate;
end;

procedure TEntity.Initialize;
begin
	inherited Initialize;
	
	position := Vec3(0, 0, 0);
	rotation := Vec3(0, 0, 0);
	scale := 1.0;
	
	UpdateModelMatrix;
end;

constructor TEntity.Create (_model: TModel);
begin
	Initialize;
	model := _model.Retain as TModel;
end;

end.