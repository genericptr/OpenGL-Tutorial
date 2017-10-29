{$mode objfpc}

unit FileUtils;
interface
uses
	Classes, FileUtil,
	UArray, UString,
	StrUtils, SysUtils;

function ExtractFileNameWithoutExtension (fileName: string): string;
function FindAllFiles(dir: string): TArray; overload;
function IsFileHidden (fileName: string): boolean;

implementation

function IsFileHidden (fileName: string): boolean;
var
	f: Longint;
begin
	f := FileGetAttr(fileName);
	if f <> -1 then
		result := (f and faHidden) <> 0
	else
		result := false;
end;

// TODO: FindAllFiles to use TStringArray or Dynamic Array (TArray1D<String>)
function FindAllFiles (dir: string): TArray; overload;
var
	files: TStringList;
	i: integer;
begin
	result := TARR;
	files := FindAllFiles(dir, '', false); 
  for i := 0 to files.count - 1 do
		result.AddValue(TSTR(files.strings[i]));
end;

function ExtractFileNameWithoutExtension (fileName: string): string;
begin
	fileName := ExtractFileName(fileName);
	result := StringReplace(fileName, ExtractFileExt(fileName), '', []);
end;

end.