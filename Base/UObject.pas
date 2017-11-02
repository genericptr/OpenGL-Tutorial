{$mode objfpc}
{$interfaces CORBA}
{$modeswitch advancedrecords}

unit UObject;
interface
uses
	TypInfo, CTypes, SysUtils, Objects, Classes,
	UTypes, USystem;

const
	kEmptyParameter = nil;		{ Use for passing empty parameters to TObject descendants }
	
{ Generic Parameters for TObject.InitializeParameter and AllocateClass }
type
	ParameterType = record
		integerType: integer;
		stringType: string;
		pointerType: pointer;
		booleanType: boolean;
	end;
	
type
	ParameterArray = array of ParameterType;
	ParameterArrayPointer = ^ParameterArray;

{ Dispatching }	
type
	TDispatchMessage = record
		method: string;
		params: pointer;
	end;

{ Method Pointers }	
type
	TMethodPointer = procedure(params: pointer) of object;
	TVoidMethodPointer = procedure of object;
	
type
	TNamedMethod = record
		name: string;
		func: pointer;
	end;
	
type
	InterfaceUUID = LongInt;
	
type 
	TObject = class;
	TObjectClass = class of TObject;		
	TAutoReleasePoolProtocol = class;	
		
	IDelegate = interface ['IDelegate']
	end;

	IObject = interface
		function GetObject: TObject;
		function GetInterface (uuid: InterfaceUUID): IObject;
		function Retain: TObject;
		procedure Release;
	end;
	
	type
		TCallback = record
			private
				method: pointer;
				target: TObject;
				params: pointer;
			public
				class function None: TCallback; static; inline;
				constructor Create (_method: pointer; _target: TObject; _params: pointer = nil);
				procedure Invoke (_params: pointer = nil); 
		end;
			
	TObject = class (IObject)
		public
			
			{ Class Methods }
			class procedure RegisterAutoReleasePool (pool: TAutoReleasePoolProtocol);
			
			{ Constructors }
			constructor Create; virtual;
			constructor Allocate; virtual;
			constructor Instance; virtual;
			constructor WeakInstance; virtual;
			
			{ Copying }
			function Copy: TObject; overload;
			function Copy (params: pointer): TObject; overload;
			function CopyOfClass (theClass: TClass): TObject;
			function GetCopyParameters: pointer;
			procedure SetCopyParameters (newValue: pointer);
			function DidInitializeFromCopying: boolean;
				
			{ Dynamic Calling }
			function InvokeMethod (name: string; params: Pointer = nil): Pointer; overload;
			function InvokeMethod (method: Pointer; params: Pointer = nil): Pointer; overload;
			procedure RegisterMethod (name: string; method: Pointer);
			function FindMethod (name: string): Pointer;
			function IsMethodRegistered (name: string): boolean;
							
			{ Memory Managment }
			function Retain: TObject;
			function AutoRelease: TObject;
			procedure Release;
			function IsAutoReleasing: boolean;
			function GetRetainCount: integer;
			procedure SetRetainCount (newValue: integer);
			procedure RemoveFromAutoRelease;
			function ManageObject (obj: TObject): TObject; overload;
			procedure ManageObject (src: TObject; out obj); overload;
			procedure ManageObject (theClass: TObjectClass; out obj); overload;
			procedure RequestInitialization;
			
			{ IObject }
			function GetObject: TObject;
			function GetInterface (uuid: InterfaceUUID): IObject; virtual;
			
			{ Method Responses }
			function GetMethodResponse (name: string): boolean; virtual;
			
			{ Introspection }
			procedure Show; virtual;
			function IsEqual (value: TObject): boolean; virtual;
			function IsMember (ofClass: TObjectClass): boolean; overload;
			function IsMember (ofClass: string): boolean; overload;
			function IsMember (ofObject: TObject): boolean; overload;
			function GetDebugString: string; overload;
			function GetDebugString (advanced: boolean): string; overload;
			function GetDescription: string; virtual;
			
			procedure DefaultHandlerStr (var message); override;
						
		protected
			procedure Initialize; virtual;
			procedure Deallocate; virtual;
			procedure CopyInstanceVariables (clone: TObject); virtual;
			procedure InitializeParameter (index: integer; value: ParameterType); virtual;
			
		private
			registeredMethods: array of TNamedMethod;
			managedObjects: array of TObject;
			autoReleaseCount: Word;
			retainCount: Word;
			didInitialize: boolean;
			initializedFromCopying: boolean;
			copyParameters: pointer;
			
			function ShowNotes: boolean;
	end;
	TObjectPtr = ^TObject;
	
