{$mode objfpc}
{$include targetos}
{$interfaces CORBA}

unit USystem;
interface
uses
	{$ifdef SDL}
	SDL,
	{$endif}
	SysUtils;

const
	kDefaultFrameRate = 60;

type
	TSystemTimeCallback = function: double;
	ISystemTime = interface
		function GetSystemTime: double;
		procedure SetSystemTimeCallback (newValue: TSystemTimeCallback);
	end;
		
procedure SetPreferredSystemFrameRate (interval: integer);
function GetPreferredSystemFrameRate: integer; inline;
function GetCurrentThreadID: Longint; inline;
procedure SetMainThreadID (newValue: Longint); 
function GetMainThreadID: Longint; inline;
function SystemTime: double; inline;
function MillisecondsSinceNow: double; inline;
procedure SystemSleep (duration: single); 
procedure FatalNotMainThread; inline;
procedure Fatal (messageString: string); overload;
procedure Fatal (condition: boolean; messageString: string); overload;

implementation

var
	PreferredSystemFrameRate: integer = kDefaultFrameRate;
	SystemInitialized: boolean = false;
	MainThreadID: Longint = 0;
	
function SystemTime: double;
begin
	result := TimeStampToMSecs(DateTimeToTimeStamp(Now)) / 1000;
end;	
	
function MillisecondsSinceNow: double;
begin
	result := TimeStampToMSecs(DateTimeToTimeStamp(Now));
end;		
	
{$ifdef SDL}
procedure SystemSleep (duration: single); 
begin
	SDL_Delay(trunc(duration * 1000));
end;	

function GetCurrentThreadID: Longint; 
begin
	result := SDL_GetThreadID(nil);
end;
{$else}
function GetCurrentThreadID: Longint; 
begin
	result := 0;
end;

procedure SystemSleep (duration: single); 
begin
	raise exception.create('SystemSleep');
end;	
{$endif}	

procedure Fatal (messageString: string);
begin
	Fatal(true, messageString);
end;

procedure Fatal (condition: boolean; messageString: string);
begin
	if condition then
		begin
			// NOTE: exceptions require the following breakpoints to be set in lldb
			//b FPC_RAISEEXCEPTION
			//b FPC_BREAK_ERROR
			//raise Exception.Create(messageString);
			writeln('***** Exception: ', messageString);
			halt;
			//b USystem.pas:88
		end;
end;

procedure FatalNotMainThread; 
begin
	if MainThreadID <> GetCurrentThreadID then
		Fatal('Not main thread');
end;

function GetMainThreadID: Longint; 
begin
	result := MainThreadID;
end;
	
procedure SetMainThreadID (newValue: Longint); 
begin
	MainThreadID := newValue;
end;	
	
procedure SetPreferredSystemFrameRate (interval: integer);
begin
	PreferredSystemFrameRate := interval;
end;

function GetPreferredSystemFrameRate: integer;
begin
	result := PreferredSystemFrameRate;
end;

end.