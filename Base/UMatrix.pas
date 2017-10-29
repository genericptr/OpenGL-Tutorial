{$mode objfpc}
{$modeswitch advancedrecords}

unit UMatrix;
interface
uses
	SysUtils, Math, TypInfo,
	UValue, UGeometry, UArray, UObject, UTypes;

type 
	IMatrixNode = interface (IObject)
		procedure SetTileCoord (newValue: TPoint3D);
		function GetTileCoord: TPoint3D;
	end;


type
	generic TGenericMatrix<T> = class (TObject)
		public
			type
				TMatrixTable = array[0..0] of T;
				TMatrixTablePtr = ^TMatrixTable;
				TMatrixIndex = LongInt;
		private
			type
				TMatrixEnumerator = class
					private
						root: TGenericMatrix;
						currentValue: T;
						x, y, z: TMatrixIndex;
					public
						constructor Create(_root: TGenericMatrix); 
						function MoveNext: Boolean;
						procedure Reset;
						property Current: T read currentValue;
				end;
		public
			
			{ Constructors }
			constructor Create (_gridSize: TSize3D); overload;
			constructor Create (_gridSize: TSize); overload;
			constructor Create (x, y, z: integer); overload;
			constructor Create (x, y: integer); overload;
			
			{ Accessors }
			procedure SetWeakRetain (newValue: boolean);
			function GetGridSize: TSize3D;
			function GetEnumerator: TMatrixEnumerator;
			
			{ Getting Values }
			function GetValue (tileCoord: TPoint3D): T; overload;
			function GetValue (x, y, z: TMatrixIndex): T; overload;			
			function GetValue (region: TRect3D; contiguous: boolean): T; overload;
			function GetValuePtr (x, y, z: TMatrixIndex): Pointer;
			function IsValidTileCoord (tileCoord: TPoint3D): boolean; overload;
			function IsValidTileCoord (x, y, z: TMatrixIndex): boolean;

			{ Iterating }
			function CountX: TMatrixIndex;
			function CountY: TMatrixIndex;
			function CountZ: TMatrixIndex;	
			function HighX: TMatrixIndex;
			function HighY: TMatrixIndex;
			function HighZ: TMatrixIndex;			
					
			function GetTable: TMatrixTablePtr;
			property table: TMatrixTablePtr read GetTable;
			
			{ Setting Values }
			procedure SetValue (tileCoord: TPoint3D; newValue: T); overload;
			procedure SetValue (x, y, z: TMatrixIndex; newValue: T); overload;
			procedure SetValue (rect: TRect3D; newValue: T); overload;
			
			{ Removing Values }
			procedure RemoveValue (tileCoord: TPoint3D); overload;
			procedure RemoveAllValues;
			
			{ 2D Helpers }
			function GetValue (tileCoord: TPoint): T; overload;
			procedure SetValue (tileCoord: TPoint; newValue: T); overload;
			procedure RemoveValue (tileCoord: TPoint); overload;
			function IsValidTileCoord (tileCoord: TPoint): boolean; overload;
						
			procedure Show; override;
		
		public
			property MatrixValues[const x,y,z:TMatrixIndex]:T read GetValue; default;	
		protected
			procedure Initialize; override;
			procedure Deallocate; override;
			
			procedure SetGridSize (newValue: TSize3D);
			function RetainValue (value: T): T; virtual;
			procedure ReleaseValue (value: T);  virtual;
			
		private
			_table: TMatrixTablePtr;
			gridSize: TSize3D;
			nextCount: integer;
			weakRetain: boolean;
			typeKind: TTypeKind;
			elementCount: TMatrixIndex;
			rows: TMatrixIndex;
			plane: TMatrixIndex;
			
			{ Flat Access }
			function GetValue (index: TMatrixIndex): T; overload;
			procedure SetValue (index: TMatrixIndex; newValue: T); overload;
			function Count: TMatrixIndex;			
			
			function GetIndexOfPosition (x, y, z: TMatrixIndex): TMatrixIndex;
	end;
	
type
	TIntegerMatrix = specialize TGenericMatrix<Integer>;
	TLongIntMatrix = specialize TGenericMatrix<LongInt>;
	TStringMatrix = specialize TGenericMatrix<String>;
	TSingleMatrix = specialize TGenericMatrix<Single>;
	TDoubleMatrix = specialize TGenericMatrix<Double>;
	TPointerMatrix = specialize TGenericMatrix<Pointer>;
	TBooleanMatrix = specialize TGenericMatrix<Boolean>;
	TMatrix = specialize TGenericMatrix<TObject>;
	
