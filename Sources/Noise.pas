{$mode objfpc}

unit Noise;
interface
uses
	UGeometry, UObject, SysUtils, Math;

//perlin.c
//https://gist.github.com/nowl/828013

//simplex noise
//http://stackoverflow.com/questions/18279456/any-simplex-noise-tutorials-or-resources
//http://staffwww.itn.liu.se/~stegu/simplexnoise/SimplexNoise.java

//pascal
//http://wiki.freepascal.org/Perlin_Noise
//http://laggyluk.com/?p=86

(*
public static float[][] generateSimplexNoise(int width, int height){
      float[][] simplexnoise = new float[width][height];
      float frequency = 5.0f / (float) width;
      
      for(int x = 0; x < width; x++){
         for(int y = 0; y < height; y++){
            simplexnoise[x][y] = (float) noise(x * frequency,y * frequency);
            simplexnoise[x][y] = (simplexnoise[x][y] + 1) / 2;   //generate values between 0 and 1
         }
      }
      
      return simplexnoise;
   }
*)

const
	kNoisekPerumationMax = 256;

type
	TNoiseValue = byte;
	TNoiseSeedArray = array[0..kNoisekPerumationMax-1] of TNoiseValue;
	TNoiseFloat = double;
	
//http://flafla2.github.io/2014/08/09/perlinnoise.html
//https://gist.github.com/Flafla2/f0260a861be0ebdeef76

type
	TNoise = class (TObject)
		public
			constructor Create; overload;
			constructor Create (seed: TNoiseSeedArray); overload;
			
			function GetValue (x, y, z: TNoiseFloat): TNoiseFloat; overload;
			function GetValue (p: TPoint3D): TNoiseFloat; overload;
			function GetValue (x, y, z: TNoiseFloat; octaves: integer; persistence: TNoiseFloat): TNoiseFloat; overload;
			
		private
			repeatValue: integer;
			p: array[0..(kNoisekPerumationMax * 2)-1] of TNoiseValue;
			
			function Inc (num: integer): integer;
			function Grad (hash: integer; x, y, z: TNoiseFloat): TNoiseFloat;
			function Fade (t: TNoiseFloat): TNoiseFloat; 
			function Lerp (a, b, x: TNoiseFloat): TNoiseFloat; 
	end;

function RandomNoiseSeed (seed: cardinal = 0): TNoiseSeedArray;

implementation

function RandomNoiseSeed (seed: cardinal = 0): TNoiseSeedArray; 
var
	i: integer;
	savedSeed: cardinal;
begin
	if seed > 0 then
		begin
			savedSeed := RandSeed;
			RandSeed := seed;
		end;
		
	for i := 0 to kNoisekPerumationMax - 1 do
		result[i] := Random(kNoisekPerumationMax);
		
	if seed > 0 then
		RandSeed := savedSeed;
end;

function TNoise.GetValue (x, y, z: TNoiseFloat; octaves: integer; persistence: TNoiseFloat): TNoiseFloat;
var
	total: TNoiseFloat = 0;
	frequency: TNoiseFloat = 1;
	amplitude: TNoiseFloat = 1;
	maxValue: TNoiseFloat = 0; // Used for normalizing result to 0.0 - 1.0
	i: integer;
begin
	for i := 0 to octaves - 1 do
		begin
			total += GetValue(x * frequency, y * frequency, z * frequency) * amplitude;
			maxValue += amplitude;
			amplitude *= persistence;
      frequency *= 2;
		end;
	result := total/maxValue;
end;

function TNoise.GetValue (p: TPoint3D): TNoiseFloat;
begin
	result := GetValue(p.x, p.y, p.z);
end;

function TNoise.GetValue (x, y, z: TNoiseFloat): TNoiseFloat;
function FMod(const a, b: TNoiseFloat): TNoiseFloat;
begin
  result:= a-b * trunc(a/b);
end;
var
	xi, yi, zi: integer;
	xf, yf, zf: TNoiseFloat;
	u, v, w: TNoiseFloat;
	aaa, aba, aab, abb, baa, bba, bab, bbb: integer;
	x1, x2, y1, y2: TNoiseFloat;
