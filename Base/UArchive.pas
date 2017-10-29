{$mode objfpc}
{$interfaces CORBA}

unit UArchive;
interface
uses
	Objects, TypInfo, SysUtils,
	UDictionary, UArray, UString, UData, UObject;

const
	kArchiveRootKey = 'ClassName';

type
	IObjectArchiving = interface ['IObjectArchiving']
		procedure EncodeData (data: TDictionary);
		procedure DecodeData (data: TDictionary);
	end;

type
	TObjectArchiveHelpers = class helper for TObject
		function ArchiveData: TDictionary;
	end;

{$M+}
type
	TArchivableObject = class (TObject, IObjectArchiving)
		protected
			procedure EncodeData (data: TDictionary); virtual;
			procedure DecodeData (data: TDictionary); virtual;
	end;
{$M-}

type
	TDictionaryArchiveHelper = class helper (TDictionaryCommonTypesHelper) for TDictionary
		function CopyArchive (key: TDictionaryKey): TObject;
		function GetArchiveValue (key: TDictionaryKey): TObject;
		function Unarchive: TObject;
	end;

function AllocateFromArchive (data: TDictionary): TObject; overload;

procedure EncodeProperties (from: TObject; data: TDictionary);
procedure DecodeProperties (from: TObject; data: TDictionary);

implementation

function TDictionaryArchiveHelper.Unarchive: TObject;
begin
	result := AllocateFromArchive(self).AutoRelease;
end;

function TDictionaryArchiveHelper.GetArchiveValue (key: TDictionaryKey): TObject;
begin
	result := CopyArchive(key).AutoRelease;
end;

function TDictionaryArchiveHelper.CopyArchive (key: TDictionaryKey): TObject;
begin
	result := AllocateFromArchive(TDictionary(GetValue(key)));
end;

function AllocateFromArchive (data: TDictionary): TObject;
var
	delegate: IObjectArchiving;
begin
	result := AllocateClass(data.GetStringValue(kArchiveRootKey));
	if result <> nil then
		begin
			if Supports(result, IObjectArchiving, delegate) then
				delegate.DecodeData(data)
			else
				raise Exception.Create(result.GetDebugString+' doesn''t implement IObjectArchiving');
			InitializeObject(result);
		end
	else
		raise Exception.Create('Archive object class is not registered or invalid.');
end;

procedure EncodeProperties (from: TObject; data: TDictionary);
Var
  PT : PTypeData;
  PI : PTypeInfo;
  I,J : Longint;
  PP : PPropList;
	obj: TObject;
begin
  PI:=from.ClassInfo;
  PT:=GetTypeData(PI);
  GetMem(PP,PT^.PropCount*SizeOf(Pointer));
  J:=GetPropList(PI,PP);
  For I:=0 to J-1 do
    begin
    With PP^[i]^ do
      begin
				// http://www.freepascal.org/docs-html/rtl/typinfo/ttypekind.html
				// http://www.freepascal.org/docs-html/rtl/typinfo/getordprop.html
				//writeln('encode ', name, ': ', PropType^.kind);
				case PropType^.kind of
					tkSString:
						data.SetValue(name, GetStrProp(from, name));
					tkInteger:
						data.SetValue(name, GetOrdProp(from, name));
					tkFloat:
						data.SetFloatValue(name, GetFloatProp(from, name));
					tkBool:
						if GetOrdProp(from, name) = 0 then
							data.SetValue(name, false)
						else
							data.SetValue(name, true);
					tkClass:
						begin
							obj := GetObjectProp(from, name) as TObject;
							if obj <> nil then
								data.SetValue(name, obj)
							else
								data.RemoveValue(name);
						end;
					otherwise
						//writeln(name, ': ', PropType^.name, ' = ', GetOrdProp(self, name));
						raise Exception.Create('The published property "'+name+'" can not be encoded.');
				end;
      end;
    end;
  FreeMem(PP);
end;

procedure DecodeProperties (from: TObject; data: TDictionary);
var
  PropIndex: Integer;
  PropCount: Integer;
  PropList: PPropList;
  PropInfo: PPropInfo;
	obj: TObject;
	value: TObject;
begin
  //PropCount := GetPropList(ClassInfo, nil);
  PropCount := GetTypeData(from.ClassInfo)^.PropCount;
  GetMem(PropList, PropCount * SizeOf(PPropInfo));
	GetPropList(from.ClassInfo, PropList);
	for PropIndex := 0 to PropCount - 1 do
	begin
	  PropInfo := PropList^[PropIndex];
		//writeln('set ivar: ', PropInfo^.Name);
	  if Assigned(PropInfo^.SetProc) then
	   case PropInfo^.PropType^.Kind of
	     tkString:
	       SetStrProp(from, PropInfo, data.GetStringValue(PropInfo^.Name));
			tkInteger:
				SetOrdProp(from, PropInfo, data.GetIntegerValue(PropInfo^.Name));
			tkFloat:
				SetFloatProp(from, PropInfo, data.GetFloatValue(PropInfo^.Name));
			tkBool:
				SetOrdProp(from, PropInfo, Ord(data.GetBooleanValue(PropInfo^.Name)));
			tkClass:
				begin					
					value := data.GetValue(PropInfo^.Name);
					if value.IsMember(TDictionary) then
						begin
							if TDictionary(value).ContainsKey(kArchiveRootKey) then
								obj := AllocateFromArchive(value as TDictionary)
							else
								obj := value.Retain;
						end
					else if value.IsMember(TArray) then	
						obj := value.Retain
					else
						raise Exception.Create('The archived property "'+PropInfo^.Name+'" must be a dictionary or array.');
					SetObjectProp(from, PropInfo, obj);
				end;
	     otherwise
	       raise Exception.Create('The published property "'+PropInfo^.Name+'" can not be decoded.');
	   end;
	end;
	FreeMem(PropList);
end;

procedure TArchivableObject.EncodeData (data: TDictionary);
begin
	data.SetValue(kArchiveRootKey, ClassName);
	EncodeProperties(self, data);
end;

procedure TArchivableObject.DecodeData (data: TDictionary);
begin
	DecodeProperties(self, data);
end;

function TObjectArchiveHelpers.ArchiveData: TDictionary;
var
	delegate: IObjectArchiving;
begin
	result := TDictionary.Instance;
	if Supports(self, IObjectArchiving, delegate) then
		delegate.EncodeData(result)
	else
		raise Exception.Create(GetDebugString+' doesn''t implement IObjectArchiving.');
end;

end.