type
	TAutoReleasePoolProtocol = class (TObject)
		procedure AddObject (obj: TObject); virtual; abstract;
		procedure Drain; virtual; abstract;
	end;	

type
	IDelegation = interface
		procedure SetDelegate (newValue: TObject);
		function GetDelegate: TObject;
	end;

const
	IHashableUUID = 859276348;
type
	IHashable = interface (IObject) ['IHashable']
		function GetHashString: string;
	end;
	
	
{ High-Level Object Managment }
function AllocateClass (name: string): TObject; overload;
function AllocateClass (name: string; params: ParameterArray): TObject; overload;
function FindClass (name: string): TObjectClass; overload;
function ClassRegistered (name: string): boolean;
procedure RegisterClass (theClass: TObjectClass); overload;
procedure RegisterClass (className: string; theClass: TObjectClass); overload;
procedure ReleaseObject (var io); overload;
procedure ReleaseObjects (objects: array of const);
procedure RetainObject (var io; newObject: TObject); overload;
procedure CopyObject (var io; newObject: TObject); overload;
procedure RetainInterface (var io; newObject: IObject);
procedure ReleaseInterface (var io);
function MemberOfClass (obj: TObject; theClass: TObjectClass): boolean; overload;
function MemberOfClass (obj: TObject; theClass: string): boolean; overload;
function Transform (obj: TObject; theClass: TClass): TObject;
function InstanceVarName (theClass: TObjectClass; ivar: string): string;
procedure InitializeObject (obj: TObject);
procedure ShowObject (obj: TObject);
procedure PrintValue (typeKind: TTypeKind; value: pointer); 

procedure DrainAutoReleasePool;
	
function GetRandomInterfaceUUID (digits: integer = 9): InterfaceUUID;

// aliases for Fatal()
procedure Fatal (messageString: string); overload; inline;
procedure Fatal (condition: boolean; messageString: string); overload; inline;

implementation

const
	kIgnoreClassesCount = 1;
	
type
	ClassDefinition = record
		name: string;
		classType: TObjectClass;
	end;

type
	TAutoReleasePoolArray = specialize TDynamicList<TAutoReleasePoolProtocol>;
var
	RegisteredClasses: array of ClassDefinition;
	AutoReleasePoolStack: TAutoReleasePoolArray;	
	
var
	ShowMemoryNotes: boolean = false;
	IgnoreClasses: array[1..kIgnoreClassesCount] of string = ('dTDictionary');
	

{=============================================}
{@! ___CALLBACK___ } 
{=============================================}

procedure TCallback.Invoke (_params: pointer = nil); 
begin
	if target <> nil then
		begin
			if _params = nil then
				target.InvokeMethod(method, params)
			else
				target.InvokeMethod(method, _params);
		end;
end;

constructor TCallback.Create (_method: pointer; _target: TObject; _params: pointer = nil);
begin
	method := _method;
	target := _target;
	params := _params;
end;
	
class function TCallback.None: TCallback;
begin
	result := Default(TCallback);
end;
	
{=============================================}
{@! ___UTILITIES___ } 
{=============================================}
procedure PrintValue (typeKind: TTypeKind; value: pointer); 
begin
	case typeKind of
		tkClass:
			begin
				if value <> nil then
					TObjectPtr(value)^.Show
				else
					writeln('nil');
			end;
		tkPointer:
			begin
				if value <> nil then
					writeln(HexStr(PPointer(value)^))
				else
					writeln('nil');
			end;
		tkRecord:
			writeln('record');
		tkSString:
			writeln(PShortString(value)^);
		otherwise
			writeln(PInteger(value)^); // this is just a hack to print compiler types
	end;
end;
procedure ShowObject (obj: TObject);
begin
	if assigned(obj) then
		obj.show
	else
		writeln('nil');
end;

function GlobalAutoReleasePool: TAutoReleasePoolProtocol; 
begin
	if AutoReleasePoolStack.Count > 0 then
		result := AutoReleasePoolStack.GetLastValue as TAutoReleasePoolProtocol
	else
		result := nil;
end;

function GetRandomInterfaceUUID (digits: integer): InterfaceUUID;
var
	uuid: string = '';
	i: integer;
begin
	for i := 1 to digits do
		uuid := uuid+IntToStr(System.Random(10) mod ((10 - 1) + 1));
	result := StrToInt(uuid);
end;

