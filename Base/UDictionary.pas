{$mode objfpc}

unit UDictionary;
interface
uses
	SysUtils, TypInfo, 
	UGeometry, UValue, UString, UObject;

type
	TDictionaryKey = string[40];
	TDictionaryKeyArray = array of TDictionaryKey;

	generic TGenericDictionary<T> = class (TObject)
		public
			type
				TDictionaryEntry = record
					key: TDictionaryKey;
					value: T;
				end;
		private
			type
				TDictionaryValuePtr = ^T;
				TDictionaryEntryArray = array[0..0] of TDictionaryEntry;
				TDictionaryEntryArrayPtr = ^TDictionaryEntryArray;
				TDictionaryValueArray = array of T;
				TDictionaryEnumerator = class
					private
						root: TGenericDictionary;
						currentValue: T;
						index: integer;
					public
						constructor Create (_root: TGenericDictionary); 
						function MoveNext: Boolean;
						procedure Reset;
						property CurrentIndex: integer read index;
						property Current: T read currentValue;
				end;
		public
			
			{ Constructors }
			constructor Create (elements: integer); overload;
			constructor Create (pairs: array of const); overload;
			constructor Create; overload;
			constructor Instance;
			
			{ Setting/Removing }
			procedure SetValue (key: TDictionaryKey; value: T); overload; virtual;
			procedure SetKeysAndValuesFromDictionary (otherDictionary: TGenericDictionary);

			procedure RemoveValue (key: TDictionaryKey);		
			procedure RemoveAllValues; virtual;
			
			{ Getting }
			function GetValue (key: TDictionaryKey): T; inline; overload;
			function GetValue (key: TDictionaryKey; out value): boolean; inline; overload;
			function GetValuePtr (key: TDictionaryKey): Pointer; inline;

			function GetAllKeys: TDictionaryKeyArray;
			function GetAllValues: TDictionaryValueArray;
			function GetEnumerator: TDictionaryEnumerator;
			function Count: integer;
			
			{ Querying }
			function ContainsKey (key: TDictionaryKey): boolean;
			function ContainsValue (value: T): boolean; virtual;
			procedure Show; override;
		
		public
			property Values[const key:TDictionaryKey]:T read GetValue write SetValue; default;
		protected
			procedure Initialize; override;
			procedure Deallocate; override;
			procedure CopyInstanceVariables (clone: TObject); override;
		private
			bucket: TDictionaryEntryArrayPtr;
			totalElements: integer;
			originalElements: integer;
			hashesChanged: boolean;
			valueCount: integer;
			weakRetain: boolean;
			typeKind: TTypeKind;
			
			function BucketCount: integer; inline;
			function GetValue (index: integer): T; inline; overload;
			function GetKey (index: integer): TDictionaryKey; inline;
			function KeyOfValue (value: T): TDictionaryKey; inline;
			procedure ReleaseValue (index: integer); inline;
			procedure RetainValue (value: T); inline;
			function CompareValues (a, b: T): boolean; inline;
			
			function Hash (key: TDictionaryKey): integer;
			procedure SetValue (index: integer; key: TDictionaryKey; value: T); overload;
			procedure Rehash (elements: integer);
	end;
		
type
	TDictionary = class (specialize TGenericDictionary<TObject>)
		public
			constructor Instance (args: array of const); overload;
			procedure SetValue (key: TDictionaryKey; value: TObject); override;
	end;	

type
	TDictionaryCommonTypesHelper = class helper for TDictionary
		procedure SetValue (key: TDictionaryKey; value: string); overload;
		procedure SetValue (key: TDictionaryKey; value: boolean); overload;
		procedure SetValue (key: TDictionaryKey; value: integer); overload;

		procedure SetSingleValue (key: TDictionaryKey; value: single);
		procedure SetFloatValue (key: TDictionaryKey; value: TFloat);
		
		function GetStringValue (key: TDictionaryKey): string;
		function GetIntegerValue (key: TDictionaryKey): integer;
		function GetBooleanValue (key: TDictionaryKey): boolean;
		function GetSingleValue (key: TDictionaryKey): single;
		function GetFloatValue (key: TDictionaryKey): TFloat;
	end;

