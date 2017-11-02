{$mode objfpc}

unit UTreeNode;
interface
uses
	UArray, UObject;

type
	generic TGenericTreeNode<T> = class (TObject)
		private
			m_value: T;
		public			
			
			{ Constructors }
			constructor Create (inValue: T); overload;

			{ Accessors }
			function GetParent: TGenericTreeNode;
			function GetChildren: TArray;
			function GetChildrenIncludingSelf: TArray;
			function GetChild (index: integer): TGenericTreeNode;
			function GetIndex: integer;
			function GetAllChildren: TArray;
			function GetAllChildrenIncludingSelf: TArray;
			function GetRoot: TGenericTreeNode;
			
			function IsRoot: boolean;
			
			procedure SetValue (newValue: T);
			property Value: T read m_value write SetValue;
			
			{ Methods }
			function ChildCount: integer; inline;
			function HasChildren: boolean; inline;
			procedure AddChild (child: TGenericTreeNode);
			procedure InsertChild (child: TGenericTreeNode; index: integer); overload;
			procedure InsertChild (child: TGenericTreeNode; index: integer; respectArrayBounds: boolean); overload;
			procedure InsertChildBefore (child: TGenericTreeNode);
			procedure InsertChildAfter (child: TGenericTreeNode);
			procedure RemoveChild (child: TGenericTreeNode); overload;
			procedure RemoveChild (index: integer); overload;
			procedure RemoveAllChildren;
			procedure RemoveFromParent;
			function ContainsChild (child: TGenericTreeNode; deep: boolean): boolean;
			procedure ShowAll;
			
		protected
			procedure Initialize; override;
			procedure Deallocate; override;
			procedure CopyInstanceVariables (clone: TObject); override;
			
			{ Notifications }
			procedure HandleParentChanged; virtual;
			procedure HandleChildrenChanged; virtual;
			
		private
			parent: TGenericTreeNode;
			children: TArray;
			
			procedure Show (indent: string); overload;
			procedure GetChildrenRecursive (var list: TArray);
			procedure SetParent (newValue: TGenericTreeNode);
	end;
	TTreeNode = specialize TGenericTreeNode<TObject>;
	
implementation

procedure TGenericTreeNode.ShowAll;
begin
	Show('');
end;

procedure TGenericTreeNode.Show (indent: string);
var
	node: TGenericTreeNode;
begin
	write(indent);
	Show;
	for pointer(node) in children do
		node.Show(indent+'  ');
end;

function TGenericTreeNode.GetParent: TGenericTreeNode;
begin
	result := parent;
end;

function TGenericTreeNode.GetChildren: TArray;
begin
	result := children;
end;

function TGenericTreeNode.GetChildrenIncludingSelf: TArray;
begin
	result := TArray(children.Copy.AutoRelease);
	result.AddValue(self);
end;

function TGenericTreeNode.GetChild (index: integer): TGenericTreeNode;
begin
	result := TGenericTreeNode(children.GetValue(index));
end;

function TGenericTreeNode.ChildCount: integer;
begin
	if children <> nil then
		result := children.Count
	else
		result := 0;
end;

function TGenericTreeNode.HasChildren: boolean;
begin
	result := ChildCount > 0;
end;

function TGenericTreeNode.GetIndex: integer;
var
	i: integer;
	node: TGenericTreeNode;
begin

	// return -1 for root
	if parent = nil then
		exit(-1);
	
	result := 0;
	
	for i := 0 to parent.ChildCount - 1 do
		begin
			node := parent.GetChild(i);
			if node = self then
				exit(i);
		end;
end;

procedure TGenericTreeNode.GetChildrenRecursive (var list: TArray);
var
	child: TGenericTreeNode;
begin	
	for pointer(child) in children do
		begin
			list.AddValue(child);
			child.GetChildrenRecursive(list);
		end;
end;

function TGenericTreeNode.GetAllChildren: TArray;
begin
	result := TArray.Instance;
	GetChildrenRecursive(result);
end;

