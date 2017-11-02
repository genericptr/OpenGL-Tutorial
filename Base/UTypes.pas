{$mode objfpc}
{$interfaces CORBA}
{$modeswitch typehelpers}
{$modeswitch advancedrecords}

unit UTypes;
interface
uses
	USystem,
	CTypes, Math, Objects, Classes, SysUtils;

type
	TOrderedValue = integer;
const
  kOrderedAscending = -1;
  kOrderedSame = 0;
  kOrderedDescending = 1;		

type
	TIntegerHelper = type helper for Integer
		function Clamp (lowest, highest: integer): integer;
		function Str: String;
		function Ordered (other: integer; reverse: boolean = false): TOrderedValue;
		procedure Show;
	end;
	
type
	TLongIntHelper = type helper for LongInt
		function Clamp (lowest, highest: longint): longint;
		function Ordered (other: longint; reverse: boolean = false): TOrderedValue;
		function Str: String;
		procedure Show;
	end;
	
type
	TBooleanHelper = type helper for Boolean
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
		function Str (places: integer = -1): String;
		function Ordered (other: single; reverse: boolean = false): TOrderedValue;
		procedure Show;
		function IsIntegral: boolean;
	end;

type
	TDoubleHelper = type helper for Double
		function Str (places: integer = -1): String;
		procedure Show;
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
			procedure Free;
	    procedure AddValue (const inValue: T);
			function GetValue (i: integer): T;
			function GetLastValue: T; 
	    function Count: integer; inline;
			function High: integer; inline;
			function Empty: boolean; inline;
			property Data: FData read m_data;
		public
			property ArrayValues[const index:integer]:T read GetValue; default;	
			class operator + (me: TDynamicList; const value: T): TDynamicList; inline;
  end;

type
	TDynamicStringList = specialize TDynamicList<String>;
	
type
	TStringHelper = type helper for String
		function Int: integer; inline;
		function Length: integer; inline;
		function Single: single; inline;
		function Double: double; inline;
		function HasPrefix (prefix: string): boolean;
		function HasSuffix (suffix: string): boolean;
		function Split (delimiter: char): TDynamicStringList;
		function Wrapped (withChar: char): string; inline;
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
			class function Make: TFixedList; static; inline;
			
			procedure Reset;
			procedure Clear;
			procedure AddValue (const value: T); 
			function GetValue (index: integer): T; 
			function GetLastValue: T; 
			function Count: integer; inline;
			function High: integer; inline;
			property Data: FData read m_data;
		public
			property ArrayValues[const index:integer]:T read GetValue; default;	
			class operator + (me: TFixedList; const value: T): TFixedList;
  end;	
	
type
	generic TArray3D<T> = array of array of array of T;
	generic TArray2D<T> = array of array of T;
	generic TArray1D<T> = array of T;

type
	generic TRange<T> = record
		public
			min: T;
			max: T;
		public
			constructor Make (_min, _max: T); overload;
			constructor Make (values: array of T); overload;
			function Contains (value: T): boolean; overload;
			function Random: integer;
			function Total: T; inline;
			function Sum: T; inline;
			function Str: string;
			procedure Show;
	end;
	TRangeInt = specialize TRange<Integer>;
	TRangeFloat = specialize TRange<Single>;

type
	generic TMutableValue<T> = record
		public
			current: T;
			total: T;		
		public
			constructor Make (_total: T);
		
			procedure Subtract (amount: T);
			procedure Add (amount: T);
			class operator + (value: TMutableValue; amount: T): TMutableValue;
			class operator - (value: TMutableValue; amount: T): TMutableValue;
		
			function Str: string;
			procedure Show;
	end;
	TMutableValueInt = specialize TMutableValue<Integer>;
	TMutableValueFloat = specialize TMutableValue<Single>;
	
function PercentOfRange (range: TRangeInt; percent: single): integer; overload; inline;
function PercentOfRange (range: TRangeFloat; percent: single): Single; overload; inline;

// TODO: UMath
function FMod(const a, b: Single): Single;
function Clamp (int: integer; lowest, highest: integer): integer; inline; overload;

{ Random Numbers }
function GetRandomNumber (min, max: longint): longint;
function GetRandomFloat (min, max: single): single; overload;
function GetRandomFloat (min, max: single; decimal: integer): single; overload;
	
implementation

function Clamp (int: integer; lowest, highest: integer): integer;
begin
	result := int.Clamp(lowest, highest);
end;

function FMod(const a, b: Single): Single;
begin
  result:= a-b * trunc(a/b);
end;

{=============================================}
{@! ___RANDOM NUMBERS___ } 
{=============================================}
function GetRandomFloat (min, max: single): single; overload;
begin
	result := GetRandomFloat(min, max, 100);
end;

function GetRandomFloat (min, max: single; decimal: integer): single; overload;
begin
	result := GetRandomNumber(trunc(min * decimal), trunc(max * decimal)) / decimal;
end;

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

{=============================================}
{@! ___RANGE___ } 
{=============================================}

function TRange.Contains (value: T): boolean;
begin
	result := (value >= min) and (value <= max);
end;

constructor TRange.Make (values: array of T);
begin
	min := values[0];
	max := values[1];
end;

constructor TRange.Make (_min, _max: T);
begin
	min := _min;
	max := _max;
end;

function TRange.Random: T;
begin
	result := GetRandomNumber(Trunc(min), Trunc(max));
end;

