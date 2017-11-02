{$mode objfpc}
{$modeswitch advancedrecords}

unit UValue;
interface
uses
	SysUtils, UGeometry, UTypes, UObject;

{const
	IComparableUUID = 110544543;

type
	IComparable = interface (IObject) ['IComparable']
		function CompareTo (value: TObject): integer;
	end;}

type
	TValue = class (TObject)
		public
			function GetKind: integer;
			function GetDescription: string; override;
			function IsEqual (value: TObject): Boolean; override;
		protected
			procedure Deallocate; override;
			procedure CopyInstanceVariables (clone: TObject); override;
		private
			bytes: pointer;
			kind: integer;
			function GetSize: longint;
			constructor Create (_bytes: pointer; size: longint; _kind: integer);			
	end;

type
	TGeometryValueHelpers = class helper for TValue
		class function ValueWithPoint (point: TPoint): TValue; overload;
		class function ValueWithPoint (point: TPoint3D): TValue; overload;
		class function ValueWithRect (rect: TRect): TValue;
		class function ValueWithSize (size: TSize): TValue;
		
		function PointValue: TPoint;
		function Point3DValue: TPoint3D;
		function RectValue: TRect;
		function SizeValue: TSize;
	end;

type
	TPointerValueHelpers = class helper(TGeometryValueHelpers) for TValue
		class function ValueWithPointer (ref: pointer; byteCount: longint): TValue;
		function PointerValue: pointer;
	end;

type
	TNumber = class (TValue)
		public
			class function From (value: integer): TNumber; overload;		
			class function From (value: single): TNumber; overload;	
			class function From (value: boolean): TNumber; overload;	
			class function Default: TNumber;
			
			constructor Create (value: integer); overload;		
			constructor Create (value: single); overload;	
			constructor Create (value: boolean); overload;	
			
			function Compare (by: TNumber): integer;
			
			procedure SetValue (newValue: integer); overload;
			
			function IntegerValue: integer;
			function SingleValue: single;
			function FloatValue: single;
			function BooleanValue: boolean;
			function StringValue: string;
	end;

type
	TNull = class (TObject)
	end;

{=============================================}
{@! ___Geometry Value Helpers___ } 
{=============================================}

type
	TPointValueHelper = record helper (TPointHelper) for TPoint
		function Value: TValue;
	end;
	
type
	TPoint3DValueHelper = record helper for TPoint3D
		function Value: TValue;
	end;

type
	TRectValueHelper = record helper for TRect
		function Value: TValue;
	end;

type
	TSizeValueHelper = record helper for TSize
		function Value: TValue;
	end;

const
	kNumberKindInteger = 0;
	kNumberKindLong = 1;
	kNumberKindSingle = 3;
	kNumberKindDouble = 4;
	kNumberKindBoolean = 5;
	kNumberKindPointer = 6;
	
function TNUM (value: integer): TNumber; overload;	
function TNUM (value: boolean): TNumber; overload;	
function TNUM (value: single): TNumber; overload;	
function SortNumbersCallback (value1: TObject; value2: TObject; context: pointer): integer;
	
implementation

const
	kGeometryKindPoint = 100;
	kGeometryKindRect = 101;
	kGeometryKindSize = 102;
	kGeometryKindPoint3D = 103;

type
	IntegerPtr = ^Integer;
	LongIntPtr = ^LongInt;
	SinglePtr = ^Single;
	BooleanPtr = ^Boolean;

var
	GlobalDefaultNumber: TNumber = nil;
	
{=============================================}
{@! ___PROCEDURAL___ } 
{=============================================}
function SortNumbersCallback (value1: TObject; value2: TObject; context: pointer): integer;
begin
	result := TNumber(value1).Compare(TNumber(value2));
end;

function TNUM (value: integer): TNumber;
begin
	result := TNumber.From(value);
end;

function TNUM (value: single): TNumber;
begin
	result := TNumber.From(value);
end;

function TNUM (value: boolean): TNumber;
begin
	result := TNumber.From(value);
end;

{=============================================}
{@! ___POINTER HELPERS___ } 
{=============================================}
class function TPointerValueHelpers.ValueWithPointer (ref: pointer; byteCount: longint): TValue;
begin
	result := TValue.Create(ref, byteCount, kNumberKindPointer);
	result.AutoRelease;
end;

function TPointerValueHelpers.PointerValue: pointer;
begin
	result := bytes;
end;

{=============================================}
{@! ___GEOMETRY HELPERS___ } 
{=============================================}
function TRectValueHelper.Value: TValue;
begin
	result := TValue.Create(@self, sizeof(TRect), kGeometryKindRect);
	result.AutoRelease;
end;

function TPointValueHelper.Value: TValue;
begin
	result := TValue.Create(@self, sizeof(TPoint), kGeometryKindPoint);
	result.AutoRelease;