type
	TMatrixTilesArray = array[0..7] of TPoint3D;
	
procedure MatrixNeighborsDiagonal (tileCoord: TPoint3D; var tileCoords: TMatrixTilesArray); overload;
procedure MatrixNeighborsDiagonal (tileCoord: TPoint3D; diagonal: boolean; var tileCoords: TPoint3DArray); overload;
	
implementation

{=============================================}
{@! ___UTILITIES___ } 
{=============================================}

procedure MatrixNeighborsDiagonal (tileCoord: TPoint3D; var tileCoords: TMatrixTilesArray);
begin
	tileCoords[0] := tileCoord.Offset(-1, 0, 0);
	tileCoords[1] := tileCoord.Offset(1, 0, 0);
	tileCoords[2] := tileCoord.Offset(0, -1, 0);
	tileCoords[3] := tileCoord.Offset(0, 1, 0);
	
	tileCoords[4] := tileCoord.Offset(-1, -1, 0);
	tileCoords[5] := tileCoord.Offset(-1, 1, 0);
	tileCoords[6] := tileCoord.Offset(1, -1, 0);
	tileCoords[7] := tileCoord.Offset(1, 1, 0);
end;

procedure MatrixNeighborsDiagonal (tileCoord: TPoint3D; diagonal: boolean; var tileCoords: TPoint3DArray);
var
	neighbor: TPoint3D;
begin
	if tileCoords = nil then
		tileCoords := TPoint3DArray.Instance
	else
		tileCoords.RemoveAllValues;
	
	tileCoords.Reserve(8);
	
	tileCoords.AddValue(tileCoord.Offset(-1, 0, 0));
	tileCoords.AddValue(tileCoord.Offset(1, 0, 0));
	tileCoords.AddValue(tileCoord.Offset(0, -1, 0));
	tileCoords.AddValue(tileCoord.Offset(0, 1, 0));
	
	if diagonal then
		begin
			tileCoords.AddValue(tileCoord.Offset(-1, -1, 0));
			tileCoords.AddValue(tileCoord.Offset(-1, 1, 0));
			tileCoords.AddValue(tileCoord.Offset(1, -1, 0));
			tileCoords.AddValue(tileCoord.Offset(1, 1, 0));
		end;
end;

{=============================================}
{@! ___ENUMERATOR___ } 
{=============================================} 
constructor TGenericMatrix.TMatrixEnumerator.Create(_root: TGenericMatrix);
begin
	inherited Create;
	root := _root;
end;

function TGenericMatrix.TMatrixEnumerator.MoveNext: Boolean;
var
	gridSize: TSize3D;
begin
	gridSize := root.gridSize;
	
	// reached end
	if z = gridSize.depth then
		exit(false);
	
	currentValue := root.GetValue(x, y, z);
		
	x += 1;
	if x = gridSize.width then
		begin
			x := 0;
			y += 1;
		end;
	if y = gridSize.height then
		begin
			x := 0;
			y := 0;
			z += 1;
		end;

	result := true;
end;
	
procedure TGenericMatrix.TMatrixEnumerator.Reset;
begin
	x := 0;
	y := 0;
	z := 0;
end;

{=============================================}
{@! ___MATRIX___ } 
{=============================================}

function TGenericMatrix.HighX: TMatrixIndex;
begin
	result := CountX - 1;
end;

function TGenericMatrix.HighY: TMatrixIndex;
begin
	result := CountY - 1;
end;

function TGenericMatrix.HighZ: TMatrixIndex;			
begin
	result := CountZ - 1;
end;

function TGenericMatrix.CountX: TMatrixIndex;
begin
	result := gridSize.width.Long;
end;

function TGenericMatrix.CountY: TMatrixIndex;
begin
	result := gridSize.height.Long;
end;

function TGenericMatrix.CountZ: TMatrixIndex;
begin
	result := gridSize.depth.Long;
end;

function TGenericMatrix.GetTable: TMatrixTablePtr;
begin
	result := _table;
end;

function TGenericMatrix.GetValue (index: TMatrixIndex): T;
begin
	result := _table^[index];
end;

function TGenericMatrix.GetValue (x, y, z: TMatrixIndex): T;
begin
	if IsValidTileCoord(x, y, z) then
		result := _table^[GetIndexOfPosition(x, y, z)]
	else
		result := Default(T);
end;

