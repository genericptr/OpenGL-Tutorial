{$mode objfpc}
{$i+}
unit UImage;
interface
uses
	BeRoPNG, SysUtils, UGeometry, UObject;

type
	TImage = class (TObject)
		public
			
			{ Class Methods }
			class function Instance (_path: string): TImage;
			
			{ Constructors }
			constructor Create (_path: string);
			
			{ Accessors }
			function GetData: Pointer;
			function GetWidth: integer;
			function GetHeight: integer;
			function GetSize: TSize;
			
		protected
			procedure Deallocate; override;
			procedure CopyInstanceVariables (clone: TObject); override;
		private
			imageData: Pointer;
			imageWidth: integer;
			imageHeight: integer;
			
			procedure LoadFromFile (path: string);
	end;

implementation

function TImage.GetData: Pointer;
begin
	result := imageData;
end;

function TImage.GetSize: TSize;
begin
	result := SizeMake(imageWidth, imageHeight);
end;

function TImage.GetWidth: integer;
begin
	result := imageWidth;
end;

function TImage.GetHeight: integer;
begin
	result := imageHeight;
end;

procedure TImage.CopyInstanceVariables (clone: TObject);
var
	image: TImage;
begin
	inherited CopyInstanceVariables(clone);
	
	image := TImage(clone);
	
	imageData := GetMemory(MemSize(image.imageData));
	Move(image.imageData^, imageData^, MemSize(imageData));
	
	imageWidth := image.imageWidth;
	imageHeight := image.imageHeight;
end;

procedure TImage.Deallocate;
begin
	if imageData <> nil then
		FreeMem(imageData);
		
	inherited Deallocate;
end;

procedure TImage.LoadFromFile (path: string);
type
	TPNGDataArray = array[0..0] of TPNGPixel;
	PPNGDataArray = ^TPNGDataArray;
var
	f: file;
	bytes: pointer;
	i: integer;
begin
	try
		AssignFile(f, path);
		FileMode := fmOpenRead;
	  Reset(f, 1);
	  bytes := GetMem(FileSize(f));
	  BlockRead(f, bytes^, FileSize(f));
	  CloseFile(f);
		
		if not LoadPNG(bytes, MemSize(bytes), imageData, imageWidth, imageHeight, false) then
			raise Exception.Create('LoadPNG: failed to load bytes.');
		
		//writeln(path);
		//for i := 0 to (imageHeight * imageWidth) - 1 do
		//	writeln('i ', i,' r ', PPNGDataArray(imageData)^[i].r, ' g ', PPNGDataArray(imageData)^[i].g, ' b ', PPNGDataArray(imageData)^[i].b, ' a ', PPNGDataArray(imageData)^[i].a);
		
		FreeMem(bytes);
  except
    on E:Exception do
      //writeln('TImage.LoadFromFile: ', E.Message, ' ', path);
			raise Exception.Create('TImage.LoadFromFile: '+E.Message+' ('+path+')');
  end;
end;

class function TImage.Instance (_path: string): TImage;
begin
	result := TImage.Create(_path);
	result.AutoRelease;
end;

constructor TImage.Create (_path: string);
begin
	Initialize;
	LoadFromFile(_path);
end;

begin
	RegisterClass(TImage);
end.