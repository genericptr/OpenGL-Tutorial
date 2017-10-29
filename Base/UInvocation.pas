{$mode objfpc}

unit UInvocation;
interface
uses
	SysUtils, Objects, UArray, UObject;

const
	kInvocationRetainArgumentsWeak = 0;
	kInvocationRetainArgumentsTObject = 1;

type
	TInvocationRetainArgsMode = smallint;
	TInvocationCallback = procedure (arguments: pointer);

type
	TInvocation = class (TObject)
		public
		
			constructor Instance (_action: pointer; _target: TObject; _arguments: pointer = nil; _retainArguments: TInvocationRetainArgsMode = kInvocationRetainArgumentsWeak); overload;
			constructor Instance (_action: string; _target: TObject; _arguments: pointer = nil; _retainArguments: TInvocationRetainArgsMode = kInvocationRetainArgumentsWeak); overload;
			constructor Instance (_action: TInvocationCallback; _arguments: pointer = nil; _retainArguments: TInvocationRetainArgsMode = kInvocationRetainArgumentsWeak); overload;
			
			constructor Create (_action: pointer; _target: TObject; _arguments: pointer = nil; _retainArguments: TInvocationRetainArgsMode = kInvocationRetainArgumentsWeak); overload;
			constructor Create (_action: string; _target: TObject; _arguments: pointer = nil; _retainArguments: TInvocationRetainArgsMode = kInvocationRetainArgumentsWeak); overload;
			constructor Create (_action: TInvocationCallback; _arguments: pointer = nil; _retainArguments: TInvocationRetainArgsMode = kInvocationRetainArgumentsWeak);
			
			{
			constructor Instance (_action: pointer; _target: TObject; _arguments: pointer; _retainArguments: TInvocationRetainArgsMode); overload;
			constructor Instance (_action: pointer; _target: TObject; _arguments: pointer); overload;
			constructor Instance (_action: pointer; _target: TObject); overload;
			constructor Instance (_action: string; _target: TObject; _arguments: pointer; _retainArguments: TInvocationRetainArgsMode); overload;
			constructor Instance (_action: string; _target: TObject; _arguments: pointer); overload;
			constructor Instance (_action: string; _target: TObject); overload;
			constructor Instance (_action: TInvocationCallback; _arguments: pointer; _retainArguments: TInvocationRetainArgsMode); overload;
			constructor Instance (_action: TInvocationCallback; _arguments: pointer); overload;
			
			constructor Create (_action: pointer; _target: TObject; _arguments: pointer; _retainArguments: TInvocationRetainArgsMode); overload;
			constructor Create (_action: pointer; _target: TObject; _arguments: pointer); overload;
			constructor Create (_action: pointer; _target: TObject); overload;
			constructor Create (_action: string; _target: TObject); overload;
			constructor Create (_action: TInvocationCallback); overload;
			constructor Create (_action: TInvocationCallback; _arguments: pointer); overload;
			constructor Create (_action: TInvocationCallback; _arguments: pointer; _retainArguments: TInvocationRetainArgsMode);
			}
			
			procedure Invoke (_arguments: pointer); virtual; overload;
			procedure Invoke; virtual; overload;
			
			{ Accessors }
			procedure SetAction (newValue: pointer); overload;
			procedure SetAction (newValue: string); overload;
			procedure SetTarget (newValue: TObject);
			
			procedure SetArguments (newValue: pointer; _retain: integer); overload;
			procedure SetArguments (newValue: pointer); overload;
			
			function GetTarget: TObject;
			function GetArguments: pointer;
			
			{ Methods }
			procedure AddInvocation (invocation: TInvocation);
			
		protected
			procedure Deallocate; override;
			
		private
			target: TObject;
			actionPointer: pointer;
			actionString: string;		
			arguments: pointer;	 
			retainArguments: TInvocationRetainArgsMode;
			invocations: TArray;
	end;

type
	TInvocationObjectHelpers = class helper for TObject
		function InvocationForMethod (_action: pointer): TInvocation; overload;
		function InvocationForMethod (_action: string): TInvocation; overload;
	end;

procedure Invoke (action: TInvocation);
	
implementation

function TInvocationObjectHelpers.InvocationForMethod (_action: pointer): TInvocation;
begin
	result := TInvocation.Instance(_action, self, nil);
end;