procedure Fatal (messageString: string);
begin
	USystem.Fatal(true, messageString);
end;

procedure Fatal (condition: boolean; messageString: string);
begin
	USystem.Fatal(condition, messageString);
end;

procedure ToggleMemoryNotes;
begin
	ShowMemoryNotes := not ShowMemoryNotes;
end;
	
procedure DrainAutoReleasePool;
begin
	if GlobalAutoReleasePool <> nil then
		GlobalAutoReleasePool.Drain;
end;	
	
{=============================================}
{@! ___CLASS INTROSPECTION___ } 
{=============================================}

function MemberOfClass (obj: TObject; theClass: string): boolean; overload;
begin
	result := false;
	if obj <> nil then
		if obj.InheritsFrom(FindClass(theClass)) then
			result := true;
end;

function MemberOfClass (obj: TObject; theClass: TObjectClass): boolean; overload;
begin
	result := false;
	if obj <> nil then
		if obj.InheritsFrom(theClass) then
			result := true;
end;

procedure RegisterClass (className: string; theClass: TObjectClass); 
begin
	SetLength(RegisteredClasses, Length(RegisteredClasses) + 1);
	RegisteredClasses[High(RegisteredClasses)].name := className;
	RegisteredClasses[High(RegisteredClasses)].classType := theClass;
end; 

procedure RegisterClass (theClass: TObjectClass); 
begin
	RegisterClass(theClass.ClassName, theClass);
end; 

function ClassRegistered (name: string): boolean;
begin
	result := FindClass(name) <> nil;
end;

function FindClass (name: string): TObjectClass;
var
	def: ClassDefinition;
begin
	result := nil;
	for def in RegisteredClasses do
		if def.name = name then
			exit(def.classType);
end; 

{ Returns a class prefixed instance variable string }
function InstanceVarName (theClass: TObjectClass; ivar: string): string;
begin
	result := theClass.ClassName+'.'+ivar;
end;

{ Auto-released object transformed into another class by copying }
function Transform (obj: TObject; theClass: TClass): TObject;
begin
	result := TObject(obj.CopyOfClass(theClass).AutoRelease);
end;

{=============================================}
{@! ___CLASS MEMORY MANAGEMENT___ } 
{=============================================}

procedure InitializeObject (obj: TObject);
begin
	obj.Initialize;
end;

{ Allocates a class by name using the lookup table }
function AllocateClass (name: string): TObject;
var
	theClass: TObjectClass;
begin
		theClass := FindClass(name);
		if theClass <> nil then
			result := TObject(theClass.Allocate)
		else
			raise Exception.Create('The class "'+name+'" is not registered.');
end; 

{ Allocates a class by name using the lookup table with variable parameters (sent to InitializeParameter) }  
function AllocateClass (name: string; params: ParameterArray): TObject;
var
	theClass: TObjectClass;
	i: integer;
begin
		theClass := FindClass(name);
		if theClass <> nil then
			begin
				result := TObject(theClass.Allocate);
				for i := 0 to length(params) - 1 do
					result.InitializeParameter(i + 1, params[i]);
			end
		else
			raise Exception.Create('The class "'+name+'" is not registered.');
end; 

procedure ReleaseInterface (var io);
var
	obj: IObject absolute io;
begin
	if obj <> nil then
		obj.GetObject.Release;
	obj := nil;
end;

procedure ReleaseObject (var io); overload;
var
	obj: TObject absolute io;
begin
	if obj <> nil then
		obj.Release;
	obj := nil;
end;

procedure ReleaseObjects (objects: array of const);
var
	i: integer;
begin
	for i := 0 to System.high(objects) do
	case objects[i].vtype of
     vtObject:
     	ReleaseObject(objects[i].VObject);
   	otherwise
       Fatal('ReleaseObjects argument value type '+IntToStr(objects[i].vtype)+' is not an object.');
	end;
end;

procedure RetainInterface (var io; newObject: IObject);
var
	obj: IObject absolute io;
begin
	if obj <> nil then
		obj.GetObject.Release;
	
	if newObject <> nil then
		begin
			obj := newObject;
			obj.GetObject.Retain;
		end
	else
		obj := nil;
end;

procedure RetainObject (var io; newObject: TObject); overload;
var
	obj: TObject absolute io;
begin
	if obj <> nil then
		obj.Release;
	
	if newObject <> nil then
		begin
			obj := newObject;
			obj.Retain;
		end
	else
		obj := nil;
end;

procedure CopyObject (var io; newObject: TObject); overload;
var
	obj: TObject absolute io;
