{$mode objfpc}
{$include targetos}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}

unit UGeometry;
interface
uses	
	FPJSON, JSONParser, SysUtils, Math, UTypes;

type
	TFloat = single;

{
TVec3f = TVec3<TFloat>
TVec3Int = TVec3<Integer>

TPoint3D = TVec3f
TTileCoord = TVec3Int
}

type
	TPointPtr = ^TPoint;
	TPoint = record
		public
			x: TFloat;
			y: TFloat;
		public
			class function Make (_x, _y: TFloat): TPoint; static; inline;
			class function Invalid: TPoint; static; inline;
			class function Zero: TPoint; static; inline;
		
			{ Angles }
			class function FromAngleInDegrees (degrees: TFloat): TPoint; static; inline;
			class function FromAngleInRadians (radians: TFloat): TPoint; static; inline;
		
			{ Directions }
			class function Up (_x: TFloat = 0; _y: TFloat = -1): TPoint; static;
			class function Down (_x: TFloat = 0; _y: TFloat = 1): TPoint; static;
			class function Left (_x: TFloat = -1; _y: TFloat = 0): TPoint; static;
			class function Right (_x: TFloat = 1; _y: TFloat = 0): TPoint; static;
			class function UpLeft (_x: TFloat = -1; _y: TFloat = -1): TPoint; static;
			class function UpRight (_x: TFloat = 1; _y: TFloat = -1): TPoint; static;
			class function DownLeft (_x: TFloat = -1; _y: TFloat = 1): TPoint; static;
			class function DownRight (_x: TFloat = 1; _y: TFloat = 1): TPoint; static;
			
			procedure Show;
			function Str (places: integer = 0): string;
		
			function IsZero: boolean;
			function IsValid: boolean;
			function IsEqual (point: TPoint): boolean;
			function Offset (byX, byY: TFloat): TPoint; overload;
			function Offset (point: TPoint): TPoint; overload;
			function Floor: TPoint;
			function Integral: TPoint;
			function Trunc: TPoint;
			function Ceil: TPoint;
			function Round: TPoint;
			function Abs: TPoint;
			function IsIntegral: boolean;
			function Clamp (lowest, highest: TPoint): TPoint; overload;
			function Clamp (lowest, highest: TFloat): TPoint; overload;
			procedure SetPoint (_x, _y: TFloat);
		
			{ Math }
			function Divide (amount: TFloat): TPoint; overload;
			function Divide (amount: TPoint): TPoint; overload;
			function Multiply (amount: TFloat): TPoint; overload;
			function Multiply (amount: TPoint): TPoint; overload;
			function Add (amount: TFloat): TPoint; overload;
			function Add (amount: TPoint): TPoint; overload;
			function Subtract (amount: TPoint): TPoint; overload;
			function Subtract (amount: TFloat): TPoint; overload;
				
			{ Operators }
			class operator + (p1: TPoint; p2: TPointPtr): TPoint; overload;
			class operator - (p1: TPoint; p2: TPointPtr): TPoint; overload; 
		
			class operator + (p1, p2: TPoint): TPoint; overload;
			class operator - (p1, p2: TPoint): TPoint; overload; 
			class operator * (p1, p2: TPoint): TPoint; overload; 
			class operator / (p1, p2: TPoint): TPoint; overload;
			class operator = (p1, p2: TPoint): boolean; 
		
			class operator + (p1: TPoint; p2: TFloat): TPoint; overload; 
			class operator - (p1: TPoint; p2: TFloat): TPoint; overload; 
			class operator * (p1: TPoint; p2: TFloat): TPoint; overload; 
			class operator / (p1: TPoint; p2: TFloat): TPoint; overload;
		
			{ Vector Helpers }
			function Magnitude: TFloat;
			function Distance (point: TPoint): TFloat;
			function Normalize: TPoint;
			function Dot (point: TPoint): TFloat; inline;
			function Negate: TPoint; inline;
			function PerpendicularRight: TPoint; inline;
			function PerpendicularLeft: TPoint; inline;
			function Angle: TFloat;

			{ Utilities }
			function Min: TFloat; inline;			// x < y
			function Max: TFloat; inline;			// x > y
			function Sum: TFloat; inline;
			function Compare (_x, _y: TFloat): boolean;
		
			{ Directions }
			function ManhattanDirection (tileCoord: TPoint): TPoint;
		
			function EuclideanDistance (toPoint: TPoint): TFloat;
			function DiagonalDistance (toPoint: TPoint): integer;
			function ManhattanDistance (toPoint: TPoint): integer;
	end;

	TPoint3D = record
		public
			x: TFloat;
			y: TFloat;
			z: TFloat;
		public
			{ Constructors }
			class function Make (_x, _y, _z: TFloat): TPoint3D; static; inline;
			class function Invalid: TPoint3D; static; inline;
			class function Zero: TPoint3D; static; inline;
		
			{ Methods }
			procedure Show;
			function Str (places: integer = 0): string;
			function IsZero: boolean;
			function IsValid: boolean;
			function IsEqual (point: TPoint3D): boolean;
			function IsEqualXY (point: TPoint3D): boolean;
			function IsIntegral: boolean;
			function Offset (byX, byY: TFloat): TPoint3D; overload;
			function Offset (byX, byY, byZ: TFloat): TPoint3D; overload;
			function Offset (point: TPoint3D): TPoint3D; overload;
			function Integral: TPoint3D;
			function Floor: TPoint3D;
			function Trunc: TPoint3D;
			function Ceil: TPoint3D;
			function Round: TPoint3D;
			function Abs: TPoint3D;
			function Clamp (lowest, highest: TPoint3D): TPoint3D; overload;
			function Clamp (lowest, highest: TFloat): TPoint3D; overload;
			function Sum: TFloat;
			procedure SetPoint (_x, _y, _z: TFloat);
		
			{ Math }
			function Add (amount: TFloat): TPoint3D; overload;
			function Add (amount: TPoint3D): TPoint3D; overload;
			function Subtract (amount: TFloat): TPoint3D; overload;
			function Subtract (amount: TPoint3D): TPoint3D; overload;
			function Divide (amount: TFloat): TPoint3D;
			function Multiply (amount: TFloat): TPoint3D; overload;
			function Multiply (amount: TPoint3D): TPoint3D; overload;
		
			function Point2D: TPoint;
		
			{ Operators }
			class operator + (p1: TPoint3D; p2: TPointPtr): TPoint3D; overload; inline;
			class operator - (p1: TPoint3D; p2: TPointPtr): TPoint3D; overload; inline; 
			
			class operator + (p1, p2: TPoint3D): TPoint3D; overload; inline;
			class operator - (p1, p2: TPoint3D): TPoint3D; overload; inline; 
			class operator * (p1, p2: TPoint3D): TPoint3D; overload; inline; 
			class operator / (p1, p2: TPoint3D): TPoint3D; overload; inline;
			class operator = (p1, p2: TPoint3D): boolean; inline;
		
			class operator + (p1: TPoint3D; p2: TFloat): TPoint3D; overload; inline;
			class operator - (p1: TPoint3D; p2: TFloat): TPoint3D; overload; inline;
			class operator * (p1: TPoint3D; p2: TFloat): TPoint3D; overload; inline;
			class operator / (p1: TPoint3D; p2: TFloat): TPoint3D; overload; inline;
		
			class operator + (p1: TPoint3D; p2: TPoint): TPoint3D; overload; inline;
			class operator - (p1: TPoint3D; p2: TPoint): TPoint3D; overload; inline;
			class operator * (p1: TPoint3D; p2: TPoint): TPoint3D; overload; inline;
			class operator / (p1: TPoint3D; p2: TPoint): TPoint3D; overload; inline;
		
			{ Vector Helpers }
			function Magnitude: TFloat;
			function Distance (point: TPoint3D): TFloat;
			function Normalize: TPoint3D; inline;
			function Dot (point: TPoint3D): TFloat; inline;
			function Cross (point: TPoint3D): TPoint3D;
			function Negate: TPoint3D; inline;
			function PerpendicularRight: TPoint3D; inline;
			function PerpendicularLeft: TPoint3D; inline;
			function AngleTo (constref b:TPoint3D): TFloat; inline;
			function Angle (constref b,c:TPoint3D):TFloat; inline;
			function SquaredLength: TFloat; inline;

			{ Helpers }
			function Compare (_x, _y, _z: TFloat): boolean;
		
			{ Distance }
			function EuclideanDirection (tileCoord: TPoint3D): TPoint3D;
			function ManhattanDirection (tileCoord: TPoint3D): TPoint3D;
		
			function EuclideanDistance (toPoint: TPoint3D): TFloat;
			function ManhattanDistance (toPoint: TPoint3D): integer;

			property XY: TPoint read Point2D;
	end;
	TPoint3DPtr = ^TPoint3D;
								
type
	TSize = record
		public
			width: TFloat;
			height: TFloat;
		public
			{ Methods }
			class function Make (w, h: TFloat): TSize; static; inline;
			class function Make (size: TFloat): TSize; static; inline;
		
			procedure Show;
			function Str (places: integer = 0): string;
			function IsEqual (size: TSize): boolean; inline;
			function IsZero: boolean; inline;
			function IsInfinte: boolean; inline;
			function Floor: TSize;
			function Ceil: TSize;
			function Min: TFloat;
			function Max: TFloat;
			function Sum: TFloat;
			function Area: TFloat;
			function Vector: TPoint;
		
			{ Math }
			function Add (amount: TFloat): TSize; overload;
			function Add (amount: TSize): TSize; overload;
			function Divide (amount: TFloat): TSize; overload;
			function Divide (amount: TSize): TSize; overload;
			function Multiply (amount: TSize): TSize; overload;
			function Multiply (amount: TFloat): TSize; overload;
		
			{ Operators }
			class operator + (s1, s2: TSize): TSize; overload;
			class operator - (s1, s2: TSize): TSize; overload; 
			class operator * (s1, s2: TSize): TSize; overload; 
			class operator / (s1, s2: TSize): TSize;  overload;
		
			class operator + (s1: TSize; s2: TFloat): TSize; overload; 
			class operator - (s1: TSize; s2: TFloat): TSize; overload; 
			class operator * (s1: TSize; s2: TFloat): TSize; overload; 
			class operator / (s1: TSize; s2: TFloat): TSize; overload;
		
			class operator = (s1, s2: TSize): boolean; 
			
			{ Properties }
			property w: TFloat read width;
			property h: TFloat read height;
	end;
	TSizePtr = ^TSize;
	
type
	TPolygon = record
		public
			v: array of TPoint;
		public
			constructor Make (_verticies: integer);
			procedure SetVerticies (_verticies: integer);
			procedure AddVertex (x, y: TFloat); overload;
			procedure AddVertex (point: TPoint); overload;
			procedure SetVertex (index: integer; point: TPoint);
			function ContainsPoint (point: TPoint): boolean;
			procedure Offset (x, y: TFloat); overload;
			procedure Offset (amount: TPoint); overload;
			function GetVertex (index: integer): TPoint;			
			function High: integer;
			function Count: integer;
			function Str: AnsiString;
			procedure Show;
		public
			property Verticies[const index:integer]:TPoint read GetVertex; default;
	end;	
	
type
	TRect = record
		public
			origin: TPoint;
			size: TSize;
		public
			{ Constructors }
			class function Make (x, y, width, height: TFloat): TRect; static; inline;
			class function Make (point: TPoint): TRect; static; inline;
			class function Empty: TRect; static; inline;
			class function Infinite: TRect; static; inline;
			
			{ Methods }
			procedure Show;
			function Str (places: integer = 0): string;
		
			{ Helpers }
		  function Offset (x, y: TFloat): TRect; overload; inline;
			function Offset (point: TPoint): TRect; overload; inline;
	
		  function Inset (x, y: TFloat): TRect; overload; inline;
		  function Inset (amount: TFloat): TRect; overload; inline;
		  function Resize (width, height: TFloat): TRect; overload; inline;
		  function Resize (s: TSize): TRect; overload; inline;
		  function Resize (s: TFloat): TRect; overload; inline;
			function Union (rect: TRect): TRect; inline;
			function Clamp (point: TPoint): TPoint;
			
		  function Integral: TRect; inline;
			function Floor: TRect; inline;
			function Ceil: TRect; inline;
		
			function SetOrigin (x, y: TFloat): TRect;
			function SetSize (width, height: TFloat): TRect;
			function IsEmpty: boolean;
			function Polygon: TPolygon;
		
			function ContainsPoint (point: TPoint): boolean;
			function ContainsRect (rect: TRect): boolean;
			function IntersectsRect (rect: TRect): boolean;
		
			{ Operators }
			class operator + (r1, r2: TRect): TRect; overload;
			class operator - (r1, r2: TRect): TRect; overload; 
			class operator * (r1, r2: TRect): TRect; overload; 
			class operator / (r1, r2: TRect): TRect;  overload;
		                  
			class operator + (r1: TRect; r2: TFloat): TRect; overload; 
			class operator - (r1: TRect; r2: TFloat): TRect; overload; 
			class operator * (r1: TRect; r2: TFloat): TRect; overload; 
			class operator / (r1: TRect; r2: TFloat): TRect; overload;
		
			class operator = (r1, r2: TRect): boolean; 
		
			{ Math }
			function Divide (amount: TFloat): TRect; inline;
			function Multiply (amount: TFloat): TRect; inline;
		
			{ Absolute Coords }
			function Min: TPoint; inline;
			function Max: TPoint; inline;
			function Mid: TPoint; inline;

			function GetTopLeft: TPoint; inline;
			function GetTopRight: TPoint; inline;
			function GetBottomLeft: TPoint; inline;
			function GetBottomRight: TPoint; inline;
			function GetCenter: TPoint; inline;
		
			{ Relative Coords }
			function GetMinX: TFloat; inline;
			function GetMidX: TFloat; inline;
			function GetMaxX: TFloat; inline;
			function GetMinY: TFloat; inline;
			function GetMidY: TFloat; inline;
			function GetMaxY: TFloat; inline;
		
			function GetWidth: TFloat; inline;
			function GetHeight: TFloat; inline;
			
			{ Properties }
			property x: TFloat read origin.x write origin.x;
			property y: TFloat read origin.y write origin.y;
			property w: TFloat read size.width write size.width;
			property h: TFloat read size.height write size.height;
	end;
	TRectPtr = ^TRect;
	