function TGenericMatrix.GetValue (tileCoord: TPoint3D): T;
begin
	result := GetValue(tileCoord.x.Long, tileCoord.y.Long, tileCoord.z.Long);
end;

{procedure TGenericMatrix.GetValues (region: TRect3D; var regions: TMatrixValues);
var
	x, y, z: TMatrixIndex;
	value: T;
begin
	value :=  Default(T);
	if regions = nil then
		regions := TMatrixValues.Instance;
	for x := region.MinX.Long to region.MaxX.Long-1 do
	for y := region.MinY.Long to region.MaxY.Long-1 do
	for z := region.MinZ.Long to region.MaxZ.Long-1 do
		begin
			value := GetValue(x, y, z);
			if value <> Default(T) then
				regions.AddValue(value);
		end;
end;

function TGenericMatrix.GetValues (region: TRect3D): TMatrixValues;
begin
	result := TMatrixValues.Instance;
	GetValues(region, result);
end;}

function TGenericMatrix.GetValue (region: TRect3D; contiguous: boolean): T;
var
	x, y, z: TMatrixIndex;
	value: T;
	firstPass: boolean = false;
begin
	result := Default(T);
	for x := region.MinX.Long to region.MaxX.Long - 1 do
	for y := region.MinY.Long to region.MaxY.Long - 1 do
	for z := region.MinZ.Long to region.MaxZ.Long - 1 do
		begin
			// all tiles in the region must be the same value
			if contiguous then
				begin
					result := GetValue(x, y, z);
					if firstPass and (value <> result) then
						exit(Default(T));
					firstPass := true;
				end
			else // return the first value found
				begin
					value := GetValue(x, y, z);
					if value <> Default(T) then
						exit(value);
				end;
		end;
end;

function TGenericMatrix.GetValuePtr (x, y, z: TMatrixIndex): Pointer;
begin
	if IsValidTileCoord(x, y, z) then
		result := @_table^[GetIndexOfPosition(x, y, z)]
	else
		result := nil;
end;

function TGenericMatrix.GetValue (tileCoord: TPoint): T;
begin
	result := GetValue(PointMake(tileCoord.x, tileCoord.y, 0));
end;

function TGenericMatrix.GetIndexOfPosition (x, y, z: TMatrixIndex): TMatrixIndex;
begin
	if z > 0 then
		result := (plane * z) + (rows * y) + x
	else if y > 0 then
		result := (rows * y) + x
	else
		result := x;
end;

function TGenericMatrix.IsValidTileCoord (x, y, z: TMatrixIndex): boolean;
begin
	if (x < 0) or (y < 0) or (z < 0) or (x >= gridSize.width) or (y >= gridSize.height) or ((gridSize.depth > 0) and (z >= gridSize.depth)) then
		result := false
	else
		result := true;
end;

function TGenericMatrix.IsValidTileCoord (tileCoord: TPoint3D): boolean;
begin
	if not tileCoord.x.IsIntegral or not tileCoord.y.IsIntegral or not tileCoord.z.IsIntegral then
		exit(false);
	result := IsValidTileCoord(tileCoord.x.Long, tileCoord.y.Long, tileCoord.z.Long)
end;

function TGenericMatrix.IsValidTileCoord (tileCoord: TPoint): boolean;
begin
	result := IsValidTileCoord(PointMake(tileCoord.x, tileCoord.y, 0));
end;

procedure TGenericMatrix.SetValue (tileCoord: TPoint; newValue: T);
begin
	SetValue(PointMake(tileCoord.x, tileCoord.y, 0), newValue);
end;

procedure TGenericMatrix.RemoveValue (tileCoord: TPoint);
begin
	RemoveValue(PointMake(tileCoord.x, tileCoord.y, 0));
end;

procedure TGenericMatrix.SetValue (index: TMatrixIndex; newValue: T);
begin
	ReleaseValue(_table^[index]);
	_table^[index] := RetainValue(newValue);
end;

procedure TGenericMatrix.SetValue (x, y, z: TMatrixIndex; newValue: T);
begin
	if not IsValidTileCoord(x, y, z) then
		Fatal('Tile coord '+PointMake(x, y, z).Str+' is invalid ('+gridSize.Str+')');
	SetValue(GetIndexOfPosition(x, y, z), newValue);
end;

procedure TGenericMatrix.SetValue (tileCoord: TPoint3D; newValue: T);
begin
	SetValue(tileCoord.x.Long, tileCoord.y.Long, tileCoord.z.Long, newValue);
end;

