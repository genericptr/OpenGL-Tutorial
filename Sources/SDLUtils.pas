{$mode objfpc}

unit SDLUtils;
interface
uses
	UColor, UGeometry, UObject,
	GL, GLExt, SysUtils, SDL,
	UTypes;
	
const
	kSDLOpenGLWindow_Modern = true;	
	kSDLOpenGLWindow_Legacy = false;	

type
	TSDLOpenGLWindow = class (TObject)
		public
			constructor Create (width, height: integer; modern: boolean = kSDLOpenGLWindow_Legacy);
			procedure RunMainLoop;
			function GetWidth: integer;
			function GetHeight: integer;
		protected
			procedure Prepare; virtual;
			procedure Update; virtual;
			procedure HandleEvent (event: TSDL_Event); virtual;
			procedure Reshape (width, height: integer); virtual;
		private
			window: PSDL_Window;
			context: PSDL_GLContext;
	end;
	
type
	TSDLBitmapWindow = class (TObject)
		public
			constructor Create (width, height: integer; zoom: single = 1.0);
			procedure RunMainLoop;
			procedure Close;
			procedure Redraw; 
			function GetWidth: integer;
			function GetHeight: integer;
			function GetZoom: single;
			
			procedure DrawPixel (r,g,b,a: single; x, y: integer); overload;
			procedure DrawPixel (c: TRGBA; x, y: integer); overload;
			procedure FillRect (r,g,b,a: single; rect: TRect); overload;
			procedure FillRect (c: TRGBA; rect: TRect); overload;
			procedure DrawRect (c: TRGBA; rect: TRect); overload;

		protected
			procedure HandleEvent (event: TSDL_Event); virtual;
			procedure HandleDraw; virtual;			
		private
			window: PSDL_Window;
			renderer: PSDL_Renderer;
			windowSize: TSize;
	end;

function GetDataFile (name: string): string;
procedure SetBasePath (name: string);

var
	SystemKeysDown: array[0..1024] of boolean;
	
implementation

const
	FRAME_RATE = 1000 div 60;

var
	BasePath: string = '';

procedure SetBasePath (name: string);
begin
	BasePath := name;
end;

function GetDataFile (name: string): string;
begin
	if BasePath <> '' then
		result := SDL_GetBasePath+BasePath+'/'+name
	else
		result := SDL_GetBasePath+name;
end;
	
function TimeLeft (nextTime: UInt32): UInt32;
var
	now: UInt32;
begin
	now := SDL_GetTicks;
	if nextTime <= now then
		result := 0
	else
		result := nextTime - now;
end;

{=============================================}
{@! ___OPENGL WINDOW___ } 
{=============================================}

function TSDLOpenGLWindow.GetWidth: integer;
var
	w, h: LongInt;
begin
	SDL_GetWindowSize(window, w, h);
	result := w;
end;

function TSDLOpenGLWindow.GetHeight: integer;
var
	w, h: LongInt;
begin
	SDL_GetWindowSize(window, w, h);
	result := h;
end;

constructor TSDLOpenGLWindow.Create (width, height: integer; modern: boolean = kSDLOpenGLWindow_Legacy);
var
	value: longint;
begin
	Initialize;
	
	if SDL_Init(SDL_INIT_VIDEO) < 0 then
		Fatal('SDL could not initialize! '+SDL_GetError);
	
	if modern = kSDLOpenGLWindow_Legacy then
		begin
			if Load_GL_VERSION_2_1 = false then
				Fatal('OpenGL is not loaded');
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);	
			SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
		  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);	
		end
	else
		begin
			//if Load_GL_VERSION_4_0 = false then
			if Load_GL_VERSION_3_3 = false then
			if Load_GL_VERSION_3_2 = false then
			if Load_GL_VERSION_3_0 = false then
			if Load_GL_VERSION_2_1 = false then
				Fatal('OpenGL is not loaded');
						
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);	
			SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
		  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);

			{SDL_GL_GetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, value);
			writeln('SDL_GL_CONTEXT_MAJOR_VERSION: ', value);
			SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, value);	
			writeln('SDL_GL_CONTEXT_MINOR_VERSION: ', value);}
		end;
	
	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);

	// create window	
	window := SDL_CreateWindow('SDL Tutorial', SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, SDL_WINDOW_SHOWN + SDL_WINDOW_OPENGL + SDL_WINDOW_RESIZABLE);
	if window = nil then
		writeln('Window could not be created! ', SDL_GetError)
	else
		begin
			context := SDL_GL_CreateContext(window);
			SDL_GL_MakeCurrent(window, context);
			SDL_GL_SetSwapInterval(1);
		end;
	
	writeln('Vendor: ', glGetString(GL_VENDOR));
	writeln('OpenGL Version: ', glGetString(GL_VERSION));
	writeln('GLSL Version: ', glGetString(GL_SHADING_LANGUAGE_VERSION));
	 
 	// setup
	Prepare;
	Reshape(width, height);