type
	TSize3D = record
		public
			width: TFloat;		// x
			height: TFloat;		// y
			depth: TFloat;		// z
		public
			{ Constructor }
			class function Make (_width, _height, _depth: TFloat): TSize3D; overload; static; inline;
			class function Make (size: TSize): TSize3D; overload; static; inline;
			class function Make (_volume: TFloat): TSize3D; overload; static; inline;
		
			{ Methods }
			procedure Show;
			function Str (places: integer = 0): string;
			function IsEqual (size: TSize3D): boolean; inline;
			function IsZero: boolean; inline;
			function Floor: TSize3D;
			function Ceil: TSize3D;
			function Size2D: TSize;
			function WH: TSize;
			function Sum: TFloat;
			function Volume: TFloat;
			function SetDepth (newValue: TFloat): TSize3D;
			function Vector: TPoint3D;
		
			{ Math }
			function Add (amount: TFloat): TSize3D; overload;
			function Add (amount: TSize3D): TSize3D; overload;
			function Divide (amount: TFloat): TSize3D; overload;
			function Divide (amount: TSize3D): TSize3D; overload;
			function Multiply (amount: TSize3D): TSize3D; overload;
			function Multiply (amount: TFloat): TSize3D; overload;
		
			{ Operators }
			class operator + (s1, s2: TSize3D): TSize3D; overload;
			class operator - (s1, s2: TSize3D): TSize3D; overload; 
			class operator * (s1, s2: TSize3D): TSize3D; overload; 
			class operator / (s1, s2: TSize3D): TSize3D;  overload;
		
			class operator + (s1: TSize3D; s2: TFloat): TSize3D; overload; 
			class operator - (s1: TSize3D; s2: TFloat): TSize3D; overload; 
			class operator * (s1: TSize3D; s2: TFloat): TSize3D; overload; 
			class operator / (s1: TSize3D; s2: TFloat): TSize3D; overload;
		
			class operator = (s1, s2: TSize3D): boolean; 
	end;	
	
type
	TRect3D = record
		public
			origin: TPoint3D;
			size: TSize3D;
		public
			{ Constructor }
			class function Make (x, y, z, width, height, depth: TFloat): TRect3D; overload; static;
			class function Make (rect: TRect): TRect3D; overload; static;
			class function Make (rect: TRect; originZ, sizeDepth: TFloat): TRect3D; overload; static;
			class function Empty: TRect3D; static; inline;
				
			{ Accessors }
			function Min: TPoint3D; inline;
			function Mid: TPoint3D; inline;
			function Max: TPoint3D; inline;
		
			function MinX: TFloat; inline;
			function MidX: TFloat; inline;
			function MaxX: TFloat; inline;
		
			function MinY: TFloat; inline;
			function MidY: TFloat; inline;
			function MaxY: TFloat; inline;
		
			function MinZ: TFloat; inline;
			function MidZ: TFloat; inline;
			function MaxZ: TFloat; inline;
		
			function Width: TFloat; inline;
			function Height: TFloat; inline;
			function Depth: TFloat; inline;
		
			function Center: TPoint3D; inline;
				
			{ Methods }
			procedure Show;
			function Str (places: integer = 0): string;	
			function Rect2D: TRect;	
			function IsEmpty: boolean;
		
			function Union (rect: TRect3D): TRect3D;
			function Inset (x, y, z: TFloat): TRect3D;
		
			function IntersectsRect (rect: TRect3D): boolean;
			function ContainsPoint (point: TPoint3D): boolean;
	end;

// TODO: aabb's can be replaced by TRect by adding constructors and min/max properties		
type
	TAABB2 = record
		public
			min: TPoint;
			max: TPoint;
		public
			{ Constructors }
			constructor Make (_minX, _maxX: TFloat; _minY, _maxY: TFloat); overload;
			constructor Make (_min, _max: TPoint); overload;
			constructor Make (rect: TRect); overload;

			{ Points }
			function MinX: TFloat; inline;
			function MinY: TFloat; inline;
			function MaxX: TFloat; inline;
			function MaxY: TFloat; inline;
			function Width: TFloat; inline;
			function Height: TFloat; inline;

			{ Methods }
			function Rect: TRect;
			function Intersects (_rect: TRect): boolean; overload;
			function Intersects (_square: TAABB2): boolean; overload;
			procedure Offset (amount: TPoint);
			
			function Str: string;
			procedure Show;
	end;	
	
type
	TAABB3 = record
		public
			min: TPoint3D;
			max: TPoint3D;
		
		public
			{ Constructors }
			class function Make (_minX, _maxX: TFloat; _minY, _maxY: TFloat; _minZ, _maxZ: TFloat): TAABB3; overload; static; inline;
			class function Make (_min, _max: TPoint3D): TAABB3; overload; static; inline;
			class function Make (rect: TRect3D): TAABB3; overload; static; inline;

			{ Points }
			function MinX: TFloat; inline;
			function MinY: TFloat; inline;
			function MinZ: TFloat; inline;
		
			function MaxX: TFloat; inline;
			function MaxY: TFloat; inline;
			function MaxZ: TFloat; inline;

			function MidX: TFloat; inline;
			function MidY: TFloat; inline;
			function MidZ: TFloat; inline;

			function Width: TFloat; inline;
			function Height: TFloat; inline;
			function Depth: TFloat; inline;

			{ Methods }
			function Str: string;
			procedure Show;
			function Rect: TRect3D;
			function Intersects (aabb: TAABB3): boolean;
	end;	

type
	TBezierCurvePoints = record
		public
			p0, p1, p2, p3: TPoint;
			constructor Create (_p0, _p1, _p2, _p3: TPoint);
	end;

type
	TBezierCurve = record
		public
			points: array of TPoint;
			startPoint: TPoint;
			endPoint: TPoint;
		public
			constructor Make (p0, p1, p2, p3: TPoint; _steps: integer);
			class function PointAt (p0, p1, p2, p3: TPoint; step, totalSteps: integer): TPoint; static; overload;
			class function PointAt (pts: TBezierCurvePoints; step, totalSteps: integer): TPoint; static; overload;

			function Steps: integer;
			function Sum: TPoint;
			function Average: TPoint;
			function Count: integer;
			procedure Show;
	end;

type
	TCircle = record
		public
			origin: TPoint;
			radius: TFloat;
		public
			class function Make (_origin: TPoint; _radius: TFloat): TCircle; static; inline;
			class function Make (x, y: TFloat; _radius: TFloat): TCircle; static; inline;
			class function Make (rect: TRect): TCircle; static; inline;
			class function RadiusForBoundingRect (rect: TRect): TFloat; static; inline;

			procedure SetOrigin (newValue: TPoint); 
		
			function Intersects (const circle: TCircle): boolean; overload;
			function Intersects (const circle: TCircle; out hitPoint: TPoint): boolean; overload; 
			function Intersects (const rect: TRect): boolean; overload;
			function Distance (const circle: TCircle; fromDiameter: boolean = true): TFloat; inline;
			
			function Str: string;
			procedure Show;
	end;
	TCirclePtr = ^TCircle;
		
type
	TLine = record
		public
			a: TPoint;
			b: TPoint;
		public
			class function Make (_a, _b: TPoint): TLine; static; inline;
			class function Zero: TLine; static; inline;
			
			function Intersects (rect: TRect): boolean;
			
			class operator + (line: TLine; amount: TFloat): TLine;
			class operator - (line: TLine; amount: TFloat): TLine;
			class operator * (line: TLine; amount: TFloat): TLine;
			class operator / (line: TLine; amount: TFloat): TLine;
			class operator = (line1: TLine; line2: TLine): boolean; 
		
			function Str: string;
			procedure Show;
	end;
	TLinePtr = ^TLine;		

type
	TLine3D = record
		public
			a: TPoint3D;
			b: TPoint3D;
		public
			class function Make (_a, _b: TPoint3D): TLine3D; static; inline;
			function Intersects (rect: TRect3D): boolean;
		
			class operator + (line: TLine3D; amount: TFloat): TLine3D;
			class operator - (line: TLine3D; amount: TFloat): TLine3D;
			class operator * (line: TLine3D; amount: TFloat): TLine3D;
			class operator / (line: TLine3D; amount: TFloat): TLine3D;
			class operator = (line1: TLine3D; line2: TLine3D): boolean; 
		
			function	Line2D: TLine; inline;
			function Str: string;
			procedure Show;
	end;
	TLine3DPtr = ^TLine3D;		
	
{ Making }
function PointMake (s: TFloat): TPoint; overload; inline;
function PointMake (x, y: TFloat): TPoint; overload; inline;
function PointMake (x, y, z: TFloat): TPoint3D; overload; inline;
function PointMake (point: TPoint; z: TFloat): TPoint3D; overload; inline;
function SizeMake (width, height: TFloat): TSize; overload; inline;
function SizeMake (s: TFloat): TSize; overload; inline;
function SizeMake (w, h, d: TFloat): TSize3D; overload; inline;
function SizeMake (size: TSize; depth: TFloat): TSize3D; overload; inline;
function RectMake (x, y: TFloat; width, height: TFloat): TRect;
function RectMake (x, y, z: TFloat; width, height, depth: TFloat): TRect3D;
function RectMake (origin: TPoint; size: TSize): TRect;
function RectMake (origin: TPoint3D; size: TSize3D): TRect3D;
function RectMake (rect: TRect): TRect3D;

{ Comparing }
function RectEqualToRect (rect1, rect2: TRect): boolean;
function PointEqualToPoint (point1, point2: TPoint): boolean;
function PointEqualToPoint (point1, point2: TPoint3D): boolean;
function SizeEqualToSize (size1, size2: TSize): boolean;

{ Rects }
function RectIsEmpty (rect: TRect): boolean;
function RectInset (rect: TRect; x, y: TFloat): TRect;
function RectOffset (rect: TRect; x, y: TFloat): TRect;
function RectContainsPoint (rect: TRect; point: TPoint): boolean;
function RectContainsRect (rect1: TRect; rect2: TRect): boolean;
function RectIntersectsRect (rect1: TRect; rect2: TRect): boolean;
function RectCenter (rect: TRect; target: TRect): TRect;
function RectCenterX (rect: TRect; target: TRect): TRect;
function RectCenterY (rect: TRect; target: TRect): TRect;
function RectPolygon (rect: TRect): TPolygon;

function RectMinX (rect: TRect): TFloat; inline;
function RectMidX (rect: TRect): TFloat; inline;
function RectMaxX (rect: TRect): TFloat; inline;
function RectMinY (rect: TRect): TFloat; inline;
function RectMidY (rect: TRect): TFloat; inline;
function RectMaxY (rect: TRect): TFloat; inline;
function RectWidth (rect: TRect): TFloat; inline;
function RectHeight (rect: TRect): TFloat; inline;

{ Points }
function PointOffset (point: TPoint; x, y: TFloat): TPoint;
function PointIsZero (point: TPoint): boolean;

{ Integral }
function PointIntegral (point: TPoint): TPoint;
function RectIntegral (rect: TRect): TRect;
function SizeIntegral (size: TSize): TSize;

{ Text Representations }
function PointFromString (str: string): TPoint;
function RectFromString (str: string): TRect;
function SizeFromString (str: string): TSize;

function StringFromPoint (point: TPoint): string;
function StringFromRect (rect: TRect): string;
function StringFromSize (size: TSize): string;

{ Debugging }
procedure TShow (rect: TRect); overload;
procedure TShow (size: TSize); overload;
procedure TShow (point: TPoint); overload;
procedure TShow (point: TPoint3D); overload;

function TStr (rect: TRect): string; overload;
function TStr (size: TSize): string; overload;	
function TStr (point: TPoint): string; overload;
function TStr (point: TPoint3D): string; overload;

function RectString (rect: TRect): string;
function SizeString (size: TSize): string;	
function PointString (point: TPoint): string; overload; 
function PointString (point: TPoint3D): string; overload;

function RectZero: TRect;
function PointZero: TPoint;
function Point3DZero: TPoint3D;
function PointInvalid: TPoint;
function Point3DInvalid: TPoint3D;
function PointMax: TPoint;
function PointMin: TPoint;

