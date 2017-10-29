{$mode objfpc}

unit UNotificationCenter;
interface
uses
	Objects, UArray, UDictionary, UInvocation, UObject;
	
type
	TNotification = class (TDictionary)
		public
			
			{ Class Methods }
			class function Notification (name: string; userInfo: TObject): TNotification; overload;
			class function Notification (userInfo: TObject): TNotification; overload;
			
			{ Accessors }
			function GetName: string;
			function GetObject: pointer;
			function GetUserInfo: TObject;
			
		private
			objct: pointer;
	end;
	TNotificationClass = class of TNotification;
	
{ The dispatch message parameter for all notification handlers }	
type
	NotificationDispatchMessage = record
		method: string;
		notification: TNotification;
	end;
	
type 
	TNotificationCenter = class (TObject)
		public
			
			{ Class Methods }
			class function DefaultCenter: TNotificationCenter;
			
			{ Posting Notifications }
			procedure PostNotification (name: string; objct: pointer; userInfo: TObject); overload;
			procedure PostNotification (name: string; objct: pointer); overload;
			procedure PostNotification (name: string); overload;
			procedure PostNotification (notification: TNotification); overload;
			
			{ Observing Notifications }
			procedure ObserveNotification (observer: TObject; name: string; withMethod: Pointer); overload;
			procedure ObserveNotification (observer: TObject; name: string; withMethod: Pointer; objct: pointer); overload;
			
			procedure RemoveObserver (observer: TObject; notification: string); overload;
			procedure RemoveEveryObserver (observer: TObject);
				
			{ Accessors }
			function IsObserving (observer: TObject; notification: string): boolean;
			
		protected
			procedure Initialize; override;
			procedure Deallocate; override;
			
		private
			handlers: TArray;
	end;

implementation

const
	kNotificiationUserInfoKey = 'userInfo';
	kNotificiationNameKey = 'name';

type 
	TNotificationHandler = class (TInvocation)
		public
			constructor Create (_action: pointer; _target: TObject; _notification: string; _object: pointer);
			
			function GetNotification: string;
			function GetObject: pointer;
			
		private
			notification: string;
			obj: pointer;															
	end;

var
	GlobalDefaultCenter: TNotificationCenter = nil;
	
{=============================================}
{@! ___NOTIFICATION HANDLER___ } 
{=============================================}
constructor TNotificationHandler.Create (_action: pointer; _target: TObject; _notification: string; _object: pointer);
begin
	SetAction(_action);
	SetTarget(_target);
	notification := _notification;
	obj := _object;
	Initialize;
end;

function TNotificationHandler.GetObject: pointer;
begin
	result := obj;
end;

function TNotificationHandler.GetNotification: string;
begin
	result := notification;
end;

{=============================================}
{@! ___NOTIFICATION___ } 
{=============================================}
class function TNotification.Notification (name: string; userInfo: TObject): TNotification;
begin
	result := TNotification.Create;
	result.SetValue(kNotificiationNameKey, name);
	if userInfo <> nil then
		result.SetValue(kNotificiationUserInfoKey, userInfo);
	result.AutoRelease;
end;

class function TNotification.Notification (userInfo: TObject): TNotification;
begin
	result := TNotification.Create;
	result.SetValue(kNotificiationUserInfoKey, userInfo);
	result.AutoRelease;
end;

function TNotification.GetUserInfo: TObject;
begin
	result := GetValue(kNotificiationUserInfoKey);
end;

function TNotification.GetName: string;
begin
	result := GetStringValue(kNotificiationNameKey);
end;

function TNotification.GetObject: pointer;
begin
	result := objct;
end;

{=============================================}
{@! ___NOTIFICATION CENTER___ } 
{=============================================}
function TNotificationCenter.IsObserving (observer: TObject; notification: string): boolean;
var
	handler: TNotificationHandler;
begin
	result := false;
	for pointer(handler) in handlers do
		if (handler.GetTarget = observer) and (handler.GetNotification = notification) then
			exit(true);
end;

procedure TNotificationCenter.RemoveObserver (observer: TObject; notification: string);
var
	handler: TNotificationHandler;
	removedHandlers: TArray;
begin
	removedHandlers := TArray.Instance;
	
	for pointer(handler) in handlers do
		if (handler.GetTarget = observer) and (handler.GetNotification = notification) then
			removedHandlers.AddValue(handler);
			
	for pointer(handler) in removedHandlers do
		handlers.RemoveFirstValue(handler);
end;

{ Invoked to remove observer from notification centers }
procedure TNotificationCenter.RemoveEveryObserver (observer: TObject);
var
	handler: TNotificationHandler;
	removedHandlers: TArray;
begin
	removedHandlers := TArray.Instance;
	
	for pointer(handler) in handlers do
		if handler.GetTarget = observer then
			removedHandlers.AddValue(handler);
			
	for pointer(handler) in removedHandlers do
		handlers.RemoveFirstValue(handler);
end;

procedure TNotificationCenter.PostNotification (name: string; objct: pointer; userInfo: TObject);
var
	handler: TNotificationHandler;
	notification: TNotification;
begin
	notification := TNotification.Notification(name, userInfo);
	for pointer(handler) in handlers do
		if (handler.GetNotification = name) and (handler.GetObject = objct) then
			handler.Invoke(notification);
end;

procedure TNotificationCenter.PostNotification (name: string; objct: pointer);
begin
	PostNotification(name, objct, nil);
end;

procedure TNotificationCenter.PostNotification (name: string);
begin
	PostNotification(name, nil, nil);
end;

procedure TNotificationCenter.PostNotification (notification: TNotification);
begin
	PostNotification(notification.GetName, notification.GetObject, notification);
end;

procedure TNotificationCenter.ObserveNotification (observer: TObject; name: string; withMethod: pointer; objct: pointer);
var
	handler: TNotificationHandler;
begin
	handler := TNotificationHandler.Create(withMethod, observer, name, objct);
	handlers.AddValue(handler);
	handler.Release;		
end;

procedure TNotificationCenter.ObserveNotification (observer: TObject; name: string; withMethod: Pointer);
begin
	ObserveNotification(observer, name, withMethod, nil);
end;

class function TNotificationCenter.DefaultCenter: TNotificationCenter;
begin
	result := GlobalDefaultCenter;
end;

procedure TNotificationCenter.Initialize;
begin
	inherited Initialize;
	
	handlers := TArray.Create;
end;

procedure TNotificationCenter.Deallocate;
begin
	handlers.Release;
	
	inherited Deallocate;
end;

begin
	RegisterClass(TNotification);
	
	GlobalDefaultCenter := TNotificationCenter.Create;
end.