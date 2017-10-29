{$mode objfpc}
{$modeswitch advancedrecords}

unit UColor;
interface
uses
	UArray, UGeometry, UObject,
	SysUtils;

type
	TRGBA = record
		//red, green, blue, alpha: TFloat;
				
		class function Make (r, g, b, a: TFloat): TRGBA; static; inline;
		class function RedColor (r: TFloat = 1; g: TFloat = 0; b: TFloat = 0; a: TFloat = 1): TRGBA; static; inline;
		class function GreenColor (r: TFloat = 0; g: TFloat = 1; b: TFloat = 0; a: TFloat = 1): TRGBA; static; inline;
		class function BlueColor (r: TFloat = 0; g: TFloat = 0; b: TFloat = 1; a: TFloat = 1): TRGBA; static; inline;
		class function WhiteColor (r: TFloat = 1; g: TFloat = 1; b: TFloat = 1; a: TFloat = 1): TRGBA; static; inline;
		class function BlackColor (r: TFloat = 0; g: TFloat = 0; b: TFloat = 0; a: TFloat = 1): TRGBA; static; inline;
		class function ClearColor (r: TFloat = 0; g: TFloat = 0; b: TFloat = 0; a: TFloat = 0): TRGBA; static; inline;
			
		function Add (amount: TFloat): TRGBA; overload;
		function Add (amount: TRGBA): TRGBA; overload;
		function Divide (amount: TFloat): TRGBA; overload;
		function Divide (amount: TRGBA): TRGBA; overload;
		function Multiply (amount: TFloat): TRGBA; overload;
		function Multiply (amount: TRGBA): TRGBA; overload;
		
		function Transparency (a: TFloat): TRGBA;
		
		procedure Show;
		function Str: string;
		
		case integer of
			0:
				(red, green, blue, alpha: TFloat);
			1:
				(c: array[0..3] of TFloat);
	end;

type
	TColor = class (TObject)
		public
			
			{ Class Methods }
			class function From (r, g, b, a: TFloat): TColor; overload;
			class function From (color: TRGBA): TColor; overload;
			class function From (w, a: TFloat): TColor; overload;
			class function From (components: TArray): TColor; overload;
			
			class function RedColor: TColor;
			class function GreenColor: TColor;
			class function BlueColor: TColor;
			class function WhiteColor: TColor;
			class function BlackColor: TColor;
			class function LightGrayColor: TColor;
			class function GrayColor: TColor;
			class function DarkGrayColor: TColor;
			class function ClearColor: TColor;
			
			{ Constructors }
			constructor Create (r, g, b, a: TFloat); overload;
			constructor Create (components: TArray); overload;
			
			{ Accessors }
			function GetRedComponent: TFloat;	
			function GetGreenComponent: TFloat;	
			function GetBlueComponent: TFloat;	
			function GetAlphaComponent: TFloat;	
			function GetRGBColor: TRGBA;
			function GetComponents: TArray;
			
			procedure Show; override;
		protected
			procedure CopyInstanceVariables (clone: TObject); override;
		private
			color: TRGBA;
	end;

function RGBColorMake (r, g, b, a: TFloat): TRGBA; overload;
function RGBColorMake (components: TArray): TRGBA; overload;
function RGBColorCompare (color1, color2: TRGBA): boolean;
function RGBColorComponents (color: TRGBA): TArray;
function RGBColorIsValid (color: TRGBA): boolean;

implementation

class function  TRGBA.Make (r, g, b, a: TFloat): TRGBA;
begin
	result.red := r;
	result.green := g;
	result.blue := b;
	result.alpha := a;
end;

class function TRGBA.RedColor (r: TFloat = 1; g: TFloat = 0; b: TFloat = 0; a: TFloat = 1): TRGBA;
begin
	result := Make(r, g, b, a);
end;

class function TRGBA.GreenColor (r: TFloat = 0; g: TFloat = 1; b: TFloat = 0; a: TFloat = 1): TRGBA;
begin
	result := Make(r, g, b, a);
end;

class function TRGBA.BlueColor (r: TFloat = 0; g: TFloat = 0; b: TFloat = 1; a: TFloat = 1): TRGBA;
begin
	result := Make(r, g, b, a);
end;

class function TRGBA.WhiteColor (r: TFloat = 1; g: TFloat = 1; b: TFloat = 1; a: TFloat = 1): TRGBA;
begin
	result := Make(r, g, b, a);
end;

class function TRGBA.BlackColor (r: TFloat = 0; g: TFloat = 0; b: TFloat = 0; a: TFloat = 1): TRGBA;
begin
	result := Make(r, g, b, a);
end;

class function TRGBA.ClearColor (r: TFloat = 0; g: TFloat = 0; b: TFloat = 0; a: TFloat = 0): TRGBA;
begin
	result := Make(r, g, b, a);
end;

function TRGBA.Add (amount: TFloat): TRGBA; overload;
begin
	result := RGBColorMake(red + amount, green + amount, blue + amount, alpha + amount);
end;

function TRGBA.Divide (amount: TFloat): TRGBA; overload;
begin
	result := RGBColorMake(red / amount, green / amount, blue / amount, alpha / amount);
