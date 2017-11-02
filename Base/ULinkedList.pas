{$mode objfpc}
{$interfaces CORBA}
{$modeswitch advancedrecords}

unit ULinkedList;
interface
uses
	UObject, TypInfo, SysUtils;

// http://docs.oracle.com/javase/7/docs/api/java/util/LinkedList.html
// https://stackoverflow.com/questions/18734705/which-one-runs-faster-arraylist-or-linkedlist?noredirect=1&lq=1
// http://www.thelearningpoint.net/computer-science/data-structures-doubly-linked-list-with-c-program-source-code
// http://cslibrary.stanford.edu/103/LinkedListBasics.pdf

type
	generic TGenericLinkedListNode<T> = class (TObject)
		private
			m_value: T;
			m_next: TGenericLinkedListNode;
			m_prev: TGenericLinkedListNode;
		private
			// TODO: finding class looked into the comment and will break with nested
			type
				TLinkedListEnumerator = record
					private
						root: TGenericLinkedListNode;
						currentNode: TGenericLinkedListNode;
						currentValue: T;
					public
						constructor Create(_root: TGenericLinkedListNode); 
						function MoveNext: Boolean;
						property Current: T read currentValue;
				end;
		protected
			procedure Deallocate; override;
		public
		
			{ Construcrors }
			constructor Create (newValue: T);
			
			{ Actions }
			function Insert (newValue: T): TGenericLinkedListNode;
			function Remove: TGenericLinkedListNode;
			procedure RemoveAll; 
			
			{ Methods }
			procedure Show; override;			
			function GetDescription: string; override;
			function GetEnumerator: TLinkedListEnumerator;

		private
			function IsDefault (theValue: T): boolean; inline;
			function IsRoot: boolean; inline;
			function TypeKind: TTypeKind; inline;
			
			procedure SetValue (newValue: T);
			procedure SetNext (newValue: TGenericLinkedListNode);
			procedure SetPrevious (newValue: TGenericLinkedListNode);
			
			property Next: TGenericLinkedListNode read m_next write SetNext;
			property Previous: TGenericLinkedListNode read m_prev write SetPrevious;
			property Value: T read m_value write SetValue;
	end;
	TLinkedListNode = specialize TGenericLinkedListNode<TObject>;
	TLinkedListStringNode = specialize TGenericLinkedListNode<String>;
	TLinkedListIntegerNode = specialize TGenericLinkedListNode<Integer>;
	
implementation

{=============================================}
{@! ___ENUMERATOR___ } 
{=============================================} 
constructor TGenericLinkedListNode.TLinkedListEnumerator.Create(_root: TGenericLinkedListNode);
begin
	root := _root;
	currentNode := root;
end;
	
function TGenericLinkedListNode.TLinkedListEnumerator.MoveNext: Boolean;
begin
	if currentNode = nil then
		exit(false);
	currentValue := currentNode.Value;
	currentNode := currentNode.next;
	result := true;
end;

{=============================================}
{@! ___LINKED LIST___ } 
{=============================================}

function TGenericLinkedListNode.GetEnumerator: TLinkedListEnumerator;
begin
	result := TLinkedListEnumerator.Create(self);
end;

function TGenericLinkedListNode.GetDescription: string; 
begin
	case typeKind of
		tkClass:
			begin
				if not IsDefault(value) then
					result := TObjectPtr(@value)^.GetDescription
				else
					result := 'nil';
			end;
		tkPointer:
			begin
				if not IsDefault(value) then
					result := HexStr(PPointer(@value)^)
				else
					result := 'nil';
			end;
		tkRecord:
			result := 'record';
		tkSString:
			writeln(PShortString(@value)^);
		otherwise
			result := IntToStr(PInteger(@value)^); // this is just a hack to print compiler types
	end;
end;

procedure TGenericLinkedListNode.Show;
begin
	writeln(GetDescription);
	if next <> nil then
		next.Show;
end;

function TGenericLinkedListNode.TypeKind: TTypeKind; 
begin
	result := PTypeInfo(TypeInfo(T))^.kind;
end;

function TGenericLinkedListNode.IsDefault (theValue: T): boolean;
begin
	result := theValue = Default(T);
end;

function TGenericLinkedListNode.IsRoot: boolean; 
begin
	result := previous = nil;
end;

procedure TGenericLinkedListNode.RemoveAll; 
begin				
	if next <> nil then
		begin
			next.RemoveAll;
			next := nil;
		end;	
	if previous <> nil then
		previous := nil;
end;

function TGenericLinkedListNode.Remove: TGenericLinkedListNode;
begin
	Fatal(previous = nil, 'can''t remove root node.');
	Retain;
	if previous <> nil then
		previous.next := next;
	if next <> nil then
		next.previous := previous;
	Release;
end;

function TGenericLinkedListNode.Insert (newValue: T): TGenericLinkedListNode;
var
	old: TGenericLinkedListNode = nil;
	newNode: TGenericLinkedListNode;
begin
	Fatal(next <> nil, 'Linked node already has child');
	
	newNode := TGenericLinkedListNode.Create(newValue);
	old := next;
	next := newNode;
	
	if old <> nil then
		old.previous := newNode;
	
	newNode.next := old;
	newNode.previous := self;

	newNode.Release;
	result := newNode;
end;

procedure TGenericLinkedListNode.SetValue (newValue: T);
var
	obj: TObject absolute newValue;
begin
	if typeKind = tkClass then
		begin
			if value <> Default(T) then
				obj.Retain
			else
				obj.Release;
		end;
	m_value := newValue;
end;

procedure TGenericLinkedListNode.SetNext (newValue: TGenericLinkedListNode);
begin
	RetainObject(m_next, newValue);
end;

procedure TGenericLinkedListNode.SetPrevious (newValue: TGenericLinkedListNode);
begin
	m_prev := newValue;
end;

procedure TGenericLinkedListNode.Deallocate;
begin
	//writeln('dealloc node: ', GetDescription);
	next := nil;
	previous := nil;
	inherited Deallocate;
end;

constructor TGenericLinkedListNode.Create (newValue: T);
begin
	value := newValue;
	Initialize;
end;

end.