function PercentOfRange (range: TRangeInt; percent: single): integer;
begin
	result := Trunc(range.min+((range.max-range.min)*percent));
end;

function PercentOfRange (range: TRangeFloat; percent: single): single;
begin
	result := range.min+((range.max-range.min)*percent);
end;

function TRange.Total: T;
begin
	result := max - min;
end;

function TRange.Sum: T;
begin
	result := max + min;
end;

function TRange.Str: string;
begin
	//result := '['+min.str+', '+max.str+']';
	result := min.str+'-'+max.str;
end;

procedure TRange.Show;
begin
	writeln(Str);
end;

{=============================================}
{@! ___MUTABLE VALUE___ } 
{=============================================}

constructor TMutableValue.Make (_total: T);
begin
	total := _total;
	current := total;
end;

class operator TMutableValue.+ (value: TMutableValue; amount: T): TMutableValue;
begin
	result := value;
	result.Add(amount);
end;

class operator TMutableValue.- (value: TMutableValue; amount: T): TMutableValue;
begin
	result := value;
	result.Subtract(amount);
end;

procedure TMutableValue.Subtract (amount: T);
begin
	current -= amount;
	if current < 0 then
		current := 0;
end;

procedure TMutableValue.Add (amount: T);
begin
	current += amount;
	if current > total then
		current := total;
end;

function TMutableValue.Str: string;
begin
	result := current.Str+'/'+total.Str;
end;

procedure TMutableValue.Show;
begin
	writeln(Str);
end;

{=============================================}
{@! ___TYPE HELPERS___ } 
{=============================================}
function TBooleanHelper.Str: String;
begin
	if self then
		result := 'true'
	else
		result := 'false';
end;

procedure TBooleanHelper.Show;
begin
	writeln(Str);
end;

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

function TLongIntHelper.Ordered (other: longint; reverse: boolean = false): TOrderedValue;
begin
	if reverse then
		begin
			if self < other then
				result := kOrderedAscending
			else if self > other then
				result := kOrderedDescending
			else
				result := kOrderedSame;
		end
	else
		begin
			if self > other then
				result := kOrderedAscending
			else if self < other then
				result := kOrderedDescending
			else
				result := kOrderedSame;
		end;
end;

function TIntegerHelper.Str: String;
begin
	result := IntToStr(self);
end;

function TIntegerHelper.Ordered (other: Integer; reverse: boolean = false): TOrderedValue;
begin
	if reverse then
		begin
			if self < other then
				result := kOrderedAscending
			else if self > other then
				result := kOrderedDescending
			else
				result := kOrderedSame;
		end
	else
		begin
			if self > other then
				result := kOrderedAscending
			else if self < other then
				result := kOrderedDescending
			else
				result := kOrderedSame;
		end;
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

function TSingleHelper.Ordered (other: Single; reverse: boolean = false): TOrderedValue;
begin
	if reverse then
		begin
			if self < other then
				result := kOrderedAscending
			else if self > other then
				result := kOrderedDescending
			else
				result := kOrderedSame;
		end
	else
		begin
			if self > other then
				result := kOrderedAscending
			else if self < other then
				result := kOrderedDescending
			else
				result := kOrderedSame;
		end;
end;

function TSingleHelper.Str (places: integer = -1): string;
begin
	if places = -1 then
		result := FloatToStr(self)
	else if places = 0 then
		result := FloatToStr(Trunc(self))
	else
		result := Format('%.'+IntToStr(places)+'f', [self]);
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

function TStringHelper.Single: single;
begin
	result := StrToFloat(self);
end;

function TStringHelper.Double: double;
begin
	result := StrToFloat(self);
end;

function TStringHelper.Wrapped (withChar: char): string;
begin
	result := withChar+self+withChar;
end;
	
function TStringHelper.Split (delimiter: char): TDynamicStringList;
var
	i: integer;
	c: char;
	part: string = '';
	parts: TDynamicStringList;
begin
	parts := TDynamicStringList.Make; 
	for i := 1 to Length do
		begin
			c := self[i];
			if (c = delimiter) or (i = Length) then
				begin
					if (i = Length) then
						part += c;
					parts += part;
					part := '';
				end
			else
				part += c;
		end;
	result := parts;
end;

function TStringHelper.HasPrefix (prefix: string): boolean;
var
	i: integer;
begin
	result := true;
	for i := 1 to prefix.Length do
	if self[i] <> prefix[i] then
		exit(false);
end;

function TStringHelper.HasSuffix (suffix: string): boolean;
var
	i: integer;
begin
	result := true;
	for i := 1 to suffix.Length do
	if self[(Length+1) - i] <> suffix[(suffix.Length+1) - i] then
		exit(false);
end;

function TDoubleHelper.Str (places: integer = -1): string;
begin
	if places = -1 then
		result := FloatToStr(self)
	else if places = 0 then
		result := FloatToStr(Trunc(self))
	else
		result := Format('%.'+IntToStr(places)+'f', [self]);
end;

procedure TDoubleHelper.Show;
begin
	writeln(Str);
end;

{=============================================}
{@! ___FIXED LIST___ } 
{=============================================}
class function TFixedList.Make: TFixedList;
begin
	result.Clear;
end;

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
	Fatal(Count = Length(m_data), 'Fixed list out of range');
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

procedure TDynamicList.Free;
begin
	SetLength(m_data, 0);
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

function TDynamicList.Empty: boolean;
begin
	result := Count = 0;
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

begin
	System.Randomize;	
end.