begin
	if obj <> nil then
		obj.Release;
	
	if newObject <> nil then
		obj := newObject.Copy
	else
		obj := nil;
end;

{=============================================}
{@! ___TOBJECT___ } 
{=============================================}

{ Invokes a method directly by function pointer }
function TObject.InvokeMethod (method: Pointer; params: Pointer = nil): Pointer;
begin
	if params <> nil then
		result := CallPointerMethod(method, self, params)
	else
		result := CallVoidMethod(method, self);
end;

{ Invokes a method by name with parameter }
function TObject.InvokeMethod (name: string; params: Pointer = nil): Pointer;
var
	method: Pointer;
	msg: TDispatchMessage;
begin
	method := FindMethod(name);
	if method <> nil then
		result := InvokeMethod(method, params)
	else
		begin
			msg.method := name;
			msg.params := params;
			DispatchStr(msg);
			result := nil;
		end;
end;

procedure TObject.DefaultHandlerStr (var message);
begin
	//writeln('Warning: the method ', TDispatchMessage(message).method, ' could not be found in ', ClassName, '.');
end;

function TObject.IsMethodRegistered (name: string): boolean;
begin
	result := FindMethod(name) <> nil;
end;

function TObject.FindMethod (name: string): Pointer;
var
	pair: TNamedMethod;
begin
	result := nil;
	for pair in registeredMethods do
		if pair.name = name then
			exit(pair.func);
end;

procedure TObject.RegisterMethod (name: string; method: Pointer);
begin
	SetLength(registeredMethods, Length(registeredMethods) + 1);
	registeredMethods[High(registeredMethods)].name := name;
	registeredMethods[High(registeredMethods)].func := method;
end;

function TObject.GetDescription: string;
begin
	result := GetDebugString;
end;

function TObject.IsEqual (value: TObject): boolean;
begin
	result := value = self;
end;

function TObject.GetDebugString: string;
begin
	result := GetDebugString(false);
end;

function TObject.GetDebugString (advanced: boolean): string;
begin
	if not advanced then
		result := ClassName+' ('+HexStr(self)+')'
	else
		result := ClassName+' ('+HexStr(self)+') #'+IntToStr(GetRetainCount);
end;

function TObject.IsMember (ofClass: TObjectClass): boolean;
begin
	result := MemberOfClass(self, ofClass);
end;

function TObject.IsMember (ofClass: string): boolean;
begin
	result := MemberOfClass(self, ofClass);
end;

function TObject.IsMember (ofObject: TObject): boolean;
begin
	result := MemberOfClass(self, TObjectClass(ofObject.ClassType));
end;

procedure TObject.Show;
begin
	writeln(GetDescription);
end;

{ Creates the object by first initializing instance data }
constructor TObject.Create;
begin
	Initialize;
end;

{ Queries a named method for a boolean response (like an accessor method) }
function TObject.GetMethodResponse (name: string): boolean;
begin
	result := false;
end;

{ Sent from AllocateClass with un-typed indexed parameters }
procedure TObject.InitializeParameter (index: integer; value: ParameterType);
begin
end;

{ Override to assign instance variables to "self" from "clone" during copying }
procedure TObject.CopyInstanceVariables (clone: TObject);
begin
end;

{ Make a copy of the object by transforming it into another class type }
function TObject.CopyOfClass (theClass: TClass): TObject;
begin
	result := TObjectClass(theClass).Allocate;
	result.CopyInstanceVariables(self);
	result.Initialize;
end;

procedure TObject.SetCopyParameters (newValue: pointer); 
begin
	copyParameters := newValue;
end;

function TObject.GetCopyParameters: pointer;
begin
	result := copyParameters;
end;

{ Returns true if the object was initialized from a copy operation }
function TObject.DidInitializeFromCopying: boolean;
begin
	result := initializedFromCopying;
end;

{ Make a copy of the object }
function TObject.Copy (params: pointer): TObject;
begin
	result := TObjectClass(ClassType).Allocate;
	result.initializedFromCopying := true;
	if params <> nil then
		result.copyParameters := params;
	result.CopyInstanceVariables(self);
	result.Initialize;
end;

function TObject.Copy: TObject;
begin
	result := Copy(nil);
end;

{ Creates an auto-released instance with initialization }
constructor TObject.Instance;
begin
	Initialize;
	AutoRelease;
end;

constructor TObject.WeakInstance;
begin
	Initialize;
	retainCount := 0;
end;