function PointOnSide (p, a, b: TPoint): integer; inline;
function LineIntersectsRect (p1, p2: TPoint; rect: TRect): boolean;
function PolyEdge (poly: TPolygon; edge: integer): TLine; 

type
	TPointHelper = record helper for TPoint
		function Rect: TRect;
		function XYZ (z: TFloat = 0): TPoint3D;
	end;
	
// TODO: UMath
function Highest (v1, v2: TFloat): TFloat; overload; 
function Highest (v1, v2: LongInt): LongInt; overload;

function Lowest (v1, v2: TFloat): TFloat; overload;
function Lowest (v1, v2: LongInt): LongInt; overload;

function Within (v, l, h: double): boolean; overload;
function Within (v, l, h: integer): boolean; overload;

function Round2(const Number: TFloat; const Places: longint): TFloat;

implementation

function PolyEdge (poly: TPolygon; edge: integer): TLine; 
begin
	if edge < poly.high then
		result := TLine.Make(poly[edge], poly[edge + 1])
	else
		result := TLine.Make(poly[edge], poly[0]);
end;

{=============================================}
{@! ___MATH___ } 
{=============================================}
function Round2(const Number: TFloat; const Places: longint): TFloat;
var
	t: TFloat;
begin
	if places = 0 then
		exit(number);
	t := power(10, places);
	round2 := round(Number*t)/t;
end;

function Within (v, l, h: double): boolean;
begin
	result := (v >= l) and (v <= h);
end;

function Within (v, l, h: integer): boolean;
begin
	result := (v >= l) and (v <= h);
end;

function Highest (v1, v2: TFloat): TFloat; 
begin
	if v1 > v2 then
		result := v1
	else
		result := v2;
end;

function Lowest (v1, v2: TFloat): TFloat; 
begin
	if v1 < v2 then
		result := v1
	else
		result := v2;
end;

function Highest (v1, v2: LongInt): LongInt; 
begin
	if v1 > v2 then
		result := v1
	else
		result := v2;
end;

function Lowest (v1, v2: LongInt): LongInt; 
begin
	if v1 < v2 then
		result := v1
	else
		result := v2;
end;

{=============================================}
{@! ___LINE___ } 
{=============================================}

//https://stackoverflow.com/questions/1560492/how-to-tell-whether-a-point-is-to-the-right-or-left-side-of-a-line
//It is 0 on the line, and +1 on one side, -1 on the other side.
function PointOnSide (p, a, b: TPoint): integer;
begin
	result := Sign(((b.x - a.x) * (p.y - a.y)) - ((b.y - a.y) * (p.x - a.x)));
end;

// http://stackoverflow.com/questions/99353/how-to-test-if-a-line-segment-intersects-an-axis-aligned-rectange-in-2d
function LineIntersectsRect (p1, p2: TPoint; rect: TRect): boolean;
var
	minX, maxY, minY, maxX: TFloat;
	dx: TFloat;
	tmp: TFloat;
	a, b: TFloat;
begin
	// Find min and max X for the segment
	minX := p1.x;
	maxX := p2.x;
	if (p1.x > p2.x) then
		begin
			minX := p2.x;
	    maxX := p1.x;
		end;	

	// Find the intersection of the segment's and rectangle's x-projections
  if (maxX > rect.GetMaxX) then
    maxX := rect.GetMaxX;

  if (minX < rect.GetMinX) then
    minX := rect.GetMinX;

  if (minX > maxX) then // If their projections do not intersect return false
  	exit(false);

  // Find corresponding min and max Y for min and max X we found before
  minY := p1.y;
  maxY := p2.y;
	dx := p2.x - p1.x;
	
	if Abs(dx) > 0.0000001 then
		begin
			a := (p2.y - p1.y) / dx;
	    b := p1.y - a * p1.x;
	    minY := a * minX + b;
	    maxY := a * maxX + b;
		end;

  if (minY > maxY) then
		begin
			tmp := maxY;
	    maxY := minY;
	    minY := tmp;
		end;

	// Find the intersection of the segment's and rectangle's y-projections
  if (maxY > rect.GetMaxY) then
    maxY := rect.GetMaxY;

  if (minY < rect.GetMinY) then
    minY := rect.GetMinY;

  if (minY > maxY) then // If Y-projections do not intersect return false
  	exit(false);

  result := true;
end;

//https://stackoverflow.com/questions/1073336/circle-line-segment-collision-detection-algorithm
function LineIntersectsCircle (line: TLine; circle: TCircle): boolean; 
var
	d, f: TPoint;
	a, b, c: TFloat;
	discriminant: TFloat;
	t1, t2: TFloat;
begin
	d := line.b - line.a; // Direction vector of ray, from start to end
	f := line.a - circle.origin; // Vector from center sphere to ray start
	a := d.Dot( d );
	b := 2*f.Dot( d ) ;
	c := f.Dot( f ) - circle.radius*circle.radius;
	discriminant := b*b-4*a*c;
	if( discriminant < 0 ) then
		exit(false) // no intersection
	else
		begin
			// ray didn't totally miss sphere,
		  // so there is a solution to
		  // the equation.
		  discriminant := Sqrt(discriminant);

		  // either solution may be on or off the ray so need to test both
		  // t1 is always the smaller value, because BOTH discriminant and
		  // a are nonnegative.
		  t1 := (-b - discriminant)/(2*a);
		  t2 := (-b + discriminant)/(2*a);

		  // 3x HIT cases:
		  //          -o->             --|-->  |            |  --|->
		  // Impale(t1 hit,t2 hit), Poke(t1 hit,t2>1), ExitWound(t1<0, t2 hit), 

		  // 3x MISS cases:
		  //       ->  o                     o ->              | -> |
		  // FallShort (t1>1,t2>1), Past (t1<0,t2<0), CompletelyInside(t1<0, t2>1)

		  if (t1 >= 0) and (t1 <= 1) then
				begin
					// t1 is the intersection, and it's closer than t2
			    // (since t1 uses -b - discriminant)
			    // Impale, Poke
			    exit(true);
				end;

		  // here t1 didn't intersect so we are either started
		  // inside the sphere or completely past it
		  if (t2 >= 0) and (t2 <= 1) then
				begin
					// ExitWound
			    exit(true);
				end;

		  // no intn: FallShort, Past, CompletelyInside
		  exit(false)
		end;
	
end;

procedure TLine.Show;
begin
	writeln(Str);
end;

function TLine.Str: string;
begin
	result := a.Str+', '+b.Str;
end;

class operator TLine.= (line1: TLine; line2: TLine): boolean; 
begin
	result := (line1.a = line2.a) and (line1.b = line2.b);
end;

class operator TLine.+ (line: TLine; amount: TFloat): TLine;
begin
	result := TLine.Make(line.a + amount, line.b + amount);
end;

class operator TLine.- (line: TLine; amount: TFloat): TLine;
begin
	result := TLine.Make(line.a - amount, line.b - amount);
end;

class operator TLine.* (line: TLine; amount: TFloat): TLine;
begin
	result := TLine.Make(line.a * amount, line.b * amount);
end;

class operator TLine./ (line: TLine; amount: TFloat): TLine;
begin
	result := TLine.Make(line.a / amount, line.b / amount);
end;

function TLine.Intersects (rect: TRect): boolean;
begin
	result := LineIntersectsRect(a, b, rect);
end;

class function TLine.Make (_a, _b: TPoint): TLine;
begin
	result.a := _a;
	result.b := _b;
end;	

class function TLine.Zero: TLine;
begin
	result.a := TPoint.Zero;
	result.b := TPoint.Zero;
end;

{=============================================}
{@! ___LINE3D___ } 
{=============================================}

// http://www.3dkingdoms.com/weekly/weekly.php?a=3
function GetIntersection (fDst1, fDst2: TFloat; P1, P2: TPoint3D; out hit: TPoint3D): boolean; inline;
begin
	if ( (fDst1 * fDst2) >= 0.0) then exit(false);
	if ( fDst1 = fDst2) then exit(false); 
	Hit := P1 + (P2-P1) * ( -fDst1/(fDst2-fDst1) );
	result := true;
end;

function InBox (Hit, B1, B2: TPoint3D; const axis: integer): boolean; inline;
begin
	if ( (Axis=1) and (Hit.z > B1.z) and (Hit.z < B2.z) and (Hit.y > B1.y) and (Hit.y < B2.y)) then exit(true);
	if ( (Axis=2) and (Hit.z > B1.z) and (Hit.z < B2.z) and (Hit.x > B1.x) and (Hit.x < B2.x)) then exit(true);
	if ( (Axis=3) and (Hit.x > B1.x) and (Hit.x < B2.x) and (Hit.y > B1.y) and (Hit.y < B2.y)) then exit(true);
	result := false;
end;

// returns true if line (L1, L2) intersects with the box (B1, B2)
// returns intersection point in Hit
function CheckLineBox (B1, B2, L1, L2: TPoint3D; out hit: TPoint3D): boolean;
begin
	if ((L2.x < B1.x) and (L1.x < B1.x)) then exit(false);
	if ((L2.x > B2.x) and (L1.x > B2.x)) then exit(false);
	if ((L2.y < B1.y) and (L1.y < B1.y)) then exit(false);
	if ((L2.y > B2.y) and (L1.y > B2.y)) then exit(false);
	if ((L2.z < B1.z) and (L1.z < B1.z)) then exit(false);
	if ((L2.z > B2.z) and (L1.z > B2.z)) then exit(false);
	if ((L1.x > B1.x) and (L1.x < B2.x) and
	    (L1.y > B1.y) and (L1.y < B2.y) and
	    (L1.z > B1.z) and (L1.z < B2.z)) then
			begin
				Hit := L1; 
		    exit(true);
			end;
	if ( (GetIntersection( L1.x-B1.x, L2.x-B1.x, L1, L2, Hit) and InBox( Hit, B1, B2, 1 ))
	  or (GetIntersection( L1.y-B1.y, L2.y-B1.y, L1, L2, Hit) and InBox( Hit, B1, B2, 2 )) 
	  or (GetIntersection( L1.z-B1.z, L2.z-B1.z, L1, L2, Hit) and InBox( Hit, B1, B2, 3 )) 
	  or (GetIntersection( L1.x-B2.x, L2.x-B2.x, L1, L2, Hit) and InBox( Hit, B1, B2, 1 )) 
	  or (GetIntersection( L1.y-B2.y, L2.y-B2.y, L1, L2, Hit) and InBox( Hit, B1, B2, 2 )) 
	  or (GetIntersection( L1.z-B2.z, L2.z-B2.z, L1, L2, Hit) and InBox( Hit, B1, B2, 3 ))) then
		exit(true);

	result := false;
end;

function TLine3D.Intersects (rect: TRect3D): boolean;
var
	hit: TPoint3D;
begin
	//exit(LineIntersectsRect(a.XY, b.XY, rect.Rect2D));
	result := CheckLineBox(rect.min, rect.max, self.a, self.b, hit);
end;

procedure TLine3D.Show;
begin
	writeln(Str);
end;

function TLine3D.Line2D: TLine;
begin
	result := TLine.Make(a.XY, b.XY);
end;

function TLine3D.Str: string;
begin
	result := a.Str+', '+b.Str;
end;

class operator TLine3D.= (line1: TLine3D; line2: TLine3D): boolean; 
begin
	result := (line1.a = line2.a) and (line1.b = line2.b);
end;

class operator TLine3D.+ (line: TLine3D; amount: TFloat): TLine3D;
begin
	result := TLine3D.Make(line.a + amount, line.b + amount);
end;

class operator TLine3D.- (line: TLine3D; amount: TFloat): TLine3D;
begin
	result := TLine3D.Make(line.a - amount, line.b - amount);
end;

class operator TLine3D.* (line: TLine3D; amount: TFloat): TLine3D;
begin
	result := TLine3D.Make(line.a * amount, line.b * amount);
end;

class operator TLine3D./ (line: TLine3D; amount: TFloat): TLine3D;
begin
	result := TLine3D.Make(line.a / amount, line.b / amount);
end;

{function TLine3D.Intersects (rect: TRect3D): boolean;
begin
	if ((a.z > rect.MaxZ) or (a.z < rect.MinZ)) and ((b.z > rect.MaxZ) or (b.z < rect.MinZ)) then
		exit(false);
	result := LineIntersectsRect(a.XY, b.XY, rect.Rect2D);
end;}
	
class function TLine3D.Make (_a, _b: TPoint3D): TLine3D;
begin
	result.a := _a;
	result.b := _b;
end;	

{=============================================}
{@! ___CIRCLE___ } 
{=============================================}
class function TCircle.Make (_origin: TPoint; _radius: TFloat): TCircle;
begin
	result.origin := _origin;
	result.radius := _radius;
end;

class function TCircle.Make (x, y: TFloat; _radius: TFloat): TCircle;
begin
	result.origin.x := x;
	result.origin.y := y;
	result.radius := _radius;
end;

class function TCircle.Make (rect: TRect): TCircle;
begin
	result.origin := rect.GetCenter;
	result.radius := rect.Min.Distance(rect.Max) / 2;
end;


class function TCircle.RadiusForBoundingRect (rect: TRect): TFloat;
begin
	result := rect.Min.Distance(rect.Max) / 2;
end;

