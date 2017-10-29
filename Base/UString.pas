{$mode objfpc}

unit UString;
interface
uses
	SysUtils, UObject;

type
	TStringInternal = AnsiString;

type
	TString = class (TObject)
		public
		
			{ Class Methods }
			class function StringFromFile (path: string): TString;
			class function CString (str: string): PChar;
			
			{ Constructors }
			constructor Instance (contents: TStringInternal);
			constructor Create (contents: TStringInternal); overload;
			
			{ Accessors }
			function GetString: TStringInternal;
			function GetLength: integer;
			function GetCharacter (i: integer): char;
			function GetCString: PChar;
			
			{ Methods }
			function IsEqual (value: TObject): Boolean; override;
			function Compare (otherString: TString): integer;
			procedure Show; override;
			
		protected
			procedure Deallocate; override;
			procedure CopyInstanceVariables (clone: TObject); override;
			
		private
			ref: TStringInternal;
			_cString: PChar;
			
			procedure LoadFromFile (path: string);
	end;

function TSTR (contents: TStringInternal): TString; overload;
function SortStringsCallback (value1: TObject; value2: TObject; context: pointer): integer;

implementation

{=============================================}
{@! ___PROCEDURAL___ } 
{=============================================}
function TSTR (contents: TStringInternal): TString; overload;
begin
	result := TString.Instance(contents);
end;

function SortStringsCallback (value1: TObject; value2: TObject; context: pointer): integer;
begin
	result := TString(value1).Compare(TString(value2));
end;

{=============================================}
{@! ___STRING___ } 
{=============================================}
procedure TString.LoadFromFile (path: string);
var
	f: File;
	bytes: pointer;
begin
	try
		AssignFile(f, path);
		FileMode := fmOpenRead;
	  Reset(f, 1);
	  bytes := GetMem(FileSize(f));
	  BlockRead(f, bytes^, FileSize(f));
		if MemSize(bytes) > 0 then
			begin
				ref := StrPas(pchar(bytes));
				SetLength(ref, FileSize(f));
			end;
	  CloseFile(f);
		FreeMem(bytes);
		{Fs   := TFileStream.Create(path, fmOpenRead); 
		   SetLength(tr, Fs.Size);
		   Fs.Read(tr[1], Fs.Size);
		   Showmessage(tr); 
		   Fs.Free;}
  except
    on E:Exception do
      writeln('TString.LoadFromFile: ', E.Message);
  end;
end;

procedure TString.CopyInstanceVariables (clone: TObject);
begin
	inherited CopyInstanceVariables(clone);
			
	ref := TString(clone).ref;
end;

procedure TString.Deallocate;
begin
	//writeln('TString.dealloc ', ref);
	if _cString <> nil then
		StrDispose(_cString);
		
	inherited Deallocate;
end;

function TString.GetLength: integer;
begin
	result := length(ref);
end;

function TString.GetCharacter (i: integer): char;
begin
	result := ref[i];
end;

function TString.GetCString: PChar;
begin
	// allocate one time and manage the value
	if _cString = nil then
		begin
			_cString := StrAlloc(GetLength+1);
			StrPCopy(_cString, ref);
		end;
	result := _cString;
end;

function TString.GetString: TStringInternal;
begin
	result := ref;
end;

function TString.Compare (otherString: TString): integer;
begin
	result := CompareStr(GetString, otherString.GetString);
end;

function TString.IsEqual (value: TObject): Boolean;
begin
	if value.IsMember(TString) then
		result := TString(value).GetString = GetString
	else
		result := false; // not TValue
end;

procedure TString.Show;
begin
	writeln(ref);
end;

constructor TString.Instance (contents: TStringInternal);
begin
	ref := contents;
	Initialize;
	AutoRelease;
end;

constructor TString.Create (contents: TStringInternal);
begin
	ref := contents;
	Initialize;
end;

// Auto releasing CString
class function TString.CString (str: string): PChar;
begin
	result := TSTR(str).GetCString;
end;

class function TString.StringFromFile (path: string): TString;
begin
	result := TString.Create;
	result.LoadFromFile(path);
	result.AutoRelease;
end;

begin
	RegisterClass(TString);
end.