function TInvocationObjectHelpers.InvocationForMethod (_action: string): TInvocation;
begin
	result := TInvocation.Instance(_action, self, nil);
end;

procedure Invoke (action: TInvocation);
begin
	if action <> nil then
		action.Invoke;
end;

procedure TInvocation.AddInvocation (invocation: TInvocation);
begin
	if invocations = nil then
		invocations := TArray.Create;
	invocations.AddValue(invocation);
end;

procedure TInvocation.SetArguments (newValue: pointer);
begin
	SetArguments(newValue, kInvocationRetainArgumentsWeak);
end;

procedure TInvocation.SetArguments (newValue: pointer; _retain: integer);
begin
	retainArguments := _retain;
	case retainArguments of
		kInvocationRetainArgumentsWeak:
			arguments := newValue;
		kInvocationRetainArgumentsTObject:
			arguments := TObject(newValue).Retain;
	end
end;

function TInvocation.GetTarget: TObject;
begin
	result := target;
end;

function TInvocation.GetArguments: pointer;
begin
	result := arguments;
end;

procedure TInvocation.Invoke (_arguments: pointer);
var
	invocation: TInvocation;
begin
	if target <> nil then
		begin				
			if actionPointer <> nil then
				target.InvokeMethod(actionPointer, _arguments)
			else
				target.InvokeMethod(actionString, _arguments);
		end
	else
		// call a plain function
		TInvocationCallback(actionPointer)(_arguments);
	
	// invoke children
	if invocations <> nil then
		begin
			for pointer(invocation) in invocations do
				invocation.Invoke;
			invocations.Release;
			invocations := nil;	
		end;
end;

procedure TInvocation.Invoke;
begin
	Invoke(arguments);
end;

procedure TInvocation.Deallocate;
begin	
	ReleaseObject(target);
	ReleaseObject(invocations);
	
	if retainArguments = kInvocationRetainArgumentsTObject then
		ReleaseObject(arguments);
	
	inherited Deallocate;	
end;

procedure TInvocation.SetAction (newValue: pointer);
begin
	actionPointer := newValue;
end;

procedure TInvocation.SetAction (newValue: string);
begin
	actionString := newValue;
end;

procedure TInvocation.SetTarget (newValue: TObject);
begin
	if target <> nil then
		target.Release;
	target := newValue.Retain;
end;

constructor TInvocation.Instance (_action: TInvocationCallback; _arguments: pointer = nil; _retainArguments: TInvocationRetainArgsMode = kInvocationRetainArgumentsWeak);
begin
	Create(_action, _arguments, _retainArguments);
	AutoRelease;
end;

constructor TInvocation.Instance (_action: pointer; _target: TObject; _arguments: pointer = nil; _retainArguments: TInvocationRetainArgsMode = kInvocationRetainArgumentsWeak);
begin
	Create(_action, _target);
	SetArguments(_arguments, _retainArguments);
	AutoRelease;
end;

constructor TInvocation.Instance (_action: string; _target: TObject; _arguments: pointer = nil; _retainArguments: TInvocationRetainArgsMode = kInvocationRetainArgumentsWeak);
begin
	Create(_action, _target);
	SetArguments(_arguments, _retainArguments);
	AutoRelease;
end;

constructor TInvocation.Create (_action: pointer; _target: TObject; _arguments: pointer = nil; _retainArguments: TInvocationRetainArgsMode = kInvocationRetainArgumentsWeak);
begin
	if _target = nil then	
		raise Exception.Create('TInvocation: target must not be nil.');
	target := _target.Retain;
	actionPointer := _action;
	SetArguments(_arguments, _retainArguments);
	Initialize; 
end;

constructor TInvocation.Create (_action: string; _target: TObject; _arguments: pointer = nil; _retainArguments: TInvocationRetainArgsMode = kInvocationRetainArgumentsWeak);
begin
	if _target = nil then	
		raise Exception.Create('TInvocation: target must not be nil.');
	target := _target.Retain;
	actionString := _action;
	SetArguments(_arguments, _retainArguments);
	Initialize;
end;

constructor TInvocation.Create (_action: TInvocationCallback; _arguments: pointer = nil; _retainArguments: TInvocationRetainArgsMode = kInvocationRetainArgumentsWeak);
begin
	actionPointer := _action;
	SetArguments(_arguments, _retainArguments);
	Initialize;
end;

end.