procedure TCircle.SetOrigin (newValue: TPoint); 
begin
	origin := newValue;
end;


// http://stackoverflow.com/questions/21089959/detecting-collision-of-rectangle-with-circle
function TCircle.Intersects (const rect: TRect): boolean; 
var
	distX, distY: TFloat;
	dx, dy: TFloat;
begin
	distX := Abs(origin.x - rect.origin.x - rect.size.width / 2);
	distY := Abs(origin.y - rect.origin.y - rect.size.height / 2);
	
	if (distX > (rect.size.width / 2 + radius)) then
		exit(false);
	
	if (distY > (rect.size.height / 2 + radius)) then
		exit(false);
		
	if (distX <= (rect.size.width / 2)) then
		exit(true);
	
	if (distY <= (rect.size.height / 2)) then
		exit(true);	
	
	dx := distX - rect.size.width / 2;
	dy := distY - rect.size.height / 2;
	result := (dx * dx + dy * dy <= (radius * radius));
end;

function TCircle.Intersects (const circle: TCircle): boolean; 
var
	dx, dy: TFloat;
	radii: TFloat;
begin	
	dx := circle.origin.x - origin.x;
  dy := circle.origin.y - origin.y;
  radii := radius + circle.radius;
	result := (dx * dx) + (dy * dy) <= (radii * radii);
end;

function TCircle.Intersects (const circle: TCircle; out hitPoint: TPoint): boolean; 
begin	
	result := Intersects(circle);
		
	//https://gamedevelopment.tutsplus.com/tutorials/when-worlds-collide-simulating-circle-circle-collisions--gamedev-769
	if result then
		begin
			if self.radius = circle.radius then
				begin
					hitPoint.x := (self.origin.x + circle.origin.x) / 2;
					hitPoint.y := (self.origin.y + circle.origin.y) / 2;
				end
			else
				begin
					hitPoint.x := ((self.origin.x * circle.radius) + (circle.origin.x * self.radius)) / (self.radius + circle.radius);
					hitPoint.y := ((self.origin.y * circle.radius) + (circle.origin.y * self.radius)) / (self.radius + circle.radius);
				end;
		end;
end;

// distance from diameter
function TCircle.Distance (const circle: TCircle; fromDiameter: boolean = true): TFloat; 
begin	
	if fromDiameter then
		result := origin.Distance(circle.origin) - (radius + circle.radius)
	else
		result := origin.Distance(circle.origin);
end;

function TCircle.Str: string;
begin
	result := origin.str+', r='+radius.Str;
end;

procedure TCircle.Show; 
begin
	writeln(Str);
end;

{=============================================}
{@! ___SQUARE___ } 
{=============================================}
function TAABB2.Str: string;
begin
	result := min.str+', '+max.str;
end;

procedure TAABB2.Show; 
begin
	writeln(Str);
end;

function TAABB2.Rect: TRect;
begin
	result := RectMake(min.x, min.y, max.x - min.x, max.y - min.y);
end;

procedure TAABB2.Offset (amount: TPoint);
begin
	min += amount;
	max += amount;
end;

function TAABB2.Intersects (_rect: TRect): boolean;
begin
	result := (self.min.X < _rect.GetMaxX) and 
						(self.max.X > _rect.GetMinX) and 
						(self.min.Y < _rect.GetMaxY) and 
						(self.max.Y > _rect.GetMinY);
end;

function TAABB2.Intersects (_square: TAABB2): boolean;
begin
	result := (self.min.X < _square.max.X) and 
						(self.max.X > _square.min.X) and 
						(self.min.Y < _square.max.Y) and 
						(self.max.Y > _square.min.Y);
end;

function TAABB2.Width: TFloat;
begin
	result := max.x - min.x;
end;

function TAABB2.Height: TFloat;
begin
	result := max.y - min.y;
end;

function TAABB2.MinX: TFloat;
begin
	result := min.x
end;

function TAABB2.MinY: TFloat;
begin
	result := min.y;
end;

function TAABB2.MaxX: TFloat;
begin
	result := max.x;
end;

function TAABB2.MaxY: TFloat;
begin
	result := max.y;
end;

constructor TAABB2.Make (rect: TRect);
begin
	min := rect.origin;
	max := PointMake(rect.GetMaxX, rect.GetMaxY);
end;

constructor TAABB2.Make (_minX, _maxX: TFloat; _minY, _maxY: TFloat);
begin
	min := PointMake(_minX, _minY);
	max := PointMake(_maxX, _maxY);
end;

constructor TAABB2.Make (_min, _max: TPoint);
begin
	min := _min;
	max := _max;
end;

{=============================================}
{@! ___CUBE___ } 
{=============================================}
function TAABB3.Str: string;
begin
	result := min.str+', '+max.str;
end;

procedure TAABB3.Show; 
begin
	writeln(Str);
end;

function TAABB3.Rect: TRect3D;
begin
	result := RectMake(min.x, min.y, min.z, max.x - min.x, max.y - min.y, max.z - min.z);
end;

function TAABB3.Intersects (aabb: TAABB3): boolean;
begin
	result := (self.min.X < aabb.max.X) and 
						(self.max.X > aabb.min.X) and 
						(self.min.Y < aabb.max.Y) and 
						(self.max.Y > aabb.min.Y) and
						(self.min.Z < aabb.max.Z) and 
						(self.max.Z > aabb.min.Z);
end;

function TAABB3.Width: TFloat;
begin
	result := max.x - min.x;
end;

function TAABB3.Height: TFloat;
begin
	result := max.y - min.y;
end;

function TAABB3.Depth: TFloat;
begin
	result := max.z - min.z;
end;

function TAABB3.MidX: TFloat;
begin
	result := min.x + ((max.x - min.x) / 2);
end;

function TAABB3.MidY: TFloat;
begin
	result := min.y + ((max.y - min.y) / 2);
end;

function TAABB3.MidZ: TFloat;
begin
	result := min.z + ((max.z - min.z) / 2);
end;

function TAABB3.MinX: TFloat;
begin
	result := min.x
end;

function TAABB3.MinY: TFloat;
begin
	result := min.y;
end;

function TAABB3.MinZ: TFloat;
begin
	result := min.z;
end;

function TAABB3.MaxX: TFloat;
begin
	result := max.x;
end;

function TAABB3.MaxY: TFloat;
begin
	result := max.y;
end;

function TAABB3.MaxZ: TFloat;
begin
	result := max.z;
end;

class function TAABB3.Make (rect: TRect3D): TAABB3;
begin
	result.min := rect.Min;
	result.max := rect.Max;
end;

class function TAABB3.Make (_minX, _maxX: TFloat; _minY, _maxY: TFloat; _minZ, _maxZ: TFloat): TAABB3;
begin
	result.min := PointMake(_minX, _minY, _minZ);
	result.max := PointMake(_maxX, _maxY, _maxZ);
end;

class function TAABB3.Make (_min, _max: TPoint3D): TAABB3;
begin
	result.min := _min;
	result.max := _max;
end;

{=============================================}
{@! ___BEZIER CURVE___ } 
{=============================================}
function TBezierCurve.Sum: TPoint;
var
	i: integer;
begin
	result := PointMake(0, 0);
	for i := 0 to high(points) do
		begin
			result.x += points[i].x;
			result.y += points[i].y;
		end;
end;

function TBezierCurve.Count: integer;
begin
	result := length(points);
end;

function TBezierCurve.Average: TPoint;
begin
	result := Sum.Divide(length(points));
end;

function TBezierCurve.Steps: integer;
begin
	result := length(points);
end;

procedure TBezierCurve.Show;
var
	i: integer;
begin
	for i := 0 to high(points) do
		points[i].Show;
end;

// http://robnapier.net/blog/fast-bezier-intro-701
// http://robnapier.net/faster-bezier
class function TBezierCurve.PointAt (pts: TBezierCurvePoints; step, totalSteps: integer): TPoint;
begin
	result := PointAt(pts.p0, pts.p1, pts.p2, pts.p3, step, totalSteps);
end;

class function TBezierCurve.PointAt (p0, p1, p2, p3: TPoint; step, totalSteps: integer): TPoint;
var
	t: TFloat;
	gC0, gC1, gC2, gC3: TFloat;
begin
	t := step/totalSteps;
	gC0 := (1-t)*(1-t)*(1-t); // * P0
  gC1 := 3 * (1-t)*(1-t) * t; // * P1
  gC2 := 3 * (1-t) * t*t; // * P2
  gC3 := t*t*t; // * P3;
	result.x := gC0*P0.x + gC1*P1.x + gC2*P2.x + gC3*P3.x;
	result.y := gC0*P0.y + gC1*P1.y + gC2*P2.y + gC3*P3.y;
end;

constructor TBezierCurve.Make (p0, p1, p2, p3: TPoint; _steps: integer);
var
	t: TFloat;
	step: integer;
	point: TPoint;
	gC0, gC1, gC2, gC3: array of TFloat;
begin
	startPoint := p0;
	endPoint:= p3;
	
	SetLength(points, _steps);
	SetLength(gC0, _steps);
	SetLength(gC1, _steps);
	SetLength(gC2, _steps);
	SetLength(gC3, _steps);
	
	for step := 0 to _steps - 1 do
		begin
			t := step/_steps;
			gC0[step] := (1-t)*(1-t)*(1-t); // * P0
      gC1[step] := 3 * (1-t)*(1-t) * t; // * P1
      gC2[step] := 3 * (1-t) * t*t; // * P2
      gC3[step] := t*t*t; // * P3;
		end;
	
	for step := 0 to _steps - 1 do
		begin
			point.x := gC0[step]*P0.x + gC1[step]*P1.x + gC2[step]*P2.x + gC3[step]*P3.x;
			point.y := gC0[step]*P0.y + gC1[step]*P1.y + gC2[step]*P2.y + gC3[step]*P3.y;
			points[step] := point;
		end;
end;
		
constructor TBezierCurvePoints.Create (_p0, _p1, _p2, _p3: TPoint);
begin
	p0 := _p0;
	p1 := _p1;
	p2 := _p2;
	p3 := _p3;
end;

{=============================================}
{@! ___POINT HELPER___ } 
{=============================================}		
function TPointHelper.Rect: TRect;
begin
	result := RectMake(x, y, 1, 1);
end;

function TPointHelper.XYZ (z: TFloat = 0): TPoint3D;
begin
	result := PointMake(self, z);
end;
		
{=============================================}
{@! ___POLYGON___ } 
{=============================================}

constructor TPolygon.Make (_verticies: integer);
begin
	SetVerticies(_verticies);
end;

procedure TPolygon.SetVerticies (_verticies: integer);
begin
	SetLength(v, _verticies);
end;

procedure TPolygon.AddVertex (x, y: TFloat);
begin
	AddVertex(PointMake(x, y))
end;

procedure TPolygon.AddVertex (point: TPoint);
begin
	SetLength(v, length(v) + 1);
	v[High] := point;
	//writeln('added ', high(verticies), ' at ', point.str);
end;

procedure TPolygon.SetVertex (index: integer; point: TPoint);
begin
	v[index] := point;
end;

function TPolygon.Str: AnsiString;
var
	i: integer;
begin
	result := '(';
	for i := 0 to High do
		begin
			result := result+v[i].Str;
			if i < High then
				result := result+', ';
		end;
	result := result+')';
end;

procedure TPolygon.Show;
begin
	writeln(Str);
end;

function TPolygon.Count: integer;
begin
	result := length(v);
end;

function TPolygon.High: integer;
begin
	result := Count - 1;
end;

function TPolygon.GetVertex (index: integer): TPoint;
begin
	result := v[index];
end;

procedure TPolygon.Offset (amount: TPoint);
begin
	Offset(amount.x, amount.y);
end;

procedure TPolygon.Offset (x, y: TFloat);
var
	i: integer;
begin
	for i := 0 to High do
		v[i] := v[i].Offset(PointMake(x, y));
end;

// http://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon
// https://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
function TPolygon.ContainsPoint (point: TPoint): boolean;
var
	i, j, c: integer;
begin
	i := 0;
	j := High;
	c := 0;
	while i < length(v) do
		begin
			if ((v[i].y > point.y) <> (v[j].y > point.y)) 
					and (point.x < (v[j].x - v[i].x) * (point.y - v[i].y) / (v[j].y - v[i].y) + v[i].x) then
				c := not c;
			j := i;
			i += 1;
		end;
	result := c <> 0;
end;

{=============================================}
{@! ___POINT___ } 
{=============================================}
procedure TPoint.Show;
begin
	TShow(self);
end;

function TPoint.Str (places: integer = 0): string;
begin
	result := '{'+self.x.Str(places)+', '+self.y.Str(places)+'}';
end;

class function TPoint.Make (_x, _y: TFloat): TPoint;
begin
	result.x := _x;
	result.y := _y;
end;

class function TPoint.FromAngleInDegrees (degrees: TFloat): TPoint;
begin
	SinCos(DegToRad(degrees), result.y, result.x);
end;

class function TPoint.FromAngleInRadians (radians: TFloat): TPoint;
begin
	SinCos(radians, result.y, result.x);
end;

class function TPoint.Invalid: TPoint;
begin
	result := Make(-MaxInt, -MaxInt);
end;

class function TPoint.Zero: TPoint;
begin
	result := Make(0, 0);
