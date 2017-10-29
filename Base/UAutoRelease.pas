{$mode objfpc}

unit UAutoRelease;
interface
uses
	SysUtils, UArray, UObject;

const
	kAutoReleasePoolDrainMaximum = 1024;	// Maximum number of objects to drain per pass

type
	AutoReleasePoolDrainHandler = procedure (context: pointer);

type
	TAutoReleasePool = class (TAutoReleasePoolProtocol)
		public
			class procedure RegisterDrainHandler (handler: AutoReleasePoolDrainHandler; context: pointer);
			
			procedure AddObject (obj: TObject); override;
			procedure Drain; override;
		protected
			procedure Initialize; override;
			procedure Deallocate; override;
		private
			objects: TArray;
	end;

implementation

var
	GlobalDrainHandler: AutoReleasePoolDrainHandler = nil;
	GlobalDrainHandlerContext: Pointer = nil;

class procedure TAutoReleasePool.RegisterDrainHandler (handler: AutoReleasePoolDrainHandler; context: pointer);
begin
	GlobalDrainHandler := handler;
	GlobalDrainHandlerContext := context;
	TAutoReleasePool.Create;
end;

procedure TAutoReleasePool.AddObject (obj: TObject);
begin
	// invoke handler the first time an object is added
	if (objects.Count = 0) and (GlobalDrainHandler <> nil) then
		GlobalDrainHandler(GlobalDrainHandlerContext);
	objects.AddValue(obj);
end;

procedure TAutoReleasePool.Drain;
var
	obj: TObject;
	i, max: integer;
begin
	if objects.Count > 0 then
		begin
			// NOTE: I can't figure out how to make this work efficiently
			{max := objects.Count;
			if max > kAutoReleasePoolDrainMaximum then
				max := kAutoReleasePoolDrainMaximum;
			for i := 0 to max - 1 do
				begin
					obj := objects.GetValue(i);
					obj.RemoveFromAutoRelease;
				end;
			objects.RemoveValuesInRange(0, max - 1);}
			//writeln('drain ', objects.Count);
			for pointer(obj) in objects do
				obj.RemoveFromAutoRelease;
			objects.RemoveAllValues;
		end;
end;

procedure TAutoReleasePool.Initialize;
begin
	inherited Initialize;
	
	objects := TArray.Create;
	TObject.RegisterAutoReleasePool(self);
end;

procedure TAutoReleasePool.Deallocate;
begin
	Drain;
	objects.Release;
	
	inherited Deallocate;
end;

end.