type
	TIntegerDictionary = specialize TGenericDictionary<Integer>;
	TLongIntDictionary = specialize TGenericDictionary<LongInt>;
	TSingleDictionary = specialize TGenericDictionary<Single>;
	TDoubleDictionary = specialize TGenericDictionary<Double>;
	TStringDictionary = specialize TGenericDictionary<String>;
	TPointerDictionary = specialize TGenericDictionary<Pointer>;

function TDICT: TDictionary; overload;
function TDICT (args: array of const): TDictionary; overload;

implementation

{=============================================}
{@! ___PROCEURAL___ } 
{=============================================}
function TDICT: TDictionary;
begin
	result := TDictionary.Instance;
end;

function TDICT (args: array of const): TDictionary;
begin
	result := TDictionary.Instance(args);
end;

{=============================================}
{@! ___COMMON TYPES HELPER___ } 
{=============================================}
procedure TDictionaryCommonTypesHelper.SetSingleValue (key: TDictionaryKey; value: single);
begin
	SetValue(key, TNUM(value));
end;

procedure TDictionaryCommonTypesHelper.SetFloatValue (key: TDictionaryKey; value: TFloat);
begin
	SetValue(key, TNUM(value));
end;

procedure TDictionaryCommonTypesHelper.SetValue (key: TDictionaryKey; value: string);
begin
	SetValue(key, TSTR(value));
end;

procedure TDictionaryCommonTypesHelper.SetValue (key: TDictionaryKey; value: integer);
begin
	SetValue(key, TNUM(value));
end;

procedure TDictionaryCommonTypesHelper.SetValue (key: TDictionaryKey; value: boolean);
begin
	SetValue(key, TNUM(value));
end;

function TDictionaryCommonTypesHelper.GetStringValue (key: TDictionaryKey): string;
var
	value: TObject;
begin
	value := GetValue(key);
	if value <> nil then
		begin
			if value.IsMember(TNumber) then
				result := TNumber(value).StringValue
			else
				result := TString(value).GetString
		end
	else
		result := '';
end;

function TDictionaryCommonTypesHelper.GetIntegerValue (key: TDictionaryKey): integer;
var
	value: TObject;
begin
	value := GetValue(key);
	if value <> nil then
		begin
			if value.IsMember(TString) then
				begin
					if TString(value).GetString <> '' then
						result := StrToInt(TString(value).GetString)
					else
						result := 0;
				end
			else
				result := TNumber(value).IntegerValue;
		end
	else
		result := 0;
end;

function TDictionaryCommonTypesHelper.GetBooleanValue (key: TDictionaryKey): boolean;
var
	value: TObject;
begin
	value := GetValue(key);
	if value <> nil then
		begin
			if value.IsMember(TString) then
				begin
					if TString(value).GetString = 'true' then
						result := true
					else if TString(value).GetString = 'false' then
						result := false
					else if TString(value).GetString = '1' then
						result := true
					else
						result := false;
				end
			else
				result := TNumber(value).BooleanValue;
		end
	else
		result := false;
end;

function TDictionaryCommonTypesHelper.GetSingleValue (key: TDictionaryKey): single;
var
	value: TObject;
begin
	value := GetValue(key);
	if value <> nil then
		begin
			if value.IsMember(TString) then
				result := StrToFloat(TString(value).GetString)
			else
				result := TNumber(value).SingleValue;
		end
	else
		result := 0;
end;

function TDictionaryCommonTypesHelper.GetFloatValue (key: TDictionaryKey): TFloat;
var
	value: TObject;
begin
	value := GetValue(key);
	if value <> nil then
		begin
			if value.IsMember(TString) then
				result := StrToFloat(TString(value).GetString)
			else
				result := TNumber(value).FloatValue;
		end
	else
		result := 0;
end;

{=============================================}
{@! ___ENUMERATOR___ } 
{=============================================} 
constructor TGenericDictionary.TDictionaryEnumerator.Create(_root: TGenericDictionary);
begin
	inherited Create;
	root := _root;
end;
	
function TGenericDictionary.TDictionaryEnumerator.MoveNext: Boolean;
var
	count: integer;