end;

class function TPoint.Up (_x: TFloat = 0; _y: TFloat = -1): TPoint;
begin
	result := Make(_x, _y);
end;

class function TPoint.Down (_x: TFloat = 0; _y: TFloat = 1): TPoint;
begin
	result := Make(_x, _y);
end;

class function TPoint.Left (_x: TFloat = -1; _y: TFloat = 0): TPoint;
begin
	result := Make(_x, _y);
end;

class function TPoint.Right (_x: TFloat = 1; _y: TFloat = 0): TPoint;
begin
	result := Make(_x, _y);
end;

class function TPoint.UpLeft (_x: TFloat = -1; _y: TFloat = -1): TPoint;
begin
	result := Make(_x, _y);
end;

class function TPoint.UpRight (_x: TFloat = 1; _y: TFloat = -1): TPoint;
begin
	result := Make(_x, _y);
end;

class function TPoint.DownLeft (_x: TFloat = -1; _y: TFloat = 1): TPoint;
begin
	result := Make(_x, _y);
end;

class function TPoint.DownRight (_x: TFloat = 1; _y: TFloat = 1): TPoint;
begin
	result := Make(_x, _y);
end;

function TPoint.IsZero: boolean;
begin
	result := (self.x = 0) and (self.y = 0);
end;

function TPoint.IsValid: boolean;
begin
	result := (x <> -MaxInt) and (y <> -MaxInt);
end;

function TPoint.IsEqual (point: TPoint): boolean;
begin
	result := (self.x = point.x) and (self.y = point.y);
end;

function TPoint.Ceil: TPoint;
begin
	result := PointMake(Math.Ceil(x), Math.Ceil(y));
end;

function TPoint.Round: TPoint;
begin
	result := PointMake(System.Round(x), System.Round(y));
end;

function TPoint.Integral: TPoint;
begin
	result := PointIntegral(self);
end;

function TPoint.Trunc: TPoint;
begin
	result := PointMake(System.Trunc(x), System.Trunc(y));
end;

function TPoint.Divide (amount: TFloat): TPoint;
begin
	result := PointMake(x / amount, y / amount);
end;

function TPoint.Multiply (amount: TFloat): TPoint;
begin
	result := PointMake(x * amount, y * amount);
end;

function TPoint.Add (amount: TFloat): TPoint;
begin
	result := PointMake(x + amount, y + amount);
end;

function TPoint.Subtract (amount: TFloat): TPoint;
begin
	result := PointMake(x - amount, y - amount);
end;

function TPoint.Divide (amount: TPoint): TPoint;
begin
	result := PointMake(x / amount.x, y / amount.y);
end;

function TPoint.Multiply (amount: TPoint): TPoint;
begin
	result := PointMake(x * amount.x, y * amount.y);
end;

function TPoint.Add (amount: TPoint): TPoint;
begin
	result := PointMake(x + amount.x, y + amount.y);
end;

function TPoint.Subtract (amount: TPoint): TPoint;
begin
	result := PointMake(x - amount.x, y - amount.y);
end;

function TPoint.Min: TFloat;
begin
	if x < y then
		result := x
	else
		result := y;
end;

function TPoint.Max: TFloat;
begin
	if x > y then
		result := x
	else
		result := y;
end;

function TPoint.Sum: TFloat;
begin
	result := x + y;
end;

function TPoint.Compare (_x, _y: TFloat): boolean;
begin
	result := (x = _x) and (y = _y);
end;

function TPoint.IsIntegral: boolean;
begin
	result := x.IsIntegral and y.IsIntegral;
end;

procedure TPoint.SetPoint (_x, _y: TFloat);
begin
	x := _x;
	y := _y;
end;

function TPoint.Clamp (lowest, highest: TPoint): TPoint;
begin
	result := self;
	if result.x < lowest.x then
		result.x := lowest.x;
	if result.y < lowest.y then
		result.y := lowest.y;
	if result.x > highest.x then
		result.x := highest.x;
	if result.y > highest.y then
		result.y := highest.y;
end;

function TPoint.Clamp (lowest, highest: TFloat): TPoint;
begin
	result := self;
	if result.x < lowest then
		result.x := lowest;
	if result.y < lowest then
		result.y := lowest;
	if result.x > highest then
		result.x := highest;
	if result.y > highest then
		result.y := highest;
end;

function TPoint.Abs: TPoint;
begin
	result := PointMake(System.Abs(x), System.Abs(y));
end;

function TPoint.Floor: TPoint;
begin
	result := PointMake(Math.Floor(x), Math.Floor(y));
end;

function TPoint.Offset (byX, byY: TFloat): TPoint;
begin
	result := PointOffset(self, byX, byY);
end;

function TPoint.Offset (point: TPoint): TPoint;
begin
	result := PointOffset(self, point.x, point.y);
end;

// http://blog.wolfire.com/2009/07/linear-algebra-for-game-developers-part-2/

function TPoint.Magnitude: TFloat;
begin
	result := Sqrt(Power(x, 2) + Power(y, 2));
end;

function TPoint.Normalize: TPoint;
begin
	result := self / Magnitude;
end;

function TPoint.Negate: TPoint;
begin
	result := PointMake(-x, -y);
end;

function TPoint.PerpendicularRight: TPoint;
begin
	result := PointMake(-y, x);
end;

function TPoint.PerpendicularLeft: TPoint;
begin
	result := PointMake(y, -x);
end;

function TPoint.Angle: TFloat;
begin
	result := Arctan2(y, x);
end;

function TPoint.Dot (point: TPoint): TFloat;
begin
	// (a1,a2)•(b1,b2) = a1b1 + a2b2
	//(3,2)•(1,4) = 3*1 + 2*4 
	result := (x * point.x) + (y * point.y);
end;

function TPoint.Distance (point: TPoint): TFloat;
begin
	//Distance = |P-E| = |(3,3)-(1,2)| = |(2,1)| = sqrt(22+12) = sqrt(5) = 2.23
	result := Subtract(point).Magnitude;
end;

class operator TPoint.+ (p1: TPoint; p2: TPointPtr): TPoint;
begin
	result := PointMake(p1.x+p2^.x, p1.y+p2^.y);
end;

class operator TPoint.- (p1: TPoint; p2: TPointPtr): TPoint;
begin
	result := PointMake(p1.x-p2^.x, p1.y-p2^.y);
end;

class operator TPoint.+ (p1, p2: TPoint): TPoint;
begin
	result := PointMake(p1.x+p2.x, p1.y+p2.y);
end;

class operator TPoint.- (p1, p2: TPoint): TPoint;
begin
	result := PointMake(p1.x-p2.x, p1.y-p2.y);
end;

class operator TPoint.* (p1, p2: TPoint): TPoint; 
begin
	result := PointMake(p1.x*p2.x, p1.y*p2.y);
end;

class operator TPoint./ (p1, p2: TPoint): TPoint; 
begin
	result := PointMake(p1.x/p2.x, p1.y/p2.y);
end;

class operator TPoint.= (p1, p2: TPoint): boolean; 
begin
	result := (p1.x = p2.x) and (p1.y = p2.y);
end;

class operator TPoint.+ (p1: TPoint; p2: TFloat): TPoint;
begin
	result := PointMake(p1.x+p2, p1.y+p2);
end;

class operator TPoint.- (p1: TPoint; p2: TFloat): TPoint;
begin
	result := PointMake(p1.x-p2, p1.y-p2);
end;

class operator TPoint.* (p1: TPoint; p2: TFloat): TPoint;
begin
	result := PointMake(p1.x*p2, p1.y*p2);
end;

class operator TPoint./ (p1: TPoint; p2: TFloat): TPoint;
begin
	result := PointMake(p1.x/p2, p1.y/p2);
end;

// http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html
function TPoint.DiagonalDistance (toPoint: TPoint): integer;
var
	dx, dy, d1, d2: integer;
begin
	d1 := 1;
	d2 := 1;
	dx := System.abs(System.Trunc(self.x - toPoint.x));
  dy := System.abs(System.Trunc(self.y - toPoint.y));
  result := d1 * (dx + dy) + (d2 - 2 * d1) * Math.Min(dx, dy);
end;

function TPoint.EuclideanDistance (toPoint: TPoint): TFloat;
var
	dx, dy: TFloat;
	d: integer = 1;
begin
	dx := System.abs(self.x - toPoint.x);
  dy := System.abs(self.y - toPoint.y);
  result := D * sqrt(dx * dx + dy * dy);
end;

function TPoint.ManhattanDistance (toPoint: TPoint): integer;
begin
	result := (System.abs(System.Trunc(toPoint.x - self.x)) + System.abs(System.Trunc(toPoint.y - self.y)));
end;

// http://www-cs-students.stanford.edu/~amitp/game-programming/grids/

function TPoint.ManhattanDirection (tileCoord: TPoint): TPoint;
begin
	result := PointMake(0, 0);
	if x > tileCoord.x then
		result.x := 1
	else if x < tileCoord.x then
		result.x := -1;
	
	if y > tileCoord.y then
		result.y := 1
	else if y < tileCoord.y then
		result.y := -1;
end;

{=============================================}
{@! ___POINT 3D___ } 
{=============================================}
class operator TPoint3D.+ (p1: TPoint3D; p2: TPoint): TPoint3D;
begin
	result := p1 + PointMake(p2, 0);
end;

class operator TPoint3D.- (p1: TPoint3D; p2: TPoint): TPoint3D;
begin
	result := p1 - PointMake(p2, 0);
end;

class operator TPoint3D.* (p1: TPoint3D; p2: TPoint): TPoint3D;
begin
	result := p1 * PointMake(p2, 0);
end;

class operator TPoint3D./ (p1: TPoint3D; p2: TPoint): TPoint3D;
begin
	result := p1 / PointMake(p2, 0);
end;

class operator TPoint3D.+ (p1: TPoint3D; p2: TPointPtr): TPoint3D;
begin
	result := PointMake(p1.x+p2^.x, p1.y+p2^.y, p1.z);
end;

class operator TPoint3D.- (p1: TPoint3D; p2: TPointPtr): TPoint3D;
begin
	result := PointMake(p1.x-p2^.x, p1.y-p2^.y, p1.z);
end;

class operator TPoint3D.+ (p1, p2: TPoint3D): TPoint3D;
begin
	result := PointMake(p1.x+p2.x, p1.y+p2.y, p1.z+p2.z);
end;

class operator TPoint3D.- (p1, p2: TPoint3D): TPoint3D;
begin
	result := PointMake(p1.x-p2.x, p1.y-p2.y, p1.z-p2.z);
end;

class operator TPoint3D.* (p1, p2: TPoint3D): TPoint3D; 
begin
	result := PointMake(p1.x*p2.x, p1.y*p2.y, p1.z*p2.z);
end;

class operator TPoint3D./ (p1, p2: TPoint3D): TPoint3D; 
begin
	result := PointMake(p1.x/p2.x, p1.y/p2.y, p1.z/p2.z);
end;

class operator TPoint3D.= (p1, p2: TPoint3D): boolean; 
begin
	result := (p1.x = p2.x) and (p1.y = p2.y) and (p1.z = p2.z);
end;

class operator TPoint3D.+ (p1: TPoint3D; p2: TFloat): TPoint3D;
begin
	result := PointMake(p1.x+p2, p1.y+p2, p1.z+p2);
end;

class operator TPoint3D.- (p1: TPoint3D; p2: TFloat): TPoint3D;
begin
	result := PointMake(p1.x-p2, p1.y-p2, p1.z-p2);
end;

class operator TPoint3D.* (p1: TPoint3D; p2: TFloat): TPoint3D;
begin
	result := PointMake(p1.x*p2, p1.y*p2, p1.z*p2);
end;

class operator TPoint3D./ (p1: TPoint3D; p2: TFloat): TPoint3D;
begin
	result := PointMake(p1.x/p2, p1.y/p2, p1.z/p2);
end;

function TPoint3D.ManhattanDirection (tileCoord: TPoint3D): TPoint3D;
begin
	result := PointMake(0, 0, 0);
	if x > tileCoord.x then
		result.x := 1
	else if x < tileCoord.x then
		result.x := -1;
	
	if y > tileCoord.y then
		result.y := 1
	else if y < tileCoord.y then
		result.y := -1;
	
	if z > tileCoord.z then
		result.z := 1
	else if z < tileCoord.z then
		result.z := -1;
end;

function TPoint3D.EuclideanDirection (tileCoord: TPoint3D): TPoint3D;
begin
	result := PointMake((self.x - tileCoord.x), (self.y - tileCoord.y), (self.z - tileCoord.z));
end;

function TPoint3D.IsZero: boolean;
begin
	result := (self.x = 0) and (self.y = 0) and (self.z = 0);
end;

function TPoint3D.IsValid: boolean;
begin
	result := (x <> -MaxInt) and (y <> -MaxInt) and (z <> -MaxInt);
end;

function TPoint3D.IsEqual (point: TPoint3D): boolean;
begin
	result := (self.x = point.x) and (self.y = point.y) and (self.z = point.z);
end;

function TPoint3D.IsEqualXY (point: TPoint3D): boolean;
begin
	result := (self.x = point.x) and (self.y = point.y);
end;