begin
	// If we have any repeat on, change the coordinates to their "local" repetitions
	if (repeatValue > 0) then			
		begin
			x := FMod(x, repeatValue);
			y := FMod(y, repeatValue);
			z := FMod(z, repeatValue);
			// ??? mod overloading for singles in trunk 3.1.1
			{x := x mod repeatValue;
			y := y mod repeatValue;
			z := z mod repeatValue;}
		end;
	
	xi := Floor(x) and 255;								// Calculate the "unit cube" that the point asked will be located in
	yi := Floor(y) and 255;								// The left bound is ( |_x_|,|_y_|,|_z_| ) and the right bound is that
	zi := Floor(z) and 255;								// plus 1.  Next we calculate the location (from 0.0 to 1.0) in that cube.
	xf := x-Floor(x);											// We also fade the location to smooth the result.
	yf := y-Floor(y);
	zf := z-Floor(z);
	u := Fade(xf);
	v := Fade(yf);
	w := Fade(zf);
	
	aaa := p[p[p[    xi ]+    yi ]+    zi ];
	aba := p[p[p[    xi ]+inc(yi)]+    zi ];
	aab := p[p[p[    xi ]+    yi ]+inc(zi)];
	abb := p[p[p[    xi ]+inc(yi)]+inc(zi)];
	baa := p[p[p[inc(xi)]+    yi ]+    zi ];
	bba := p[p[p[inc(xi)]+inc(yi)]+    zi ];
	bab := p[p[p[inc(xi)]+    yi ]+inc(zi)];
	bbb := p[p[p[inc(xi)]+inc(yi)]+inc(zi)];
	
	x1 := Lerp(	Grad(aaa, xf  , yf  , zf),				// The gradient function calculates the dot product between a pseudorandom
				Grad(baa, xf-1, yf  , zf),							// gradient vector and the vector from the input coordinate to the 8
				u);																			// surrounding points in its unit cube.
	x2 := Lerp(	Grad(aba, xf  , yf-1, zf),				// This is all then lerped together as a sort of weighted average based on the faded (u,v,w)
				Grad(bba, xf-1, yf-1, zf),							// values we made earlier.
		          u);
	y1 := Lerp(x1, x2, v);

	x1 := Lerp(	Grad(aab, xf  , yf  , zf-1),
				Grad(bab, xf-1, yf  , zf-1),
				u);
	x2 := Lerp(	Grad(abb, xf  , yf-1, zf-1),
	          	Grad(bbb, xf-1, yf-1, zf-1),
	          	u);
	y2 := Lerp(x1, x2, v);
	
	result := (Lerp(y1, y2, w)+1)/2;						// For convenience we bound it to 0 - 1 (theoretical min/max before is -1 - 1)
end;

function TNoise.Inc (num: integer): integer;
begin
	num += 1;
	if repeatValue > 0 then
		num := num mod repeatValue;
	result := num;
end;

// http://riven8192.blogspot.com/2010/08/calculate-perlinnoise-twice-as-fast.html
function TNoise.Grad (hash: integer; x, y, z: TNoiseFloat): TNoiseFloat;
begin
	case (hash and $F) of
		$0:
			result := x + y;
		$1:
			result := -x + y;
		$2:
			result := x - y;
		$3:
			result := -x - y;
		$4:
			result := x + z;
		$5:
			result := -x + z;
		$6:
			result := x - z;
		$7:
			result := -x - z;
		$8:
			result := y + z;
		$9:
			result := -y + z;
		$A:
			result := y - z;
		$B:
			result := -y - z;
		$C:
			result := y + x;
		$D:
			result := -y + z;
		$E:
			result := y - x;
		$F:
			result :=	-y - z;
		otherwise
			result := 0; // never happens
	end;
end;

{
function TNoise.Grad (hash: integer; x, y, z: TNoiseFloat): TNoiseFloat;
var
	h: integer;
	u, v: TNoiseFloat;
begin
	h := hash and 15;									// Take the hashed value and take the first 4 bits of it (15 == 0b1111)
	
	if h < 8 then
		u := x
	else
		u := y;

	if h < 4 then
		v := y
	else if (h = 12) or (h = 14) then
		v := x
	else
		v := z;
	
	if h and 1 = 0 then
		result := u
	else
		result := -u;
		
	if h and 2 = 0 then
		result := result + v
	else
		result := result - v;
end;
}

function TNoise.Fade (t: TNoiseFloat): TNoiseFloat; 
begin
	// Fade function as defined by Ken Perlin.  This eases coordinate values
	// so that they will "ease" towards integral values.  This ends up smoothing
	// the final output.
	result := t * t * t * (t * (t * 6 - 15) + 10);			// 6t^5 - 15t^4 + 10t^3
end;

function TNoise.Lerp (a, b, x: TNoiseFloat): TNoiseFloat; 
begin
	result := a + x * (b - a);
end;

constructor TNoise.Create;
begin	
	Create(RandomNoiseSeed);
end;

constructor TNoise.Create (seed: TNoiseSeedArray);
var
	i: integer;
begin	
	repeatValue := -1;
	for i := 0 to high(p) do
		p[i] := seed[i mod kNoisekPerumationMax];
	Initialize;
end;

end.