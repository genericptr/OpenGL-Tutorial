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
			
			{ Modifying }
			procedure AddLine (str: TStringInternal);
			procedure Append (str: TStringInternal);

			{ Stream }
			procedure Open (path: string);
			procedure Close;
			procedure Flush;

			{ Methods }
			function IsEqual (value: TObject): Boolean; override;
			function Compare (otherString: TString): integer;
			procedure Show; override;
			procedure WriteToFile (path: string);

		protected
			procedure Deallocate; override;
			procedure CopyInstanceVariables (clone: TObject); override;
			
		private
			ref: TStringInternal;
			_cString: PChar;
			fileHandle: TextFile;
			fileOpen: boolean;

			procedure LoadFromFile (path: string);
	end;

function TSTR (contents: TStringInternal): TString; overload;
function SortStringsCallback (value1: TObject; value2: TObject; context: pointer): integer;

operator + (a: TString; b: string): TString; overload;

implementation

{=============================================}
{@! ___PROCEDURAL___ } 
{=============================================}
operator + (a: TString; b: string): TString; overload;
begin
	a.AddLine(b);
	result := a;
end;

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

// http://wiki.freepascal.org/File_Handling_In_Pascal

procedure TString.Open (path: string);
begin
	try
		AssignFile(fileHandle, path);
		Rewrite(fileHandle);
		fileOpen := true;
  except
    on E:Exception do
      writeln(path+': '+E.Message);
  end;
end;

procedure TString.Close;
begin
	CloseFile(fileHandle);
	fileOpen := false;
end;

procedure TString.Flush;
begin
	System.Flush(fileHandle);
end;


procedure TString.LoadFromFile (path: string);
var
	f: TextFile;
	bytes: pointer;
	s: string;
begin
	try
		//AssignFile(f, path);
		//FileMode := fmOpenRead;
		//Reset(f, 1);
		//bytes := GetMem(FileSize(f));
		//BlockRead(f, bytes^, FileSize(f));
		//if MemSize(bytes) > 0 then
		//	begin
		//		ref := StrPas(pchar(bytes));
		//		SetLength(ref, FileSize(f));
		//	end;
		//CloseFile(f);
		//FreeMem(bytes);
		AssignFile(f, path);
		Reset(f);
		while not Eof(f) do
			begin
				Readln(f, s);
				AddLine(s);
			end;
		CloseFile(f);
  except
    on E:Exception do
      writeln(path+': ', E.Message);
  end;
end;

procedure TString.AddLine (str: TStringInternal);
begin
	ref += str+#10;
	if fileOpen then
		Writeln(fileHandle, str);
end;

procedure TString.Append (str: TStringInternal);
begin
	ref += str;
	if fileOpen then
		Write(fileHandle, str);
end;

procedure TString.WriteToFile (path: string);
var
	f: TextFile;
begin
	try
		AssignFile(f, path);
	  Rewrite(f);
	  Write(f, ref);
	  CloseFile(f);
  except
    on E:Exception do
      writeln(path, ': ', E.Message);
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
end;

begin
	RegisterClass(TString);
end.