function TPoint3D.IsIntegral: boolean;
begin
	result := x.IsIntegral and y.IsIntegral and z.IsIntegral;
end;

function TPoint3D.Offset (byX, byY, byZ: TFloat): TPoint3D;
begin
	result := self;
	result.x += byX;
	result.y += byY;
	result.z += byZ;
end;

function TPoint3D.Offset (byX, byY: TFloat): TPoint3D;
begin
	result := self;
	result.x += byX;
	result.y += byY;
end;

function TPoint3D.Offset (point: TPoint3D): TPoint3D;
begin
	result := self;
	result.x += point.X;
	result.y += point.Y;
	result.z += point.Z;
end;

function TPoint3D.Divide (amount: TFloat): TPoint3D;
begin
	result := PointMake(x / amount, y / amount, z / amount);
end;

function TPoint3D.Multiply (amount: TFloat): TPoint3D;
begin
	result := PointMake(x * amount, y * amount, z * amount);
end;

function TPoint3D.Multiply (amount: TPoint3D): TPoint3D;
begin
	result := PointMake(x * amount.x, y * amount.y, z * amount.z);
end;

function TPoint3D.Sum: TFloat;
begin
	result := x + y + z;
end;

procedure TPoint3D.SetPoint (_x, _y, _z: TFloat);
begin
	x := _x;
	y := _y;
	z := _z;
end;

function TPoint3D.Clamp (lowest, highest: TPoint3D): TPoint3D;
begin
	result := self;
	if result.x < lowest.x then
		result.x := lowest.x;
	if result.y < lowest.y then
		result.y := lowest.y;
	if result.z < lowest.z then
		result.z := lowest.z;	
	if result.x > highest.x then
		result.x := highest.x;
	if result.y > highest.y then
		result.y := highest.y;
	if result.z > highest.z then
		result.z := highest.z;
end;

function TPoint3D.Clamp (lowest, highest: TFloat): TPoint3D;
begin
	result := self;
	if result.x < lowest then
		result.x := lowest;
	if result.y < lowest then
		result.y := lowest;
	if result.z < lowest then
		result.z := lowest;
	if result.x > highest then
		result.x := highest;
	if result.y > highest then
		result.y := highest;
	if result.z > highest then
		result.z := highest;
end;

function TPoint3D.Trunc: TPoint3D;
begin
	result := PointMake(System.Trunc(x), System.Trunc(y), System.Trunc(z));
end;

function TPoint3D.Ceil: TPoint3D;
begin
	result := PointMake(Math.Ceil(x), Math.Ceil(y), Math.Ceil(z));
end;

function TPoint3D.Round: TPoint3D;
begin
	result := PointMake(System.Round(x), System.Round(y), System.Round(z));
end;

function TPoint3D.Abs: TPoint3D;
begin
	result := PointMake(System.Abs(x), System.Abs(y), System.Abs(z));
end;

function TPoint3D.Floor: TPoint3D;
begin
	result := PointMake(Math.Floor(x), Math.Floor(y), Math.Floor(z));
end;

function TPoint3D.Integral: TPoint3D;
begin
	result := PointMake(System.Trunc(x), System.Trunc(y), System.Trunc(z));
end;

function TPoint3D.Point2D: TPoint;
begin
	result := PointMake(x, y);
end;

function TPoint3D.Add (amount: TFloat): TPoint3D;
begin
	result := PointMake(x + amount, y + amount, z + amount);
end;

function TPoint3D.Subtract (amount: TFloat): TPoint3D;
begin
	result := PointMake(x - amount, y - amount, z - amount);
end;

function TPoint3D.Add (amount: TPoint3D): TPoint3D;
begin
	result := PointMake(x + amount.x, y + amount.y, z + amount.z);
end;

function TPoint3D.Subtract (amount: TPoint3D): TPoint3D;
begin
	result := PointMake(x - amount.x, y - amount.y, z - amount.z);
end;

function TPoint3D.Magnitude: TFloat;
begin
	result := Sqrt(Power(x, 2) + Power(y, 2) + Power(z, 2));
end;

function TPoint3D.SquaredLength: TFloat;
begin
	result := Sqr(x) + Sqr(y) + Sqr(z);
end;

function TPoint3D.Normalize: TPoint3D;
begin
	result := self / Magnitude;
end;

function TPoint3D.Dot (point: TPoint3D): TFloat;
begin
	result := (x * point.x) + (y * point.y) + (z * point.z);
end;

function TPoint3D.Cross (point: TPoint3D): TPoint3D;
begin
	result.x := (self.y * point.z) - (self.z * point.y);
	result.y := (self.z * point.x) - (self.x * point.z);
	result.z := (self.x * point.y) - (self.y * point.x);
end;

function TPoint3D.AngleTo(constref b:TPoint3D): TFloat;
var
	d: TFloat;
begin
	d := Sqrt(SquaredLength*b.SquaredLength);
	if d <> 0.0 then
		result := Dot(b)/d
	else
		result := 0.0;
end;

function TPoint3D.Angle(constref b,c:TPoint3D):TFloat;
var DeltaAB,DeltaCB:TPoint3D;
    LengthAB,LengthCB:TFloat;
begin
 DeltaAB:=self-b;
 DeltaCB:=c-b;
 LengthAB:=DeltaAB.Magnitude;
 LengthCB:=DeltaCB.Magnitude;
 if (LengthAB=0.0) or (LengthCB=0.0) then begin
  result:=0.0;
 end else begin
  result:=ArcCos(DeltaAB.Dot(DeltaCB)/(LengthAB*LengthCB));
 end;
end;

function TPoint3D.Negate: TPoint3D;
begin
	result := PointMake(-x, -y, -z);
end;

function TPoint3D.PerpendicularRight: TPoint3D;
begin
	result := PointMake(-y, x, z);
end;

function TPoint3D.PerpendicularLeft: TPoint3D;
begin
	result := PointMake(y, -x, z);
end;

function TPoint3D.Compare (_x, _y, _z: TFloat): boolean;
begin
	result := (x = _x) and (y = _y) and (z = _z);
end;

function TPoint3D.Distance (point: TPoint3D): TFloat;
begin
	result := Subtract(point).Magnitude;
end;

// http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html
function TPoint3D.EuclideanDistance (toPoint: TPoint3D): TFloat;
var
	dx, dy, dz: TFloat;
	d: integer = 1;
begin
	dx := System.Abs(self.x - toPoint.x);
  dy := System.Abs(self.y - toPoint.y);
  dz := System.Abs(self.z - toPoint.z);
  result := D * sqrt(dx * dx + dy * dy + dz * dz);
end;

function TPoint3D.ManhattanDistance (toPoint: TPoint3D): integer;
begin
	result := (System.Abs(System.Trunc(toPoint.x - self.x)) + System.Abs(System.Trunc(toPoint.y - self.y))) + System.Abs(System.Trunc(toPoint.z - self.z));
end;

procedure TPoint3D.Show;
begin
	TShow(self);
end;

function TPoint3D.Str (places: integer = 0): string;
begin
	result := '{'+self.x.Str(places)+', '+self.y.Str(places)+', '+self.z.Str(places)+'}';
end;

class function TPoint3D.Make (_x, _y, _z: TFloat): TPoint3D;
begin
	result.x := _x;
	result.y := _y;
	result.z := _z;
end;

class function TPoint3D.Invalid: TPoint3D;
begin
	result := Make(-MaxInt, -MaxInt, -MaxInt);
end;

class function TPoint3D.Zero: TPoint3D;
begin
	result := Make(0, 0, 0);
end;

{=============================================}
{@! ___SIZE___ } 
{=============================================}

class operator TSize.+ (s1: TSize; s2: TFloat): TSize;
 begin
	result := SizeMake(s1.width + s2, s1.height + s2);
end;

class operator TSize.- (s1: TSize; s2: TFloat): TSize; 
begin
	result := SizeMake(s1.width - s2, s1.height - s2);
end;

class operator TSize.* (s1: TSize; s2: TFloat): TSize; 
begin
	result := SizeMake(s1.width * s2, s1.height * s2);
end;

class operator TSize./ (s1: TSize; s2: TFloat): TSize;
begin
	result := SizeMake(s1.width / s2, s1.height / s2);
end;

class operator TSize.+ (s1, s2: TSize): TSize;
begin
	result := SizeMake(s1.width + s2.width, s1.height + s2.height);
end;

class operator TSize.- (s1, s2: TSize): TSize;
begin
	result := SizeMake(s1.width - s2.width, s1.height - s2.height);
end;

class operator TSize.* (s1, s2: TSize): TSize;
begin
	result := SizeMake(s1.width * s2.width, s1.height * s2.height);
end;

class operator TSize./ (s1, s2: TSize): TSize;
begin
	result := SizeMake(s1.width / s2.width, s1.height / s2.height);
end;

class operator TSize.= (s1, s2: TSize): boolean; 
begin
	result := (s1.width = s2.width) and (s1.height = s2.height);
end;

function TSize.IsEqual (size: TSize): boolean;
begin
	result := (size.width = width) and (size.height = height);
end;

function TSize.Add (amount: TFloat): TSize;
begin
	result := SizeMake(width + amount, height + amount);
end;

function TSize.Add (amount: TSize): TSize;
begin
	result := SizeMake(width + amount.width, height + amount.height);
end;

function TSize.Divide (amount: TFloat): TSize;
begin
	result := SizeMake(width / amount, height / amount);
end;

function TSize.Multiply (amount: TFloat): TSize;
begin
	result := SizeMake(width * amount, height * amount);
end;

function TSize.Divide (amount: TSize): TSize;
begin
	result := SizeMake(width / amount.width, height / amount.height);
end;

function TSize.Multiply (amount: TSize): TSize;
begin
	result := SizeMake(width * amount.width, height * amount.height);
end;

function TSize.IsZero: boolean;
begin
	result := (width = 0) and (height = 0);
end;

function TSize.IsInfinte: boolean;
begin
	result := (width < 0) or (height < 0);
end;

class function TSize.Make (w, h: TFloat): TSize;
begin
	result.width := w;
	result.height := h;
end;

class function TSize.Make (size: TFloat): TSize;
begin
	result.width := size;
	result.height := size;
end;

procedure TSize.Show;
begin
	TShow(self);
end;

function TSize.Sum: TFloat;
begin
	result := width + height;
end;

function TSize.Vector: TPoint;
begin
	result := TPoint.Make(width, height);
end;

function TSize.Area: TFloat;
begin
	result := width * height;
end;

function TSize.Min: TFloat;
begin
	if width < height then
		result := width
	else
		result := height;
end;

function TSize.Max: TFloat;
begin
	if width > height then
		result := width
	else
		result := height;
end;

function TSize.Floor: TSize;
begin
	result := SizeMake(Math.Floor(width), Math.Floor(height));
end;

function TSize.Ceil: TSize;
begin
	result := SizeMake(Math.Ceil(width), Math.Ceil(height));
end;

function TSize.Str (places: integer = 0): string;
begin
	result := '{'+self.width.Str(places)+', '+self.height.Str(places)+'}';
end;

{=============================================}
{@! ___SIZE 3D___ } 
{=============================================}

class operator TSize3D.+ (s1: TSize3D; s2: TFloat): TSize3D;
 begin
	result := s1.Add(s2);
end;

class operator TSize3D.- (s1: TSize3D; s2: TFloat): TSize3D; 
begin
	result := SizeMake(s1.width - s2, s1.height - s2, s1.depth - s2);
end;

class operator TSize3D.* (s1: TSize3D; s2: TFloat): TSize3D; 
begin
	result := s1.Multiply(s2);
end;

class operator TSize3D./ (s1: TSize3D; s2: TFloat): TSize3D;
begin
	result := s1.Divide(s2);
end;

class operator TSize3D.+ (s1, s2: TSize3D): TSize3D;
begin
	result := s1.Add(s2);
end;

class operator TSize3D.- (s1, s2: TSize3D): TSize3D;
begin
	result := SizeMake(s1.width - s2.width, s1.height - s2.height, s1.depth - s2.depth);
end;

class operator TSize3D.* (s1, s2: TSize3D): TSize3D;
begin
	result := s1.Multiply(s2);
end;

class operator TSize3D./ (s1, s2: TSize3D): TSize3D;
begin
	result := s1.Divide(s2);
end;

class operator TSize3D.= (s1, s2: TSize3D): boolean; 
begin
	result := s1.IsEqual(s2);
end;

function TSize3D.IsEqual (size: TSize3D): boolean;
begin
	result := (size.width = width) and (size.height = height) and (size.depth = depth);
end;

function TSize3D.Add (amount: TFloat): TSize3D;
begin
	result := SizeMake(width + amount, height + amount, depth + amount);
end;

function TSize3D.Add (amount: TSize3D): TSize3D;
begin
	result := SizeMake(width + amount.width, height + amount.height, depth + amount.depth);
end;

function TSize3D.Divide (amount: TFloat): TSize3D;
begin
	result := SizeMake(width / amount, height / amount, depth / amount);
end;

function TSize3D.Multiply (amount: TFloat): TSize3D;
begin
	result := SizeMake(width * amount, height * amount, depth * amount);
end;

function TSize3D.Divide (amount: TSize3D): TSize3D;
begin
	result := SizeMake(width / amount.width, height / amount.height, depth / amount.depth);
end;

