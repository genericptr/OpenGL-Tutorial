{$mode objfpc}

unit UFont;
interface
uses
	UObject, UDictionary, UGeometry,
	SysUtils;

type
	TFontSize = integer;

type
	TFont = class (TObject)
		public
		
			{ Class Methods }
			class function Named (_name: string; _size: TFontSize): TFont; overload;
			class function Named (_name: string; _size: TFontSize; _bitmapScale: TFloat): TFont; overload;
			
			{ Built-in }
			class function SystemFontOfSize (_size: TFontSize): TFont;
			class function BoldSystemFontOfSize (_size: TFontSize): TFont;
			
			{ Constuctors }
			constructor Create (_name: string; _size: TFontSize);			
			
			{ Accessors }
			procedure SetAntiAliased (newValue: boolean);
			
			function GetName: string;
			function GetSize: TFontSize;
			function GetBitmapScale: TFloat;
			
			function IsAntiAliased: boolean;
			
			{ Methods }
			procedure Show; override;
			
		protected
			procedure Initialize; override;
			procedure CopyInstanceVariables (clone: TObject); override;
		private
			name: string;
			size: TFontSize;
			antiAliased: boolean;
			bitmapScale: TFloat;
	end;

implementation

var
	SystemFontName: string = '';
	
{=============================================}
{@! ___FONT___ } 
{=============================================}
function TFont.IsAntiAliased: boolean;
begin
	result := antiAliased;
end;

class function TFont.Named (_name: string; _size: TFontSize): TFont;
begin
	result := TFont.Create(_name, _size);
	result.AutoRelease;
end;

class function TFont.Named (_name: string; _size: TFontSize; _bitmapScale: TFloat): TFont;
begin
	result := TFont.Create(_name, _size);
	result.bitmapScale := _bitmapScale;
	result.AutoRelease;
end;

class function TFont.SystemFontOfSize (_size: TFontSize): TFont;
begin
	result := Named(SystemFontName, _size);
end;

class function TFont.BoldSystemFontOfSize (_size: TFontSize): TFont;
begin
	result := Named(SystemFontName, _size);
end;

constructor TFont.Create (_name: string; _size: TFontSize);			
begin
	name := _name;
	size := _size;
	Initialize;
end;

procedure TFont.SetAntiAliased (newValue: boolean);
begin
	antiAliased := newvalue;
end;

function TFont.GetName: string;
begin
	result := name;
end;

function TFont.GetSize: TFontSize;
begin
	result := size;
end;

function TFont.GetBitmapScale: TFloat;
begin
	result := bitmapScale;
end;

procedure TFont.Initialize;
begin
	inherited Initialize;
	
	bitmapScale := 1.0;
end;

procedure TFont.CopyInstanceVariables (clone: TObject);
var
	font: TFont;
begin
	inherited CopyInstanceVariables(clone);
	
	font := TFont(clone);
	
	name := font.name;
	size := font.size;
	bitmapScale := font.bitmapScale;
end;

procedure TFont.Show;
begin
	writeln(GetName, ' ', GetSize, 'pt');
end;

begin
	RegisterClass(TFont);
end.