end;

function TPoint3DValueHelper.Value: TValue;
begin
	result := TValue.Create(@self, sizeof(TPoint3D), kGeometryKindPoint3D);
	result.AutoRelease;
end;

function TSizeValueHelper.Value: TValue;
begin
	result := TValue.Create(@self, sizeof(TSize), kGeometryKindSize);
	result.AutoRelease;
end;

class function TGeometryValueHelpers.ValueWithPoint (point: TPoint): TValue;
begin
	result := TValue.Create(@point, sizeof(TPoint), kGeometryKindPoint);
	result.AutoRelease;
end;

class function TGeometryValueHelpers.ValueWithPoint (point: TPoint3D): TValue;
begin
	result := TValue.Create(@point, sizeof(TPoint3D), kGeometryKindPoint3D);
	result.AutoRelease;
end;

class function TGeometryValueHelpers.ValueWithRect (rect: TRect): TValue;
begin
	result := TValue.Create(@rect, sizeof(TRect), kGeometryKindRect);
	result.AutoRelease;
end;

class function TGeometryValueHelpers.ValueWithSize (size: TSize): TValue;
begin
	result := TValue.Create(@size, sizeof(TSize), kGeometryKindSize);
	result.AutoRelease;
end;

function TGeometryValueHelpers.PointValue: TPoint;
begin
	if kind = kGeometryKindPoint then
		result := TPointPtr(bytes)^
	else
		raise Exception.Create('TValue.GetValue: wrong type: '+IntToStr(kind));
end;

function TGeometryValueHelpers.Point3DValue: TPoint3D;
begin
	if kind = kGeometryKindPoint3D then
		result := TPoint3DPtr(bytes)^
	else
		raise Exception.Create('TValue.GetValue: wrong type: '+IntToStr(kind));
end;

function TGeometryValueHelpers.RectValue: TRect;
begin
	if kind = kGeometryKindRect then
		result := TRectPtr(bytes)^
	else
		raise Exception.Create('TValue.GetValue: wrong type: '+IntToStr(kind));
end;

function TGeometryValueHelpers.SizeValue: TSize;
begin
	if kind = kGeometryKindSize then
		result := TSizePtr(bytes)^
	else
		raise Exception.Create('TValue.GetValue: wrong type: '+IntToStr(kind));
end;

{=============================================}
{@! ___VALUE___ } 
{=============================================}
constructor TValue.Create (_bytes: pointer; size: longint; _kind: integer);
begin
	kind := _kind;
	bytes := GetMemory(size);
	Move(_bytes^, bytes^, size);
	Initialize;
end;

function TValue.GetSize: longint;
begin
	result := MemSize(bytes);
end;

function TValue.IsEqual (value: TObject): Boolean;
var
	val: TValue;
begin
	val := TValue(value);
	if val.IsMember(TValue) then
		begin
			if val.GetKind = GetKind then
				begin
					case kind of
						kNumberKindInteger:
							result := IntegerPtr(val.bytes)^ = IntegerPtr(bytes)^;
						kNumberKindLong:
							result := LongIntPtr(val.bytes)^ = LongIntPtr(bytes)^;
						kNumberKindSingle:
							result := SinglePtr(val.bytes)^ = SinglePtr(bytes)^;
						kNumberKindBoolean:
							result := BooleanPtr(val.bytes)^ = BooleanPtr(bytes)^;
						kNumberKindPointer:
							result := val.bytes = bytes;
						kGeometryKindPoint:
							result := PointEqualToPoint(TPointPtr(val.bytes)^, TPointPtr(bytes)^);
						kGeometryKindPoint3D:
							result := PointEqualToPoint(TPoint3DPtr(val.bytes)^, TPoint3DPtr(bytes)^);
						kGeometryKindRect:
							result := RectEqualToRect(TRectPtr(val.bytes)^, TRectPtr(bytes)^);
						kGeometryKindSize:
							result := SizeEqualToSize(TSizePtr(val.bytes)^, TSizePtr(bytes)^);
					end;
				end
			else
				result := false; // different kinds
		end
	else
		result := false; // not TValue
end;

function TValue.GetKind: integer;
begin
	result := kind;
end;

function TValue.GetDescription: string;
begin
	case kind of
		kNumberKindInteger:
			result := IntToStr(IntegerPtr(bytes)^);
		kNumberKindLong:
			result := IntToStr(LongIntPtr(bytes)^);
		kNumberKindSingle:
			result := FloatToStr(SinglePtr(bytes)^);
		kNumberKindBoolean:
			if BooleanPtr(bytes)^ then	
				result := 'true'
			else
				result := 'false';
		kNumberKindPointer:
			result := HexStr(bytes);
		kGeometryKindPoint:
			result := TSTR(TPointPtr(bytes)^);
		kGeometryKindPoint3D:
			result := TSTR(TPoint3DPtr(bytes)^);
		kGeometryKindRect:
			result := TSTR(TRectPtr(bytes)^);
		kGeometryKindSize:
			result := TSTR(TSizePtr(bytes)^);
		otherwise
			result := '???';
	end;