function TSize3D.Multiply (amount: TSize3D): TSize3D;
begin
	result := SizeMake(width * amount.width, height * amount.height, depth * amount.depth);
end;

function TSize3D.IsZero: boolean;
begin
	result := (width = 0) and (height = 0) and (depth = 0);
end;

procedure TSize3D.Show;
begin
	writeln(Str);
end;

function TSize3D.Floor: TSize3D;
begin
	result := SizeMake(Math.Floor(width), Math.Floor(height), Math.Floor(depth));
end;

function TSize3D.Ceil: TSize3D;
begin
	result := SizeMake(Math.Ceil(width), Math.Ceil(height), Math.Ceil(depth));
end;

function TSize3D.SetDepth (newValue: TFloat): TSize3D;
begin
	result := self;
	result.depth := newValue;
end;

function TSize3D.Size2D: TSize;
begin
	result := SizeMake(width, height);
end;

function TSize3D.WH: TSize;
begin
	result := SizeMake(width, height);
end;

function TSize3D.Sum: TFloat;
begin
	result := width + height + depth;
end;

function TSize3D.Volume: TFloat;
begin
	result := width * height * depth;
end;

function TSize3D.Vector: TPoint3D;
begin
	result := TPoint3D.Make(width, height, depth);
end;

function TSize3D.Str (places: integer = 0): string;
begin
		result := '{'+self.width.Str(places)+', '+self.height.Str(places)+', '+self.depth.Str(places)+'}';
end;

class function TSize3D.Make (_width, _height, _depth: TFloat): TSize3D;
begin
	result.width := _width;
	result.height := _height;
	result.depth := _depth;
end;

class function TSize3D.Make (_volume: TFloat): TSize3D;
begin
	result.width := _volume;
	result.height := _volume;
	result.depth := _volume;
end;

class function TSize3D.Make (size: TSize): TSize3D;
begin
	result.width := size.width;
	result.height := size.height;
	result.depth := 0;
end;

{=============================================}
{@! ___RECT___ } 
{=============================================}

function TRect.IsEmpty: boolean;
begin
	result := RectIsEmpty(self);
end;

function TRect.Polygon: TPolygon;
begin
	result := RectPolygon(self);
end;

function TRect.Divide (amount: TFloat): TRect;
begin
	result := RectMake(origin.Divide(amount), size.Divide(amount));
end;

function TRect.Multiply (amount: TFloat): TRect;
begin
	result := RectMake(origin.Multiply(amount), size.Multiply(amount));
end;

class operator TRect.+ (r1, r2: TRect): TRect;
begin
	result := RectMake(r1.origin.x + r2.origin.x, r1.origin.y + r2.origin.y, r1.size.width + r2.size.width, r1.size.height + r2.size.height);
end;

class operator TRect.- (r1, r2: TRect): TRect;
begin
	result := RectMake(r1.origin.x - r2.origin.x, r1.origin.y - r2.origin.y, r1.size.width - r2.size.width, r1.size.height - r2.size.height);
end;

class operator TRect.* (r1, r2: TRect): TRect; 
begin
	result := RectMake(r1.origin.x * r2.origin.x, r1.origin.y * r2.origin.y, r1.size.width * r2.size.width, r1.size.height * r2.size.height);
end;

class operator TRect./ (r1, r2: TRect): TRect; 
begin
	result := RectMake(r1.origin.x / r2.origin.x, r1.origin.y / r2.origin.y, r1.size.width / r2.size.width, r1.size.height / r2.size.height);
end;

class operator TRect.= (r1, r2: TRect): boolean; 
begin
	result := RectEqualToRect(r1, r2);
end;

class operator TRect.+ (r1: TRect; r2: TFloat): TRect;
begin
	result := RectMake(r1.origin.x + r2, r1.origin.y + r2, r1.size.width + r2, r1.size.height + r2);
end;

class operator TRect.- (r1: TRect; r2: TFloat): TRect;
begin
	result := RectMake(r1.origin.x - r2, r1.origin.y +- r2, r1.size.width - r2, r1.size.height - r2);
end;

class operator TRect.* (r1: TRect; r2: TFloat): TRect;
begin
	result := RectMake(r1.origin.x * r2, r1.origin.y * r2, r1.size.width * r2, r1.size.height * r2);
end;

class operator TRect./ (r1: TRect; r2: TFloat): TRect;
begin
	result := RectMake(r1.origin.x / r2, r1.origin.y / r2, r1.size.width / r2, r1.size.height / r2);
end;

function TRect.Floor: TRect;
begin
	result := RectMake(origin.Floor, size.Floor);
end;

function TRect.Ceil: TRect;
begin
	result := RectMake(Math.Ceil(origin.x), Math.Ceil(origin.y), Math.Ceil(size.width), Math.Ceil(size.height));
end;

function TRect.ContainsPoint (point: TPoint): boolean;
begin
	result := RectContainsPoint(self, point);
end;

function TRect.ContainsRect (rect: TRect): boolean;
begin
	result := RectContainsRect(self, rect);
end;

function TRect.IntersectsRect (rect: TRect): boolean;
begin
	result := RectIntersectsRect(self, rect);
end;

function TRect.GetWidth: TFloat;
begin
	result := size.width;
end;

function TRect.GetHeight: TFloat;
begin
	result := size.height;
end;

function TRect.Integral: TRect;
begin
	result := RectIntegral(self);
end;

function TRect.Offset (x, y: TFloat): TRect;
begin
	result := RectMake(origin.x + x, origin.y + y, size.width, size.height);
end;

function TRect.Offset (point: TPoint): TRect;
begin
	result := RectMake(origin.x + point.x, origin.y + point.y, size.width, size.height);
end;

function TRect.Inset (x, y: TFloat): TRect;
begin
	result := RectMake(origin.x + x, origin.y + y, size.width - (x * 2), size.height - (y * 2));
end;

function TRect.Inset (amount: TFloat): TRect;
begin
	result := Inset(amount, amount);
end;

function TRect.Clamp (point: TPoint): TPoint;
begin
	if point.x > GetMaxX then
		point.x := GetMaxX;
	if point.x < GetMinX then      
		point.x := GetMinX;
	             
	if point.y > GetMaxY then
		point.y := GetMaxY;
	if point.y < GetMinY then      
		point.y := GetMinY;      
	
	result := point;    
end;

function TRect.Union (rect: TRect): TRect;
var
	aabb: TAABB2;
begin
	result := self;
	
	if result.GetMinX < rect.GetMinX then
		aabb.min.x := result.GetMinX
	else
		aabb.min.x := rect.GetMinX;
	
	if result.GetMinY < rect.GetMinY then
		aabb.min.y := result.GetMinY
	else
		aabb.min.y := rect.GetMinY;
	
	if result.GetMaxX > rect.GetMaxX then
		aabb.max.x := result.GetMaxX
	else
		aabb.max.x := rect.GetMaxX;
	
	if result.GetMaxY > rect.GetMaxY then
		aabb.max.y := result.GetMaxY
	else
		aabb.max.y := rect.GetMaxY;
	
	result := RectMake(aabb.min.x, aabb.min.y, aabb.max.x - aabb.min.x, aabb.max.y - aabb.min.y);
end;

function TRect.Resize (s: TSize): TRect;
begin
	result := RectMake(origin.x, origin.y, size.width + s.width, size.height + s.height);
end;

function TRect.Resize (width, height: TFloat): TRect;
begin
	result := RectMake(origin.x, origin.y, size.width + width, size.height + height);
end;

function TRect.Resize (s: TFloat): TRect;
begin
	result := RectMake(origin.x, origin.y, size.width + s, size.height + s);
end;

function TRect.SetSize (width, height: TFloat): TRect;
begin
	size.width += width;
	size.height += height;
	result := self;
end;

function TRect.SetOrigin (x, y: TFloat): TRect;
begin
	origin.x := x;
	origin.y := y;
	result := self;
end;

function TRect.Min: TPoint;
begin
	result := origin;
end;

function TRect.Max: TPoint;
begin
	result := PointMake(GetMaxX, GetMaxY);
end;

function TRect.Mid: TPoint;
begin
	result := PointMake(GetMidX, GetMidY);
end;


function TRect.GetTopLeft: TPoint;
begin
	result := origin;
end;

function TRect.GetTopRight: TPoint;
begin
	result := PointMake(GetMaxX, GetMinY);
end;

function TRect.GetBottomLeft: TPoint;
begin
	result := PointMake(GetMinX, GetMaxY);
end;

function TRect.GetBottomRight: TPoint;
begin
	result := PointMake(GetMaxX, GetMaxY);
end;

function TRect.GetCenter: TPoint;
begin
	result := PointMake(GetMidX, GetMidY);
end;

function TRect.GetMinX: TFloat;
begin
	result := origin.x;
end;

function TRect.GetMidX: TFloat;
begin
	result := origin.x + (size.width / 2);
end;

function TRect.GetMaxX: TFloat;
begin
	result := origin.x + size.width;
end;

function TRect.GetMinY: TFloat;
begin
	result := origin.y;
end;

function TRect.GetMidY: TFloat;
begin
	result := origin.y + (size.height / 2);
end;

function TRect.GetMaxY: TFloat;
begin
	result := origin.y + size.height;
end;

procedure TRect.Show;
begin
	TShow(self);
end;

class function TRect.Empty: TRect;
begin
	result := TRect.Make(0, 0, 0, 0);
end;

class function TRect.Infinite: TRect;
begin
	result.origin.x := MaxInt;
	result.origin.y := MaxInt;
	result.size.width := -MaxInt;
	result.size.height := -MaxInt;
end;

class function TRect.Make (x, y, width, height: TFloat): TRect;
begin
	result.origin.x := x;
	result.origin.y := y;
	result.size.width := width;
	result.size.height := height;
end;

class function TRect.Make (point: TPoint): TRect;
begin
	result.origin := point;
	result.size := SizeMake(1, 1);
end;

function TRect.Str (places: integer = 0): string;
begin
	result := '{'+self.origin.Str(places)+', '+self.size.Str(places)+'}';
end;

{=============================================}
{@! ___RECT 3D___ } 
{=============================================}

class function TRect3D.Make (rect: TRect): TRect3D;
begin
	result.origin.x := rect.origin.x;
	result.origin.y := rect.origin.y;
	result.origin.z := 0;
	result.size.width := rect.size.width;
	result.size.height := rect.size.height;
	result.size.depth := 0;
end;

class function TRect3D.Make (rect: TRect; originZ, sizeDepth: TFloat): TRect3D;
begin
	result.origin.x := rect.origin.x;
	result.origin.y := rect.origin.y;
	result.origin.z := originZ;
	result.size.width := rect.size.width;
	result.size.height := rect.size.height;
	result.size.depth := sizeDepth;
end;

class function TRect3D.Make (x, y, z, width, height, depth: TFloat): TRect3D;
begin
	result.origin.x := x;
	result.origin.y := y;
	result.origin.z := z;
	result.size.width := width;
	result.size.height := height;
	result.size.depth := depth;
end;

class function TRect3D.Empty: TRect3D;
begin
	result.origin.x := 0;
	result.origin.y := 0;
	result.origin.z := 0;
	result.size.width := 0;
	result.size.height := 0;
	result.size.depth := 0;
end;

function TRect3D.Min: TPoint3D;
begin
	result := origin;
end;

function TRect3D.Max: TPoint3D;
begin
	result := PointMake(MaxX, MaxY, MaxZ);
end;

function TRect3D.Mid: TPoint3D;
begin
	result := PointMake(MidX, MidY, MidZ);
end;

function TRect3D.MinX: TFloat;
begin
	result := origin.x;
end;

function TRect3D.MidX: TFloat;
begin
	result := origin.x + (size.width / 2);
end;

function TRect3D.MaxX: TFloat;
begin
	result := origin.x + size.width;
end;

function TRect3D.MinY: TFloat;
begin
	result := origin.y;
end;

function TRect3D.MidY: TFloat;
begin
	result := origin.y + (size.height / 2);
end;

function TRect3D.MaxY: TFloat;
begin
	result := origin.y + size.height;
end;

function TRect3D.MinZ: TFloat;
begin
	result := origin.z;
end;

function TRect3D.MidZ: TFloat;
begin
	result := origin.z + (size.depth / 2);
end;

function TRect3D.MaxZ: TFloat;
begin
	result := origin.z + size.depth;
end;

function TRect3D.Width: TFloat;
begin
	result := size.width;
end;

function TRect3D.Height: TFloat;
begin
	result := size.height;
end;

function TRect3D.Depth: TFloat;
begin
	result := size.depth;
end;

function TRect3D.Center: TPoint3D;
begin
	result := TPoint3D.Make(origin.x + (size.width / 2), origin.y + (size.height / 2), origin.z + (size.depth / 2));
end;

procedure TRect3D.Show;
begin
	writeln(Str);
end;

function TRect3D.Str (places: integer = 0): string;
begin
	result := '{'+origin.str(places)+', '+size.str(places)+'}';
end;

function TRect3D.Inset (x, y, z: TFloat): TRect3D;
begin
	result := RectMake(origin.x + x, origin.y + y, origin.z + z, size.width - (x * 2), size.height - (y * 2), size.depth - (z * 2));
end;