function TGenericTreeNode.GetRoot: TGenericTreeNode;
var
	node: TGenericTreeNode;
begin
	if GetParent = nil then
		exit(self);
	node := self;
	while true do
		begin
			if node.GetParent = nil then
				exit(node);
			node := node.GetParent;
		end;
	result := node;
end;

function TGenericTreeNode.GetAllChildrenIncludingSelf: TArray;
begin
	result := GetAllChildren;
	result.InsertValue(self, 0);
end;

procedure TGenericTreeNode.SetValue (newValue: T);
begin
	m_value := newValue;
end;

function TGenericTreeNode.IsRoot: boolean;
begin
	result := parent = nil;
end;

procedure TGenericTreeNode.SetParent (newValue: TGenericTreeNode);
var
	changed: boolean;
begin
	changed := parent <> newValue;
	parent := newValue;
	if changed then
		HandleParentChanged;
end;

procedure TGenericTreeNode.AddChild (child: TGenericTreeNode);
begin
	child.SetParent(self);
	children.AddValue(child);
	HandleChildrenChanged;
end;

procedure TGenericTreeNode.InsertChildBefore (child: TGenericTreeNode);
begin
	if GetParent <> nil then
		parent.InsertChild(child, GetIndex)
	else
		AddChild(child);
end;

procedure TGenericTreeNode.InsertChildAfter (child: TGenericTreeNode);
begin
	if GetParent <> nil then
		parent.InsertChild(child, GetIndex + 1)
	else
		AddChild(child);
end;

procedure TGenericTreeNode.InsertChild (child: TGenericTreeNode; index: integer);
begin
	InsertChild(child, index, true);
end;

procedure TGenericTreeNode.InsertChild (child: TGenericTreeNode; index: integer; respectArrayBounds: boolean);
begin
	child.SetParent(self);
	
	if respectArrayBounds then
		begin
			if index < 0 then
				children.AddValue(child)
			else if index >= children.Count then
				children.AddValue(child)
			else
				children.InsertValue(child, index);
		end
	else
		children.InsertValue(child, index);
	
	HandleChildrenChanged;
end;

procedure TGenericTreeNode.RemoveChild (child: TGenericTreeNode);
begin
	child.SetParent(nil);
	children.RemoveFirstValue(child);
	HandleChildrenChanged;
end;

procedure TGenericTreeNode.RemoveAllChildren;
var
	child: TGenericTreeNode;
begin
	for pointer(child) in children do
		child.SetParent(nil);
	children.RemoveAllValues;
	HandleChildrenChanged;
end;

procedure TGenericTreeNode.RemoveFromParent;
begin
	if parent <> nil then
		parent.RemoveChild(self);
end;

function TGenericTreeNode.ContainsChild (child: TGenericTreeNode; deep: boolean): boolean;
var
	_child: TGenericTreeNode;
begin
	if deep then
		begin
			result := false;
			for pointer(_child) in GetAllChildren do
				if _child = child then
					exit(true);
		end
	else
		result := children.ContainsValue(child);
end;

procedure TGenericTreeNode.RemoveChild (index: integer);
var
	child: TGenericTreeNode;
begin
	child := GetChild(index);
	child.SetParent(nil);
	children.RemoveIndex(index);
end;

procedure TGenericTreeNode.HandleParentChanged;
begin
end;

procedure TGenericTreeNode.HandleChildrenChanged;
begin
end;

procedure TGenericTreeNode.CopyInstanceVariables (clone: TObject);
var
	node: TGenericTreeNode;
begin
	inherited CopyInstanceVariables(clone);
	
	node := TGenericTreeNode(clone);
	
	parent := node.parent;
	children := TArray(node.children.Copy);
end;

procedure TGenericTreeNode.Initialize;
begin
	inherited Initialize;
	
	if children = nil then
		children := TArray.Create;
end;

procedure TGenericTreeNode.Deallocate;
begin
	children.Release;
	
	inherited Deallocate;
end;

constructor TGenericTreeNode.Create (inValue: T);
begin
	value := inValue;
	Initialize;
end;

end.