// Set values to matrix in rect (tile coords)
procedure TGenericMatrix.SetValue (rect: TRect3D; newValue: T);
var
	x, y, z: TMatrixIndex;
begin
	for x := rect.MinX.Long to rect.MaxX.Long do
	for y := rect.MinY.Long to rect.MaxY.Long do
	for z := rect.MinZ.Long to rect.MaxZ.Long do
		SetValue(x, y, z, newValue);
end;

procedure TGenericMatrix.RemoveAllValues;
var
	i: TMatrixIndex;
	value: T;
begin
	if weakRetain then
		FillChar(_table^, MemSize(_table), 0)
	else
		begin
			for i := 0 to Count - 1 do
				begin
					value := GetValue(i);
					if value <> Default(T) then
						SetValue(i, Default(T));
				end;
		end;
end;

procedure TGenericMatrix.RemoveValue (tileCoord: TPoint3D);
begin
	if not IsValidTileCoord(tileCoord) then
		Fatal('Tile coord '+tileCoord.Str+' is invalid ('+gridSize.Str+')');
	SetValue(tileCoord, Default(T));
end;

procedure TGenericMatrix.Show;
var
	x, y, z: TMatrixIndex;
	value: T;
begin
	//inherited Show;
	writeln('(');
	for x := 0 to CountX - 1 do
	for y := 0 to CountY - 1 do
	for z := 0 to CountZ - 1 do
		begin
			value := GetValue(x, y, z);
			write('[',x, ',', y, ',', z, ']: ');
			//http://www.freepascal.org/docs-html/rtl/typinfo/ttypekind.html
			case typeKind of
				tkClass:
					begin
						if value <> Default(T) then
							TObjectPtr(@value)^.Show
						else
							writeln('default');
					end;
				tkPointer:
					begin
						if value <> Default(T) then
							writeln(HexStr(@value))
						else
							writeln('default');
					end;
				tkBool:
					if PBoolean(@value)^ then
						writeln('true')
					else
						writeln('false');
				otherwise
					writeln(PInteger(@value)^); // this is just a hack to print compiler types
			end;
		end;
	writeln(')');
end;

procedure TGenericMatrix.SetWeakRetain (newValue: boolean);
begin
	weakRetain := newValue;
end;

function TGenericMatrix.GetGridSize: TSize3D;
begin
	result := gridSize;
end;

function TGenericMatrix.Count: TMatrixIndex;
begin
	result := elementCount;
end;

procedure TGenericMatrix.SetGridSize (newValue: TSize3D);
begin
	gridSize := newValue;
	if gridSize.depth = 0 then
		gridSize.depth := 1;
	elementCount := CountX * CountY * CountZ;
	rows := CountX;
	plane := CountX * CountY;
	_table := TMatrixTablePtr(GetMem(Count * SizeOf(T)));
	FillChar(_table^, MemSize(_table), 0);
end;

function TGenericMatrix.GetEnumerator: TMatrixEnumerator;
begin
	result := TMatrixEnumerator.Create(self);
end;

function TGenericMatrix.RetainValue (value: T): T;
begin
	if weakRetain then
		exit(value);
	if (typeKind = tkClass) and (value <> Default(T)) then
		TObjectPtr(@value)^.Retain;
	result := value;
end;

procedure TGenericMatrix.ReleaseValue (value: T); 
begin
	if weakRetain then
		exit;
	if (typeKind = tkClass) and (value <> Default(T)) then
		TObjectPtr(@value)^.Release;
end;

procedure TGenericMatrix.Initialize;
begin
	inherited Initialize;
	
	typeKind := PTypeInfo(TypeInfo(T))^.kind;
	case typeKind of
		tkClass:
			weakRetain := false;
		otherwise
			weakRetain := true;
	end;
end;

procedure TGenericMatrix.Deallocate;
begin
	if not weakRetain then
		RemoveAllValues;
	
	FreeMem(_table);
	
	inherited Deallocate;
end;

constructor TGenericMatrix.Create (x, y: integer);
begin
	Create(SizeMake(x, y, 1));
end;

constructor TGenericMatrix.Create (x, y, z: integer);
begin
	Create(SizeMake(x, y, z));
end;

constructor TGenericMatrix.Create (_gridSize: TSize3D);
begin
	SetGridSize(_gridSize);
	Initialize;
end;

constructor TGenericMatrix.Create (_gridSize: TSize);
begin
	SetGridSize(SizeMake(_gridSize.width, _gridSize.height, 1));
	Initialize;
end;

end.