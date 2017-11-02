{$mode objfpc}

unit UBag;
interface
uses
	UDictionary, UArray, UObject,
	SysUtils;

type
	generic TGenericBag<T> = class (specialize TGenericDictionary<TObject>)
		public type TBagList = specialize TGenericArray<T>;
		public
			function AddValue (key: TDictionaryKey; value: T): TBagList;
			procedure RemoveValue (key: TDictionaryKey; value: T); overload;		
			procedure RemoveIndex (key: TDictionaryKey; index: TArrayIndex);
			
			function ContainsValue (key: TDictionaryKey; value: T): boolean; overload;
			function ContainsValue (value: T): boolean; overload;
			
			function ListCount (key: TDictionaryKey): integer;
			function GetList (key: TDictionaryKey): TBagList;
			function GetLastValue (key: TDictionaryKey): T;
			
			procedure Sort (key: TDictionaryKey; comparator: TBagList.TComparator; context: pointer = nil);
			
			property BagList [const key: TDictionaryKey]: TBagList read GetList; default;	
		private
			function CompareValues (a, b: T): boolean;
	end;

type
	TBag = specialize TGenericBag<TObject>;

implementation
uses
	TypInfo;
	
function TGenericBag.ListCount (key: TDictionaryKey): integer;
var
	list: TBagList;
begin
	list := GetList(key);
	if list <> nil then
		result := list.Count
	else
		result := 0;
end;

function TGenericBag.GetLastValue (key: TDictionaryKey): T;
var
	list: TBagList;
begin
	list := GetList(key);
	if list <> nil then
		result := list.GetLastValue
	else
		result := Default(T);
end;

function TGenericBag.GetList (key: TDictionaryKey): TBagList;
begin
	result := TBagList(GetValue(Hash(key)));
end;

procedure TGenericBag.Sort (key: TDictionaryKey; comparator: TBagList.TComparator; context: pointer = nil);
var
	list: TBagList;
begin
	list := GetList(key);
	if list <> nil then
		list.Sort(comparator, context);
end;

procedure TGenericBag.RemoveIndex (key: TDictionaryKey; index: TArrayIndex);
var
	list: TBagList;
begin
	list := GetList(key);
	if list <> nil then
		list.RemoveIndex(index);
end;

procedure TGenericBag.RemoveValue (key: TDictionaryKey; value: T);
var
	list: TBagList;
begin
	list := GetList(key);
	if list <> nil then
		list.RemoveFirstValue(value);
end;

function TGenericBag.AddValue (key: TDictionaryKey; value: T): TBagList;
var
	list: TBagList;
begin
	list := GetList(key);
	if list = nil then
		begin
			list := TBagList.Create;
			list.AddValue(value);
			SetValue(key, list);
			list.Release;
		end
	else
		list.AddValue(value);
	result := list;
end;

function TGenericBag.CompareValues (a, b: T): boolean;
begin
	if typeKind = tkClass then
		result := TObjectPtr(@a)^.IsEqual(TObjectPtr(@b)^) 
	else
		result := a = b;
end;

function TGenericBag.ContainsValue (key: TDictionaryKey; value: T): boolean;
var
	list: TBagList;
	i: TArrayIndex;
begin
	list := GetList(key);
	if list <> nil then
		begin
			for i := 0 to list.High do
			if CompareValues(value, list.GetValue(i)) then
				exit(true);
		end
	else
		result := false;
end;

function TGenericBag.ContainsValue (value: T): boolean;
var
	i, b: TArrayIndex;
	list: TBagList;
begin
	result := false;
	for i := 0 to BucketCount - 1 do
		begin
			list := TBagList(GetValue(i));
			if list <> nil then
			for b := 0 to list.High do
				if CompareValues(list.GetValue(b), value) then
					exit(true);
		end;
end;

begin
	RegisterClass(TBag);
end.