begin
	count := root.BucketCount;
	if index = count then
		exit(false);
	while index < count do
		begin
			currentValue := root.GetValue(index);
			index += 1;
			if currentValue <> Default(T) then
				break;
		end;
	result := index <= count;
end;
	
procedure TGenericDictionary.TDictionaryEnumerator.Reset;
begin
	index := 0;
end;

{=============================================}
{@! ___GENERIC DICTIONARY___ } 
{=============================================}
function TGenericDictionary.BucketCount: integer;
begin
	result := totalElements;
end;

function TGenericDictionary.GetValue (index: integer): T;
begin
	result := bucket^[index].value;
end;

function TGenericDictionary.GetKey (index: integer): TDictionaryKey;
begin
	result := bucket^[index].key;
end;

function TGenericDictionary.CompareValues (a, b: T): boolean;
begin
	if typeKind = tkClass then
		result := TObjectPtr(@a)^.IsEqual(TObjectPtr(@b)^) 
	else
		result := a = b;
end;

function TGenericDictionary.KeyOfValue (value: T): TDictionaryKey;
var
	i: integer;
begin
	result := '';
	for i := 0 to BucketCount - 1 do
		if CompareValues(GetValue(i), value) then
			exit(GetKey(i));
end;

function TGenericDictionary.ContainsValue (value: T): boolean;
begin
	result := KeyOfValue(value) <> '';
end;

function TGenericDictionary.ContainsKey (key: TDictionaryKey): boolean;
begin
	result := GetValue(key) <> Default(T);
end;

function TGenericDictionary.Count: integer;
var
	i: integer;
begin
	if hashesChanged then
		begin
			valueCount := 0;
			for i := 0 to BucketCount - 1 do
				if GetValue(i) <> Default(T) then
					valueCount += 1;
			hashesChanged := false;
		end;
	result := valueCount;
end;

procedure TGenericDictionary.RemoveValue (key: TDictionaryKey);
var
	index: integer;
begin
	index := Hash(key);
	ReleaseValue(index);
	bucket^[index].key := '';
	bucket^[index].value := Default(T);
	//Rehash(BucketCount);
end;

procedure TGenericDictionary.RemoveAllValues;
var
	i: integer;
begin
	
	// iterate all values so ReleaseValue can be called to release memory
	if not weakRetain then
		for i := 0 to BucketCount - 1 do
			ReleaseValue(i);
	
	// NOTE: shrink memory or clear?
	FillChar(bucket[0], BucketCount * sizeof(TDictionaryEntry), 0);
end;

procedure TGenericDictionary.Rehash (elements: integer);
var
	i: integer;
	entries: TDictionaryEntryArrayPtr = nil;
	oldElemenents: integer;
begin	
	if elements = 0 then
		Fatal('Rehash can''t rehash to 0.');
	if elements = BucketCount then
		Fatal('Rehashing dictionary to same size');
		
	if originalElements = 0 then
		originalElements := elements;
	
	oldElemenents := BucketCount;
	if oldElemenents > 0 then
		begin
			// TODO: if we're not in a thread keep a global memory block for moving entities
			// so we don't realloc new mem always
			entries := TDictionaryEntryArrayPtr(GetMem(oldElemenents * Sizeof(TDictionaryEntry)));
			Move(bucket[0], entries[0], SizeOf(TDictionaryEntry) * oldElemenents)
		end;
	
	// resize array
	//writeln('rehash to ', elements);
	ReAllocMem(bucket, elements * SizeOf(TDictionaryEntry));
	FillChar(bucket[0], elements * sizeof(TDictionaryEntry), 0);
	totalElements := elements;
	
	// insert old entries again
	for i := 0 to oldElemenents - 1 do
	if entries^[i].value <> Default(T) then
		SetValue(entries^[i].key, entries^[i].value);
	
	if entries <> nil then
		FreeMem(entries);
		
	hashesChanged := true;
end;

function TGenericDictionary.Hash (key: TDictionaryKey): integer;
const
	kInitialValue = 5381;
	kM = 33;
var
	hashval: integer = kInitialValue;
	i: integer;