{ Allocates the object with no initialization }
constructor TObject.Allocate;
begin
	retainCount := 1;
	
	//if ShowNotes then
	//	writeln('* alloc ', GetDebugString(true));
end;

{ Peforms any initialization before the object is created }
procedure TObject.Initialize;
begin
	retainCount := 1;
	didInitialize := true;
	//if ShowNotes then
	//	writeln('* init ', GetDebugString(true));
end;

{ Initializes an object and performs a check to prevent double-initialization }
{ Use this method in constructors to initialize objects that may be allocated from archives }
procedure TObject.RequestInitialization;
begin
	if not didInitialize then
		Initialize;
end;

function TObject.ManageObject (obj: TObject): TObject;
begin
	SetLength(managedObjects, Length(managedObjects) + 1);
	managedObjects[High(managedObjects)] := obj;
	result := obj.Retain;
end;

procedure TObject.ManageObject (src: TObject; out obj);
var
	newObj: TObject absolute obj;
begin
	newObj := ManageObject(src);
end;

procedure TObject.ManageObject (theClass: TObjectClass; out obj);
var
	newObj: TObject absolute obj;
begin
	newObj := theClass.Create;
	ManageObject(newObj);
	newObj.Release;
end;

procedure TObject.RemoveFromAutoRelease;
begin
	autoReleaseCount -= 1;
	//writeln(GetDebugString, ': ', autoReleaseCount);
end;

function TObject.AutoRelease: TObject;
begin
	Fatal(GlobalAutoReleasePool = nil, 'Global autorelease pool hasn''t been registered.');
	Fatal(IsAutoReleasing, 'Double auto-releasing an object '+GetDebugString);
	Fatal(GetCurrentThreadID <> GetMainThreadID, 'Auto releasing outside of main thread.');
	
	autoReleaseCount += 1;
	GlobalAutoReleasePool.AddObject(self);
	
	// release now since the autorelease pool retains us
	Release;
	
	result := self;
end;

{ Deallocate the object when the retain count is 0 }
procedure TObject.Deallocate;
var
	i: integer;
begin
	//writeln(ClassName, '.Deallocate');
	
	//if retainCount > 0 then
	if retainCount > 0 then
		Fatal('Deallocating an object ('+GetDebugString+') with positive retain count.');
	if IsAutoReleasing then
		Fatal('Manually releasing an object ('+GetDebugString+') in the auto-release table!');
	
	//if ShowNotes then
	//	writeln('* deallocate ', GetDebugString);
	
	// release managed objects
	for i := 0 to length(managedObjects) - 1 do
		managedObjects[i].Release;
	
	Free;
end;

function TObject.GetRetainCount: integer;
begin
	result := retainCount;
end;

{ NOTE: This is a special usage method for objects that wrap other objects/types that maintain their own memory model }
{ This should never be called unless wrapping such types with external memory managament. }
procedure TObject.SetRetainCount (newValue: integer);
begin
	retainCount := newValue;
end;

{ Increase the retain count }
function TObject.Retain: TObject;
begin
	retainCount += 1;
	//if ShowNotes then
	//	writeln('* retain ', GetDebugString(true), retainCount);
	result := self;
end;

{ Decrease the retain count and deallocate if needed }
procedure TObject.Release;
begin 
	if not didInitialize then
		Fatal('Object '+ClassName+' wasn''t initialized before being released.');
	retainCount -= 1;

	//if ShowNotes then
	//	writeln('* release ', GetDebugString(true), ': ', retainCount);
		
	if retainCount <= 0 then
		Deallocate;
end;

function TObject.IsAutoReleasing: boolean;
begin
	result := autoReleaseCount > 0;
end;

function TObject.ShowNotes: boolean;
var
	index: integer;
begin
	if not ShowMemoryNotes then
		begin
			result := false;
			exit;
		end;
		
	result := true;
	for index := 1 to kIgnoreClassesCount do
		if IgnoreClasses[index] = ClassName then
			begin
				result := false;
				exit;
			end;
end;

function TObject.GetObject: TObject;
begin
	result := self;
end;

function TObject.GetInterface (uuid: InterfaceUUID): IObject;
begin
	result := nil;
end;

class procedure TObject.RegisterAutoReleasePool (pool: TAutoReleasePoolProtocol);
begin
	pool.Retain;
	AutoReleasePoolStack.AddValue(pool);
end;

begin
	AutoReleasePoolStack := TAutoReleasePoolArray.Make(8);
	RegisterClass(TObject);
end.