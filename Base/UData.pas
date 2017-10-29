{$mode objfpc}

unit UData;
interface
uses
	SysUtils, UObject;

type
	TData = class (TObject)
		public
			
			{ Constructors }
			constructor Create (_bytes: pointer; size: longint); overload;
			constructor Create (size: longint); overload;
			constructor Create (_bytes: pointer; _mutable: boolean);
			constructor Instance (_bytes: pointer; size: longint); overload;
			
			{ Accessors }
			function GetLength: longint;
			function GetPointer: pointer;
			
			{ Methods }
			procedure AddBytes (buffer: pointer; byteCount: longint); overload;
			procedure AddBytes (data: TData; offset: longint; byteCount: longint); overload;
			procedure Reset;
			
			procedure SetBytes (buffer: pointer; offset: longint; byteCount: longint);
			procedure GetBytes (buffer: pointer); overload;
			procedure GetBytes (buffer: pointer; byteCount: longint); overload;
			procedure GetBytes (buffer: pointer; offset: longint; byteCount: longint); overload;
			
			procedure Show; override;
			
		protected
			procedure Deallocate; override;
			procedure CopyInstanceVariables (clone: TObject); override;
		private
			bytes: pointer;
			mutableLength: boolean;
			currentLength: longint;
			
			procedure Resize (newSize: longint);
	end;

implementation

const
	kMutableIncrementSize = 8;

{=============================================}
{@! ___VALUE___ } 
{=============================================}
procedure TData.Reset;
begin
	if not mutableLength then
		raise Exception.Create('TData is not mutable.');
		
	currentLength := 0;
end;

procedure TData.AddBytes (data: TData; offset: longint; byteCount: longint);
var
	actualSize: longint;
begin
	if not mutableLength then
		raise Exception.Create('TData is not mutable.');
	
	actualSize := MemSize(bytes);
	
	if currentLength + byteCount >= actualSize then
		if byteCount < kMutableIncrementSize then
			Resize(actualSize + kMutableIncrementSize)
		else
			Resize(actualSize + byteCount);
		
	//SetBytes(data.GetPointer, GetLength, byteCount);
	
	Move(pointer(longint(data.GetPointer) + offset)^, pointer(longint(bytes) + GetLength)^, byteCount);
	
	currentLength += byteCount;
end;

procedure TData.AddBytes (buffer: pointer; byteCount: longint);
var
	actualSize: longint;
begin
	if not mutableLength then
		raise Exception.Create('TData is not mutable.');
	
	actualSize := MemSize(bytes);
	//writeln('add ', byteCount, ' bytes to ', currentLength, ' of ', actualSize);
	
	if currentLength + byteCount >= actualSize then
		if byteCount < kMutableIncrementSize then
			Resize(actualSize + kMutableIncrementSize)
		else
			Resize(actualSize + byteCount);
		
	SetBytes(buffer, GetLength, byteCount);
	currentLength += byteCount;
	//writeln('current length ', currentLength);
end;

procedure TData.Resize (newSize: longint);
begin
	//writeln('resize to ', newSize);
	ReAllocMem(bytes, newSize);
	//writeln('new size ', MemSize(bytes));
	
	// set the new actual size for non-mutable data
	if not mutableLength then
		currentLength := newSize;
end;

procedure TData.SetBytes (buffer: pointer; offset: longint; byteCount: longint);
begin
	if offset + byteCount >= MemSize(bytes) then
		raise Exception.Create('TData setting offset beyond bounds ('+IntToStr(offset + byteCount)+' > '+IntToStr(MemSize(bytes))+')')
	else
		Move(buffer^, pointer(longint(bytes) + offset)^, byteCount);
end;

function TData.GetLength: longint;
begin
	if mutableLength then
		result := currentLength
	else
		result := MemSize(bytes);
end;

function TData.GetPointer: pointer;
begin
	result := bytes;
end;

procedure TData.GetBytes (buffer: pointer);
begin
	Move(bytes^, buffer^, GetLength);
end;

procedure TData.GetBytes (buffer: pointer; byteCount: longint);
begin
	if byteCount > MemSize(bytes) then
		raise Exception.Create('TData getting byte count beyond bounds.');
	
	Move(bytes^, buffer^, byteCount);
end;

procedure TData.GetBytes (buffer: pointer; offset: longint; byteCount: longint);
begin
	if offset + byteCount > MemSize(bytes) then
		raise Exception.Create('TData getting offset beyond bounds.');
	
	Move(pointer(longint(bytes) + offset)^, buffer^, byteCount);
end;

constructor TData.Create (size: longint);
begin
	if size > 0 then
		bytes := GetMemory(size)
	else
		bytes := GetMemory(kMutableIncrementSize);
	mutableLength := true;
	currentLength := 0;
	Initialize;
end;

constructor TData.Create (_bytes: pointer; size: longint);
begin
	bytes := GetMemory(size);
	Move(_bytes^, bytes^, size);
	mutableLength := false;
	Initialize;
end;

constructor TData.Create (_bytes: pointer; _mutable: boolean);
begin
	bytes := _bytes;
	mutableLength := _mutable;
	currentLength := 0;
	Initialize;
end;

constructor TData.Instance (_bytes: pointer; size: longint);	
begin
	Create(_bytes, size);
	AutoRelease;
end;

procedure TData.Show;
begin
	writeln(ClassName,': ',HexStr(self), ' (', GetLength, ' bytes)');
end;

procedure TData.CopyInstanceVariables (clone: TObject);
var
	data: TData;
begin
	inherited CopyInstanceVariables(clone);
	
	data := TData(clone);
	
	bytes := GetMemory(data.GetLength);
	Move(data.bytes^, bytes^, MemSize(bytes));
end;

procedure TData.Deallocate;
begin
	FreeMemory(bytes);
	inherited Deallocate;
end;

begin
	RegisterClass(TData);
end.