end;

procedure TSDLOpenGLWindow.RunMainLoop; 
var
	event: TSDL_Event;
	quit: boolean = false;
	nextTime: UInt32 = 0;
	frameRateTime: UInt32;
	frameCount: integer = 0;
begin
	// run main loop
	nextTime := SDL_GetTicks + FRAME_RATE;
	frameRateTime := SDL_GetTicks;
	while not quit do
		begin
			SDL_GL_MakeCurrent(window, context);
			
			while SDL_PollEvent(event) > 0 do
				begin
					HandleEvent(event);
					if event.type_ = SDL_QUIT_EVENT then
						quit := true
					else if event.type_ = SDL_WINDOW_EVENT then
						begin
							case event.window.event of
								SDL_WINDOWEVENT_LEAVE:
									begin
									end;
								SDL_WINDOWEVENT_RESIZED:
									begin
										Reshape(event.window.data1, event.window.data2);
									end;
							end;
						end
					else if event.type_ = SDL_KEYDOWN then
						begin
							if event.key.keysym.sym < length(SystemKeysDown) then
							SystemKeysDown[event.key.keysym.sym] := true;
						end
					else if event.type_ = SDL_KEYUP then
						begin
							if event.key.keysym.sym < length(SystemKeysDown) then
							SystemKeysDown[event.key.keysym.sym] := false;
						end;
				end;
			
			Update;
			
			SDL_GL_SwapWindow(window);
			SDL_Delay(TimeLeft(nextTime));
			nextTime += FRAME_RATE;
			frameCount += 1;
			
			// debugging
			if SDL_GetTicks >= frameRateTime + 1000 then 
				begin
					frameRateTime := SDL_GetTicks;
					frameCount := 0;
				end;
		end;
	
	SDL_DestroyWindow(window);
end;

procedure TSDLOpenGLWindow.Prepare;
begin
	glClearColor(1, 1, 1, 1);
	glEnable(GL_BLEND);	
	glDisable(GL_ALPHA_TEST);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
end;

procedure TSDLOpenGLWindow.Reshape (width, height: integer);
begin
	glViewPort(0, 0, width, height);
end;

procedure TSDLOpenGLWindow.Update;
begin
end;

procedure TSDLOpenGLWindow.HandleEvent (event: TSDL_Event);
begin
end;

{=============================================}
{@! ___BITMAP WINDOW___ } 
{=============================================}
function TSDLBitmapWindow.GetWidth: integer;
begin
	result := windowSize.width.int;
end;

function TSDLBitmapWindow.GetHeight: integer;
begin
	result := windowSize.height.int;
end;

function TSDLBitmapWindow.GetZoom: single; 
var
	scaleX, scaleY: SDL_Float;
begin
	SDL_RenderGetScale(renderer, scaleX, scaleY);
	result := scaleX;
end;

constructor TSDLBitmapWindow.Create (width, height: integer; zoom: single = 1.0);
begin
	windowSize := SizeMake(width, height);
	SDL_Init(SDL_INIT_VIDEO);
	SDL_CreateWindowAndRenderer(trunc(width * zoom), trunc(height * zoom), 0, window, renderer);
	//SDL_SetWindowPosition(window, x, y);
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
	SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
  SDL_RenderClear(renderer);
	SDL_RenderSetScale(renderer, zoom, zoom);
	SDL_SetWindowTitle(window, '');
	Initialize;
	Redraw;
