{$mode objfpc}
{$interfaces CORBA}
{$modeswitch typehelpers}
{$modeswitch advancedrecords}

unit UTypes;
interface
uses
	CTypes, SysUtils, Math, Objects, Classes;

type
	TIntegerHelper = type helper for Integer
		function Clamp (lowest, highest: longint): longint;
		function Str: String;
		procedure Show;
	end;
	
type
	TLongIntHelper = type helper for LongInt
		function Clamp (lowest, highest: integer): integer;
		function Str: String;
		procedure Show;
	end;
	
type
	TSingleHelper = type helper for Single
		function Int: Integer;
		function Long: LongInt;
		function Round: LongInt;
		function Floor: LongInt;
		function Ceiling: LongInt;
		function Truc: LongInt;
		function Abs: Single;
		function Decimal: Single;
		function Clamp (lowest, highest: Single): Single;
		function Str: String;
		procedure Show;
		function IsIntegral: boolean;
	end;

type
	TDoubleHelper = type helper for Double
		function Str: String;
		procedure Show;
	end;

type
	TStringHelper = type helper for string
		function Int: integer;
		function Length: integer;
	end;


type	
  generic TDynamicList<T> = record
		private type
			FData = array of T;
		private
    	m_data: FData;	
			m_actualSize: integer;
			m_growSize: integer;
		public
			class function Make (_growSize: integer = 4): TDynamicList; static; inline;
			procedure Reset;
			procedure Clear;
	    procedure AddValue (const inValue: T);
			function GetValue (i: integer): T;
			function GetLastValue: T; 
	    function Count: integer; inline;
			function High: integer; inline;
			property Data: FData read m_data;
			
			class operator + (me: TDynamicList; const value: T): TDynamicList;
  end;

{$i UTypeSizes.inc}

type	
  generic TFixedList<T, L> = record
		private type
			FData = array[0..L.size] of T;
		private
    	m_data: FData;	
			m_actualSize: integer;
		public
			procedure Reset;
			procedure Clear;
			procedure AddValue (const value: T); 
			function GetValue (index: integer): T; 
			function GetLastValue: T; 
			function Count: integer; inline;
			function High: integer; inline;
			property Data: FData read m_data;
			
			class operator + (me: TFixedList; const value: T): TFixedList;
  end;	
	
type
	generic TArray3D<T> = array of array of array of T;
	generic TArray2D<T> = array of array of T;
	generic TArray1D<T> = array of T;

// TODO: UMath
function FMod(const a, b: Single): Single;
	
implementation

function FMod(const a, b: Single): Single;
begin
  result:= a-b * trunc(a/b);
end;

{=============================================}
{@! ___TYPE HELPERS___ } 
{=============================================}
function TLongIntHelper.Str: String;
begin
	result := IntToStr(self);
end;

procedure TLongIntHelper.Show;
begin
	writeln(Str);
end;

function TLongIntHelper.Clamp (lowest, highest: longint): longint;
begin
	if self < lowest then
		result := lowest
	else if self > highest then
		result := highest
	else
		result := self;
end;

function TIntegerHelper.Str: String;
begin
	result := IntToStr(self);
end;

procedure TIntegerHelper.Show;
begin
	writeln(Str);
end;

function TIntegerHelper.Clamp (lowest, highest: integer): integer;
begin
	if self < lowest then
		result := lowest
	else if self > highest then
		result := highest
	else
		result := self;
end;

function TSingleHelper.Round: LongInt;
begin
	result := System.Round(self);
end;

function TSingleHelper.Floor: LongInt;
begin
	result := Math.Floor(self);
end;

function TSingleHelper.Ceiling: LongInt;
begin
	result := Math.Ceil(self);
end;

function TSingleHelper.Truc: LongInt;
begin
	result := System.Trunc(self);
end;

function TSingleHelper.Decimal: Single;
begin
	result := FMod(System.Trunc(self), self);
end;

function TSingleHelper.Abs: Single;
begin
	result := System.Abs(self);
end;

function TSingleHelper.Long: LongInt;
begin
	result := System.Trunc(self);
end;

function TSingleHelper.Clamp (lowest, highest: Single): Single;
begin
	if self < lowest then
		result := lowest
	else if self > highest then
		result := highest
	else
		result := self;
end;

function TSingleHelper.Int: integer;
begin
	result := System.Trunc(self);
end;

function TSingleHelper.Str: string;
begin
	result := FloatToStr(self);
end;

procedure TSingleHelper.Show;
begin
	writeln(Str);
end;

function TSingleHelper.IsIntegral: boolean;
begin
	result := Int = self;
end;

function TStringHelper.Length: integer;
begin
	result := System.Length(self);
end;

function TStringHelper.Int: integer;
begin
	if System.Length(self) > 0 then
		result := StrToInt(self)
	else
		result := 0;
end;

function TDoubleHelper.Str: string;
begin
	result := FloatToStr(self);
end;

procedure TDoubleHelper.Show;
begin
	writeln(Str);
end;

{=============================================}
{@! ___FIXED LIST___ } 
{=============================================}
procedure TFixedList.Reset;
begin
	m_actualSize := 0;
end;	

procedure TFixedList.Clear;
begin
	FillChar(m_data, Length(m_data) * sizeof(T), 0);
	m_actualSize := 0;
end;	

procedure TFixedList.AddValue (const value: T); 
begin
	if Count = Length(m_data) then
		raise Exception.Create('Fixed list out of range');
	m_data[m_actualSize] := value;
	m_actualSize += 1;
end;	

function TFixedList.Count: integer;
begin
	result := m_actualSize;
end;
	
function TFixedList.High: integer;
begin
	result := Count - 1;
end;
	
function TFixedList.GetValue (index: integer): T;
begin
	result := m_data[index];
end;

function TFixedList.GetLastValue: T;
begin
	result := m_data[High];
end;

class operator TFixedList.+ (me: TFixedList; const value: T): TFixedList;
begin
	me.AddValue(value);
	result := me;
end;

{=============================================}
{@! ___DYNAMIC LIST___ } 
{=============================================}
procedure TDynamicList.Reset;
begin
	m_actualSize := 0;
end;	

procedure TDynamicList.Clear;
begin
	FillChar(m_data, Length(m_data) * sizeof(T), 0);
	m_actualSize := 0;
end;	

procedure TDynamicList.AddValue (const inValue: T);
begin
	// assume a default grow size if the array wasn't initialized
	if m_growSize = 0 then
		m_growSize := 4;
	// grow array
	if m_actualSize = Length(m_data) then
  	SetLength(m_data, m_actualSize + m_growSize);
  m_data[m_actualSize] := inValue;
	m_actualSize += 1;
end;

function TDynamicList.Count: integer;
begin
  result := m_actualSize;
end;

function TDynamicList.High: integer;
begin
  result := Count - 1;
end;
	
function TDynamicList.GetValue (i: integer): T;
begin
	result := m_data[i];
end;	

function TDynamicList.GetLastValue: T;
begin
	result := m_data[High];
end;

class function TDynamicList.Make (_growSize: integer = 4): TDynamicList;
begin
	result.m_actualSize := 0;
	result.m_growSize := _growSize;
end;

class operator TDynamicList.+ (me: TDynamicList; const value: T): TDynamicList;
begin
	me.AddValue(value);
	result := me;
end;

end.