end;

function TRGBA.Multiply (amount: TFloat): TRGBA; overload;
begin
	result := RGBColorMake(red * amount, green * amount, blue * amount, alpha * amount);
end;

function TRGBA.Add (amount: TRGBA): TRGBA; overload;
begin
	result := RGBColorMake(red + amount.red, green + amount.green, blue + amount.blue, alpha + amount.alpha);
end;

function TRGBA.Divide (amount: TRGBA): TRGBA; overload;
begin
	result := RGBColorMake(red / amount.red, green / amount.green, blue / amount.blue, alpha / amount.alpha);
end;

function TRGBA.Multiply (amount: TRGBA): TRGBA; overload;
begin
	result := RGBColorMake(red * amount.red, green * amount.green, blue * amount.blue, alpha * amount.alpha);
end;

function TRGBA.Transparency (a: TFloat): TRGBA;
begin
	result := TRGBA.Make(red, green, blue, a);
end;

function TRGBA.Str: string;
begin
	result := '{'+FloatToStr(red)+','+FloatToStr(green)+','+FloatToStr(blue)+','+FloatToStr(alpha)+'}';
end;

procedure TRGBA.Show;
begin
	writeln(Str);
end;

function RGBColorIsValid (color: TRGBA): boolean;
begin
	result := ((color.red > 0) or (color.green > 0) or (color.blue > 0)) and (color.alpha > 0);
end;

function RGBColorComponents (color: TRGBA): TArray;
begin
	result := TARR([color.red, color.green, color.blue, color.alpha]);
end;

function RGBColorCompare (color1, color2: TRGBA): boolean;
begin
	result := (color1.red = color2.red) and (color1.green = color2.green) and (color1.blue = color2.blue) and (color1.alpha = color2.alpha);
end;

function RGBColorMake (components: TArray): TRGBA;
begin
	result.red := components.GetFloatValue(0);
	result.green := components.GetFloatValue(0);
	result.blue := components.GetFloatValue(0);
	result.alpha := components.GetFloatValue(0);
end;

function RGBColorMake (r, g, b, a: TFloat): TRGBA;
begin
	result.red := r;
	result.green := g;
	result.blue := b;
	result.alpha := a;
end;

function TColor.GetRedComponent: TFloat;
begin
	result := color.red;
end;

function TColor.GetGreenComponent: TFloat;
begin
	result := color.green;
end;

function TColor.GetBlueComponent: TFloat;
begin
	result := color.blue;
end;

function TColor.GetAlphaComponent: TFloat;	
begin
	result := color.alpha;
end;

function TColor.GetComponents: TArray;
begin
	result := TARR([color.red, color.green, color.blue, color.alpha]);
end;

function TColor.GetRGBColor: TRGBA;
begin
	result := color;
end;

class function TColor.From (components: TArray): TColor;
begin
	result := TColor.Create(components);
	result.AutoRelease;
end;

class function TColor.From (color: TRGBA): TColor;
begin
	result := TColor.Create(color.red, color.green, color.blue, color.alpha);
	result.AutoRelease;
end;

class function TColor.From (r, g, b, a: TFloat): TColor;
begin
	result := TColor.Create(r, g, b, a);
	result.AutoRelease;
end;

class function TColor.From (w, a: TFloat): TColor;
begin
	result := TColor.Create(w, w, w, a);
	result.AutoRelease;
end;

class function TColor.RedColor: TColor;
begin
	result := TColor.From(1, 0, 0, 1);
end;

class function TColor.GreenColor: TColor;
begin
	result := TColor.From(0, 1, 0, 1);
end;

class function TColor.BlueColor: TColor;
begin
	result := TColor.From(0, 0, 1, 1);
end;

class function TColor.WhiteColor: TColor;
begin
	result := TColor.From(1, 1, 1, 1);
end;

class function TColor.BlackColor: TColor;
begin
	result := TColor.From(0, 0, 0, 1);
end;

class function TColor.LightGrayColor: TColor;
begin
	result := TColor.From(0.2, 0.25, 0.25, 1);
end;

class function TColor.GrayColor: TColor;
begin
	result := TColor.From(0.5, 0.5, 0.5, 1);
end;

class function TColor.DarkGrayColor: TColor;
begin
	result := TColor.From(0.75, 0.75, 0.75, 1);
end;

class function TColor.ClearColor: TColor;
begin
	result := TColor.From(0, 0, 0, 0);
end;

constructor TColor.Create (components: TArray);
begin
	color := RGBColorMake(components.GetFloatValue(0), components.GetFloatValue(1), components.GetFloatValue(2), components.GetFloatValue(3));
	Initialize;
end;

constructor TColor.Create (r, g, b, a: TFloat);			
begin
	color := RGBColorMake(r, g, b, a);
	Initialize;
end;

procedure TColor.CopyInstanceVariables (clone: TObject);
begin
	inherited CopyInstanceVariables(clone);
			
	color := TColor(clone).color;
end;

procedure TColor.Show;
begin
	writeln('{', color.red:1:1, ',', color.green:1:1, ',', color.blue:1:1, ',', color.alpha:1:1, '}');
end;

begin
	RegisterClass(TColor);
end.