end;

procedure TSDLBitmapWindow.DrawRect (c: TRGBA; rect: TRect); 
var
	sdlRect: SDL_Rect;
begin
	SDL_SetRenderDrawColor(renderer, trunc(c.red * 255), trunc(c.green * 255), trunc(c.blue * 255), trunc(c.alpha * 255));
	sdlRect.x := rect.GetMinX.int;
	sdlRect.y := rect.GetMinY.int;
	sdlRect.w := rect.GetWidth.int;
	sdlRect.h := rect.GetHeight.int;
	SDL_RenderDrawRect(renderer, sdlRect);
end;

procedure TSDLBitmapWindow.FillRect (r,g,b,a: single; rect: TRect); 
var
	sdlRect: SDL_Rect;
begin
	SDL_SetRenderDrawColor(renderer, trunc(r * 255), trunc(g * 255), trunc(b * 255), trunc(a * 255));
	sdlRect.x := rect.GetMinX.int;
	sdlRect.y := rect.GetMinY.int;
	sdlRect.w := rect.GetWidth.int;
	sdlRect.h := rect.GetHeight.int;
	SDL_RenderFillRect(renderer, sdlRect);
end;

procedure TSDLBitmapWindow.FillRect (c: TRGBA; rect: TRect); 
var
	sdlRect: SDL_Rect;
begin
	SDL_SetRenderDrawColor(renderer, trunc(c.red * 255), trunc(c.green * 255), trunc(c.blue * 255), trunc(c.alpha * 255));
	sdlRect.x := rect.GetMinX.int;
	sdlRect.y := rect.GetMinY.int;
	sdlRect.w := rect.GetWidth.int;
	sdlRect.h := rect.GetHeight.int;
	SDL_RenderFillRect(renderer, sdlRect);
end;

procedure TSDLBitmapWindow.DrawPixel (r,g,b,a: single; x, y: integer); 
begin
	SDL_SetRenderDrawColor(renderer, trunc(r * 255), trunc(g * 255), trunc(b * 255), trunc(a * 255));
	SDL_RenderDrawPoint(renderer, x, y);
end;

procedure TSDLBitmapWindow.DrawPixel (c: TRGBA; x, y: integer); 
begin
	SDL_SetRenderDrawColor(renderer, trunc(c.red * 255), trunc(c.green * 255), trunc(c.blue * 255), trunc(c.alpha * 255));
	SDL_RenderDrawPoint(renderer, x, y);
end;

procedure TSDLBitmapWindow.HandleDraw; 
begin
end;

procedure TSDLBitmapWindow.Close; 
begin
	SDL_DestroyWindow(window);
	Release;
end;

procedure TSDLBitmapWindow.Redraw; 
begin
	SDL_SetRenderDrawColor(renderer, 1,1,1,1);
	SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
  
	SDL_RenderClear(renderer);
	HandleDraw;
	SDL_RenderPresent(renderer);
end;

procedure TSDLBitmapWindow.RunMainLoop; 
var
	event: TSDL_Event;
	nextTime: UInt32 = 0;
label
	Quit;
begin
	nextTime := SDL_GetTicks + FRAME_RATE;
	while true do
		begin
			while SDL_PollEvent(event) > 0 do
				begin
					HandleEvent(event);
					if event.type_ = SDL_WINDOW_EVENT then
						begin
							if event.window.event = SDL_WINDOWEVENT_CLOSE then
							if SDL_GetWindowFromID(event.window.windowID) = window then
								begin
									Close;
									exit;
								end;
						end
					else if event.type_ = SDL_QUIT_EVENT then
						goto Quit;
				end;
			
			SDL_Delay(TimeLeft(nextTime));
			nextTime += FRAME_RATE;
		end;
	Quit:
	SDL_Quit();
end;

procedure TSDLBitmapWindow.HandleEvent (event: TSDL_Event);
begin
end;

begin
	FillChar(SystemKeysDown, sizeof(SystemKeysDown), false);
end.