end;

procedure TValue.CopyInstanceVariables (clone: TObject);
var
	value: TValue;
begin
	inherited CopyInstanceVariables(clone);
	
	value := TValue(clone);
	
	bytes := GetMemory(value.GetSize);
	Move(value.bytes^, bytes^, MemSize(bytes));
		
	kind := value.kind;
end;

procedure TValue.Deallocate;
begin
	//write(ClassName, '.dealloc: ');Show;
	FreeMemory(bytes);
	
	inherited Deallocate;
end;

{=============================================}
{@! ___NUMBER___ } 
{=============================================}
function TNumber.BooleanValue: boolean;
begin
	if kind = kNumberKindBoolean then
		result := BooleanPtr(bytes)^
	else if kind = kNumberKindInteger then
		begin
			if IntegerPtr(bytes)^ = 1 then
				result := true
			else if IntegerPtr(bytes)^ = 0 then
				result := false
			else
				raise Exception.Create('TNumber.BooleanValue: integer out of range: '+IntToStr(IntegerPtr(bytes)^));
		end
	else if kind = kNumberKindSingle then
		begin
			if SinglePtr(bytes)^ = 1 then
				result := true
			else if SinglePtr(bytes)^ = 0 then
				result := false
			else
				raise Exception.Create('TNumber.BooleanValue: float out of range: '+FloatToStr(SinglePtr(bytes)^));
		end
	else
		raise Exception.Create('TNumber.BooleanValue: wrong type: '+IntToStr(kind));
end;

function TNumber.StringValue: string;
begin
	result := GetDescription;
end;

procedure TNumber.SetValue (newValue: integer);
begin
	if kind = kNumberKindInteger then
		IntegerPtr(bytes)^ := newValue
	else
		Fatal('TNumber.SetValue: wrong value type');
end;

function TNumber.IntegerValue: integer;
begin
	if kind = kNumberKindInteger then
		result := IntegerPtr(bytes)^
	else if kind = kNumberKindSingle then
		result := round(SinglePtr(bytes)^)
	else if kind = kNumberKindBoolean then
		begin
			if BooleanPtr(bytes)^ then
				result := 1
			else
				result := 0;
		end
	else
		raise Exception.Create('TNumber.IntegerValue: wrong type: '+IntToStr(kind));
end;

function TNumber.FloatValue: TFloat;
begin
	if kind = kNumberKindSingle then
		result := SinglePtr(bytes)^
	else if kind = kNumberKindInteger then
		result := IntegerPtr(bytes)^
	else if kind = kNumberKindBoolean then
		begin
			if BooleanPtr(bytes)^ then
				result := 1
			else
				result := 0;
		end
	else
		raise Exception.Create('TNumber.FloatValue: wrong type: '+IntToStr(kind));
end;

function TNumber.SingleValue: single;
begin
	if kind = kNumberKindSingle then
		result := SinglePtr(bytes)^
	else if kind = kNumberKindInteger then
		result := IntegerPtr(bytes)^
	else if kind = kNumberKindBoolean then
		begin
			if BooleanPtr(bytes)^ then
				result := 1
			else
				result := 0;
		end
	else
		raise Exception.Create('TNumber.GetValue: wrong type: '+IntToStr(kind));
end;

function TNumber.Compare (by: TNumber): integer;
begin
	if IntegerValue > by.IntegerValue then
		result := kOrderedDescending
	else if IntegerValue < by.IntegerValue then
		result := kOrderedAscending
	else
		result := kOrderedSame;
end;

// Placeholder for null
class function TNumber.Default: TNumber;
begin
	result := GlobalDefaultNumber;
end;

constructor TNumber.Create (value: integer);
begin
	Create(@value, sizeof(integer), kNumberKindInteger);
end;

constructor TNumber.Create (value: single);
begin
	Create(@value, sizeof(single), kNumberKindSingle);
end;

constructor TNumber.Create (value: boolean);
begin
	Create(@value, sizeof(boolean), kNumberKindBoolean);
end;

class function TNumber.From (value: boolean): TNumber;
begin
	result := TNumber.Create(value);
	result.AutoRelease;
end;

class function TNumber.From (value: integer): TNumber;
begin
	result := TNumber.Create(value);
	result.AutoRelease;
end;

class function TNumber.From (value: single): TNumber;
begin
	result := TNumber.Create(value);
	result.AutoRelease;
end;

var
	falseValue: boolean = false;
begin
	GlobalDefaultNumber := TNumber.Create(@falseValue, sizeof(boolean), kNumberKindBoolean);
	RegisterClass(TNumber);
end.