begin
	for i := 1 to Length(key) do
		hashval := kM * hashval + Ord(key[i]);
	result := abs(hashval mod BucketCount);
end;

procedure TGenericDictionary.ReleaseValue (index: integer);
var
	obj: TObject;
begin
	if weakRetain then
		exit;
	if (typeKind = tkClass) and (GetKey(index) <> '') and (GetValue(index) <> Default(T)) then
		begin
			obj := TObjectPtr(@bucket^[index].value)^;
			obj.Release;
		end;
end;

procedure TGenericDictionary.RetainValue (value: T);
var
	obj: TObject absolute value;
begin
	if weakRetain then
		exit;
	if (typeKind = tkClass) and (value <> Default(T)) then
		obj.Retain;
end;

procedure TGenericDictionary.SetKeysAndValuesFromDictionary (otherDictionary: TGenericDictionary);
var
	key: string;
begin
	for key in otherDictionary.GetAllKeys do
		SetValue(key, otherDictionary.GetValue(key));
end;

procedure TGenericDictionary.SetValue (index: integer; key: TDictionaryKey; value: T);
begin
	if value = Default(T) then
		raise Exception.Create('TGenericDictionary.SetValue: value can''t be default.');
	ReleaseValue(index);
	bucket^[index].key := key;
	bucket^[index].value := value;
	RetainValue(value);
	hashesChanged := true;
end;

procedure TGenericDictionary.SetValue (key: TDictionaryKey; value: T);
const
	kGrowSize = 2; // http://stackoverflow.com/questions/1100311/what-is-the-ideal-growth-rate-for-a-dynamically-allocated-array
var
	index: integer;
begin
	index := Hash(key);
	// available location, set value
	if GetValue(index) = Default(T) then
		SetValue(index, key, value)
	else
		begin
			// there is a collision because the key is not the same
			// but the index is occupied by a value 
			if GetKey(index) <> key then
				begin
					//writeln('collision detected for ', key, ' grow to ', Trunc(BucketCount * kGrowSize));
					Rehash(Trunc(BucketCount * kGrowSize));
					SetValue(key, value);
				end
			else 
				SetValue(index, key, value); // replace value since the key is the same
		end;
end;


function TGenericDictionary.GetAllValues: TDictionaryValueArray;
var
	i: integer;
	next: integer = 0;
begin
	SetLength(result, 0);
	for i := 0 to BucketCount - 1 do
	if GetValue(i) <> Default(T) then
		begin
			SetLength(result, Length(result) + 1);
			result[next] := GetValue(i);
			next += 1;
		end;
end;

function TGenericDictionary.GetAllKeys: TDictionaryKeyArray;
var
	i: integer;
	next: integer = 0;
begin
	if BucketCount = 0 then
		begin
			SetLength(result, 0);
			exit;
		end;
	SetLength(result, 0);
	for i := 0 to BucketCount - 1 do
	if GetValue(i) <> Default(T) then
		begin
			SetLength(result, Length(result) + 1);
			result[next] := GetKey(i);
			next += 1;
		end;
end;

function TGenericDictionary.GetEnumerator: TDictionaryEnumerator;
begin
	result := TDictionaryEnumerator.Create(self);
end;

function TGenericDictionary.GetValue (key: TDictionaryKey; out value): boolean;
var
	_value: T absolute value;
begin
	_value := GetValue(key);
	result := _value <> Default(T);
end;

function TGenericDictionary.GetValue (key: TDictionaryKey): T;
var
	entry: TDictionaryEntry;
begin
	if BucketCount = 0 then
		exit(Default(T));
	entry := bucket^[Hash(key)];
	if entry.key = key then
		result := entry.value
	else
		result := Default(T);
end;

function TGenericDictionary.GetValuePtr (key: TDictionaryKey): Pointer;
var
	entry: TDictionaryEntry;
	hashedKey: integer;
begin
	if BucketCount = 0 then
		exit(nil);
	hashedKey := Hash(key);
	if bucket^[hashedKey].key = key then
		result := @bucket^[hashedKey].value
	else
		result := nil;
end;

procedure TGenericDictionary.CopyInstanceVariables (clone: TObject);
var
	source: TGenericDictionary absolute clone;
	i: integer;