function TRect3D.Union (rect: TRect3D): TRect3D;
var
	aabb: TAABB3;
begin
	result := self;
	
	if result.MinX < rect.MinX then
		aabb.min.x := result.MinX
	else
		aabb.min.x := rect.MinX;
	
	if result.MinY < rect.MinY then
		aabb.min.y := result.MinY
	else
		aabb.min.y := rect.MinY;
	
	if result.MinZ < rect.MinZ then
		aabb.min.z := result.MinZ
	else
		aabb.min.z := rect.MinZ;
	
	if result.MaxX > rect.MaxX then
		aabb.max.x := result.MaxX
	else
		aabb.max.x := rect.MaxX;
	
	if result.MaxY > rect.MaxY then
		aabb.max.y := result.MaxY
	else
		aabb.max.y := rect.MaxY;

	if result.MaxZ > rect.MaxZ then
		aabb.max.z := result.MaxZ
	else
		aabb.max.z := rect.MaxZ;
	
	result := RectMake(aabb.min.x, aabb.min.y, aabb.min.z, aabb.max.x - aabb.min.x, aabb.max.y - aabb.min.y, aabb.max.z - aabb.min.z);
end;

function TRect3D.IntersectsRect (rect: TRect3D): boolean;
begin
	result := (rect.MinX < MaxX) and 
						(rect.MaxX > MinX) and 
						(rect.MinY < MaxY) and 
						(rect.MaxY > MinY) and
						(rect.MinZ < MaxZ) and 
						(rect.MaxZ > MinZ);
end;

function TRect3D.ContainsPoint (point: TPoint3D): boolean;
begin
	result := (point.x >= MinX) and 
						(point.y >= MinY) and 
						(point.z >= MinZ) and 
						(point.x <= MaxX) and 
						(point.y <= MaxY) and
						(point.z <= MaxZ);
end;

function TRect3D.IsEmpty: boolean;
begin
	result := size.IsZero;
end;

function TRect3D.Rect2D: TRect;
begin
	result := RectMake(origin.x, origin.y, size.width, size.height);
end;

{=============================================}
{@! ___UTILITIES___ } 
{=============================================}

// Converts point from [x, y]
function PointFromString (str: string): TPoint;
var
	arr: TJSONArray;
begin
	if str = '' then
		raise Exception.Create('PointFromString: string can''t be empty.');
	arr := TJSONArray(GetJSON(str));
	result := PointMake(arr.Floats[0], arr.Floats[1]);
end;

// Converts rect from [x, y, width, height]
function RectFromString (str: string): TRect;
var
	arr: TJSONArray;
begin
	if str = '' then
		raise Exception.Create('RectFromString: string can''t be empty.');
	arr := TJSONArray(GetJSON(str));
	result := RectMake(arr.Floats[0], arr.Floats[1], arr.Floats[2], arr.Floats[3]);
end;

// Converts size from [width, height]
function SizeFromString (str: string): TSize;
var
	arr: TJSONArray;
begin
	if str = '' then
		raise Exception.Create('SizeFromString: string can''t be empty.');
	arr := TJSONArray(GetJSON(str));
	result := SizeMake(arr.Floats[0], arr.Floats[1]);
end;

function StringFromPoint (point: TPoint): string;
begin
	result := '['+FloatToStr(point.x)+','+FloatToStr(point.y)+']';
end;

function StringFromRect (rect: TRect): string;
begin
	result := '['+FloatToStr(rect.origin.x)+','+FloatToStr(rect.origin.y)+','+FloatToStr(rect.size.width)+','+FloatToStr(rect.size.height)+']';
end;

function StringFromSize (size: TSize): string;
begin
	result := '['+FloatToStr(size.width)+','+FloatToStr(size.height)+']';
end;

function PointOffset (point: TPoint; x, y: TFloat): TPoint; inline;
begin
	result := PointMake(point.x + x, point.y + y);
end;

function PointIsZero (point: TPoint): boolean; inline;
begin
	result := (point.x = 0) and (point.x = 0);
end;

function RectZero: TRect; inline;
begin
	result := RectMake(0, 0, 0, 0);
end;

function PointZero: TPoint; inline;
begin
	result := PointMake(0, 0);
end;

function PointInvalid: TPoint; inline;
begin
	result := PointMake(-MaxInt, -MaxInt);
end;

function Point3DInvalid: TPoint3D; inline;
begin
	result := PointMake(-MaxInt, -MaxInt, -MaxInt);
end;

function PointMax: TPoint; inline;
begin
	result := PointMake(MaxInt, MaxInt);
end;

function PointMin: TPoint; inline;
begin
	result := PointMake(-MaxInt, -MaxInt);
end;

function Point3DZero: TPoint3D; inline;
begin
	result := PointMake(0, 0, 0);
end;

function RectCenter (rect: TRect; target: TRect): TRect; inline;
begin
	result.size := rect.size;
	result.origin := target.origin;
	
	result := RectCenterX(result, target);
	result := RectCenterY(result, target);
end;

function RectCenterX (rect: TRect; target: TRect): TRect; inline;
begin
	result := rect;
	
	if RectWidth(target) >= RectWidth(rect) then
		result.origin.x += (target.size.width / 2) - (rect.size.width / 2)
	else
		result.origin.x := RectMidX(target) - (rect.size.width / 2);
end;

function RectCenterY (rect: TRect; target: TRect): TRect; inline;
begin
	result := rect;
	
	if RectHeight(target) >= RectHeight(rect) then
		result.origin.y := RectMinY(target) + ((target.size.height / 2) - (rect.size.height / 2))
	else
		result.origin.y := RectMidY(target) - (rect.size.height / 2);
end;

function RectPolygon (rect: TRect): TPolygon;
begin
	result := TPolygon.Make(4);
	result.SetVertex(0, PointMake(rect.GetMinX, rect.GetMinY));
	result.SetVertex(1, PointMake(rect.GetMaxX, rect.GetMinY));
	result.SetVertex(2, PointMake(rect.GetMinX, rect.GetMaxY));
	result.SetVertex(3, PointMake(rect.GetMaxX, rect.GetMaxY));
end;

function RectMinX (rect: TRect): TFloat;
begin
	result := rect.origin.x;
end;

function RectMidX (rect: TRect): TFloat;
begin
	result := rect.origin.x + (rect.size.width / 2);
end;

function RectMaxX (rect: TRect): TFloat;
begin
	result := rect.origin.x + rect.size.width;
end;

function RectMinY (rect: TRect): TFloat;
begin
	result := rect.origin.y;
end;

function RectMidY (rect: TRect): TFloat;
begin
	result := rect.origin.y + (rect.size.height / 2);
end;

function RectMaxY (rect: TRect): TFloat;
begin
	result := rect.origin.y + rect.size.height;
end;

function RectWidth (rect: TRect): TFloat;
begin
	result := rect.size.width;
end;

function RectHeight (rect: TRect): TFloat;
begin
	result := rect.size.height;
end;

function RectIsEmpty (rect: TRect): boolean;
begin
	result := (RectWidth(rect) = 0) and (RectHeight(rect) = 0);
end;

function RectInset (rect: TRect; x, y: TFloat): TRect; inline;
begin
	result.origin.x := rect.origin.x + (x);
	result.origin.y := rect.origin.y + (y);
	result.size.width := rect.size.width - (x * 2);
	result.size.height := rect.size.height - (y * 2);
end;

function RectOffset (rect: TRect; x, y: TFloat): TRect; inline;
begin
	result.size := rect.size;
	result.origin.x := rect.origin.x + x;
	result.origin.y := rect.origin.y + y;
end;

function RectContainsPoint (rect: TRect; point: TPoint): boolean; inline;
begin
	result := (point.x >= RectMinX(rect)) and (point.y >= RectMinY(rect)) and (point.x <= RectMaxX(rect)) and (point.y <= RectMaxY(rect));
end;

function RectContainsRect (rect1: TRect; rect2: TRect): boolean; inline;
begin
	result := (RectMinX(rect2) >= RectMinX(rect1)) and (RectMinY(rect2) >= RectMinY(rect1)) and (RectMaxX(rect2) <= RectMaxX(rect1)) and (RectMaxY(rect2) <= RectMaxY(rect1));
end;

function RectIntersectsRect (rect1: TRect; rect2: TRect): boolean; inline;
begin
	// http://stackoverflow.com/questions/306316/determine-if-two-rectangles-overlap-each-other
	result := (RectMinX(rect1) < RectMaxX(rect2)) and 
						(RectMaxX(rect1) > RectMinX(rect2)) and 
						(RectMinY(rect1) < RectMaxY(rect2)) and 
						(RectMaxY(rect1) > RectMinY(rect2));
end;

function PointMake (s: TFloat): TPoint; inline;
begin
	result.x := s;
	result.y := s;
end;

function PointMake (x, y: TFloat): TPoint; inline;
begin
	result.x := x;
	result.y := y;
end;

function PointMake (point: TPoint; z: TFloat): TPoint3D; inline;
begin
	result.x := point.x;
	result.y := point.y;
	result.z := z;
end;

function PointMake (x, y, z: TFloat): TPoint3D; inline;
begin
	result.x := x;
	result.y := y;
	result.z := z;
end;

function SizeMake (width, height: TFloat): TSize; inline;
begin
	result.width := width;
	result.height := height;
end;

function SizeMake (s: TFloat): TSize; inline;
begin
	result.width := s;
	result.height := s;
end;

function SizeMake (w, h, d: TFloat): TSize3D; inline;
begin
	result.width := w;
	result.height := h;
	result.depth := d;
end;

function SizeMake (size: TSize; depth: TFloat): TSize3D; inline;
begin
	result.width := size.width;
	result.height := size.height;
	result.depth := depth;
end;

function RectMake (x, y: TFloat; width, height: TFloat): TRect; inline;
begin
	result.origin := PointMake(x, y);
	result.size := SizeMake(width, height);
end;

function RectMake (x, y, z: TFloat; width, height, depth: TFloat): TRect3D; inline;
begin
	result.origin := PointMake(x, y, z);
	result.size := SizeMake(width, height, depth);
end;

function RectMake (origin: TPoint; size: TSize): TRect; inline;
begin
	result.origin := origin;
	result.size := size;
end;

function RectMake (origin: TPoint3D; size: TSize3D): TRect3D; inline;
begin
	result.origin := origin;
	result.size := size;
end;

function RectMake (rect: TRect): TRect3D; inline;
begin
	result.origin.x := rect.origin.x;
	result.origin.y := rect.origin.y;
	result.origin.z := 0;
	
	result.size.width := rect.size.width;
	result.size.height := rect.size.height;
	result.size.depth := 0;
end;

procedure TShow (rect: TRect); overload;
begin
	writeln(RectString(rect));
end;

procedure TShow (size: TSize); overload;
begin
	writeln(SizeString(size));
end;

procedure TShow (point: TPoint); overload;
begin
	writeln(PointString(point));
end;

procedure TShow (point: TPoint3D); overload;
begin
	writeln(PointString(point));
end;

function RectIntegral (rect: TRect): TRect; inline;
begin
	result.origin.x := trunc(rect.origin.x);
	result.origin.y := trunc(rect.origin.y);
	result.size.width := trunc(rect.size.width);
	result.size.height := trunc(rect.size.height);
end;

function PointIntegral (point: TPoint): TPoint; inline;
begin
	result.x := trunc(point.x);
	result.y := trunc(point.y);
end;

function SizeIntegral (size: TSize): TSize; inline;
begin
	result.width := trunc(size.width);
	result.height := trunc(size.height);
end;

function RectEqualToRect (rect1, rect2: TRect): boolean;
begin
	result := (RectMinX(rect1) = RectMinX(rect2)) and (RectMinY(rect1) = RectMinY(rect2)) and (RectWidth(rect1) = RectWidth(rect2)) and (RectHeight(rect1) = RectHeight(rect2));
end;

function PointEqualToPoint (point1, point2: TPoint): boolean;
begin
	result := (point1.x = point2.x) and (point1.y = point2.y);
end;

function PointEqualToPoint (point1, point2: TPoint3D): boolean;
begin
	result := (point1.x = point2.x) and (point1.y = point2.y) and (point1.z = point2.z);
end;

function SizeEqualToSize (size1, size2: TSize): boolean;
begin
	result := (size1.width = size2.width) and (size1.height = size2.height);
end;

function RectString (rect: TRect): string;
begin
	result := '{'+PointString(rect.origin)+', '+SizeString(rect.size)+'}';
end;

function SizeString (size: TSize): string;	
begin
	result := '{'+FloatToStr(size.width)+', '+FloatToStr(size.height)+'}';
end;

function PointString (point: TPoint): string;	
begin
	result := '{'+FloatToStr(point.x)+', '+FloatToStr(point.y)+'}';
end;

function PointString (point: TPoint3D): string;	
begin
	result := '{'+FloatToStr(point.x)+', '+FloatToStr(point.y)+', '+FloatToStr(point.z)+'}';
end;

function TStr (rect: TRect): string; overload;
begin
	result := RectString(rect);
end;

function TStr (size: TSize): string; overload;	
begin
	result := SizeString(size);
end;

function TStr (point: TPoint): string; overload;
begin
	result := PointString(point);
end;

function TStr (point: TPoint3D): string; overload;
begin
	result := PointString(point);
end;

end.