begin
	inherited CopyInstanceVariables(clone);
	
	if source.count > 0 then
		begin
			Rehash(source.count);
			
			if weakRetain then
				Move(source.bucket[0], bucket[0], Sizeof(TDictionaryEntry) * BucketCount)
			else
				begin
					for i := 0 to source.BucketCount - 1 do
					if source.bucket^[i].key <> '' then
						begin
							bucket^[i].key := source.bucket^[i].key;
							//bucket[i].value := source.bucket[i].value.Copy;
							CopyObject(bucket^[i].value, TObjectPtr(@source.bucket^[i].value)^);
						end;
				end;
		end;
end;

procedure TGenericDictionary.Show;
var
	key: TDictionaryKey;
	value: T;
begin
	writeln('{');
	for key in GetAllKeys do
		begin
			write(key,': ');
			value := GetValue(key);
			//GetValue(key).Show();
			//http://www.freepascal.org/docs-html/rtl/typinfo/ttypekind.html
			PrintValue(typeKind, @value);
		end;
	writeln('}');
end;

procedure TGenericDictionary.Initialize; 
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

procedure TGenericDictionary.Deallocate;
var
	i: integer;
begin
	if not weakRetain then
	for i := 0 to BucketCount - 1 do
		ReleaseValue(i);
	inherited Deallocate;
end;

constructor TGenericDictionary.Instance;
begin
	Create(0);
	AutoRelease;
end;

constructor TGenericDictionary.Create;
begin
	Create(0);
end;

constructor TGenericDictionary.Create (elements: integer);
begin
	if elements = 0 then
		elements := 12;
	Rehash(elements);
	Initialize;
end;

constructor TGenericDictionary.Create (pairs: array of const);
var
	i: integer = 0;
begin
	Initialize;
	// guess a best size
	Rehash(Length(pairs) * 2);
	while i < Length(pairs) do
		begin
			if pairs[i].vtype = vtChar then
				SetValue(pairs[i].vchar, TDictionaryValuePtr(@pairs[i+1].VObject)^)
			else if pairs[i].vtype = vtString then
				SetValue(pairs[i].VString^, TDictionaryValuePtr(@pairs[i+1].VObject)^);
			i += 2;
		end;		
end;

{=============================================}
{@! ___DICTIONARY___ } 
{=============================================}

// We need this for class helpers
procedure TDictionary.SetValue (key: TDictionaryKey; value: TObject);
begin
	inherited SetValue(key, value);
end;

constructor TDictionary.Instance (args: array of const);
var
	i: integer = 0;
	key: ansistring;
	value: TObject;
begin
	Create(length(args));
	while i < length(args) do
		begin
			
			// key
			case args[i].vtype of
				vtchar:
					key := args[i].vchar;
				vtString:
					key := args[i].VString^;
				vtPChar:
					key := args[i].VPChar;
				vtAnsiString:
					key := ansistring(args[i].VAnsiString);
				otherwise
					raise Exception.Create('TGenericDictionary: key type is invalid.');
			end;
			
			// value
			case args[i+1].vtype of
	      vtinteger:
					value := TNUM(args[i+1].vinteger);
	      vtboolean:
					value := TNUM(args[i+1].vboolean);
	      vtchar:
					value := TSTR(args[i+1].vchar);
	      vtString:
					value := TSTR(args[i+1].VString^);
	      //vtPointer:
	      //  Writeln (’Pointer, value : ’,Longint(Args[i].VPointer));
	      vtPChar :
					value := TSTR(args[i+1].VPChar);
	      vtObject:
	      	value := TObject(args[i+1].VObject);
	      //vtClass      :
	      //  Writeln (’Class reference, name :’,Args[i].VClass.Classname);
	      vtAnsiString:
					value := TSTR(AnsiString(args[i+1].VAnsiString));
	    	otherwise
	        raise Exception.Create('TGenericDictionary: value type is invalid.');
			end;
			
			SetValue(key, value);
			//writeln('key:',key);
			//value.Show;
			i += 2;
		end;
	AutoRelease;
end;

begin
	RegisterClass(TDictionary);
end.