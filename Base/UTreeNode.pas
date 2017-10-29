{$mode objfpc}

unit UTreeNode;
interface
uses
	UArray, UObject;

type
	TTreeNode = class (TObject)
		public
			{ Accessors }
			function GetParent: TTreeNode;
			function GetChildren: TArray;
			function GetChildrenIncludingSelf: TArray;
			function GetChild (index: integer): TTreeNode;
			function GetIndex: integer;
			function GetAllChildren: TArray;
			function GetAllChildrenIncludingSelf: TArray;
			function GetRoot: TTreeNode;
			
			function IsRoot: boolean;
			
			{ State }
			procedure SetExpanded (newValue: boolean);
			function IsExpanded: boolean;
			function IsExpandable: boolean;
			
			{ Methods }
			function ChildCount: integer;
			function HasChildren: boolean;
			procedure AddChild (child: TTreeNode);
			procedure InsertChild (child: TTreeNode; index: integer); overload;
			procedure InsertChild (child: TTreeNode; index: integer; respectArrayBounds: boolean); overload;
			procedure InsertChildBefore (child: TTreeNode);
			procedure InsertChildAfter (child: TTreeNode);
			procedure RemoveChild (child: TTreeNode); overload;
			procedure RemoveChild (index: integer); overload;
			procedure RemoveAllChildren;
			procedure RemoveFromParent;
			function ContainsChild (child: TTreeNode; deep: boolean): boolean;
			procedure ShowAll;
			
		protected
			procedure Initialize; override;
			procedure Deallocate; override;
			procedure CopyInstanceVariables (clone: TObject); override;
			
			{ Notifications }
			procedure HandleParentChanged; virtual;
			procedure HandleChildrenChanged; virtual;
			procedure HandleExpandStateChanged; virtual;
			
		private
			parent: TTreeNode;
			children: TArray;
			expanded: boolean;
			
			procedure Show (indent: string); overload;
			procedure GetChildrenRecursive (var list: TArray);
			procedure SetParent (newValue: TTreeNode);
	end;

implementation

procedure TTreeNode.ShowAll;
begin
	Show('');
end;

procedure TTreeNode.Show (indent: string);
var
	node: TTreeNode;
begin
	write(indent);
	Show;
	for pointer(node) in children do
		node.Show(indent+'  ');
end;

procedure TTreeNode.SetExpanded (newValue: boolean);
var
	changed: boolean;
begin
	changed := expanded <> newValue;
	expanded := newValue;
	if changed then
		HandleExpandStateChanged;
end;

function TTreeNode.GetParent: TTreeNode;
begin
	result := parent;
end;

function TTreeNode.GetChildren: TArray;
begin
	result := children;
end;

function TTreeNode.GetChildrenIncludingSelf: TArray;
begin
	result := TArray(children.Copy.AutoRelease);
	result.AddValue(self);
end;

function TTreeNode.GetChild (index: integer): TTreeNode;
begin
	result := TTreeNode(children.GetValue(index));
end;

function TTreeNode.ChildCount: integer;
begin
	result := children.Count;
end;

function TTreeNode.HasChildren: boolean;
begin
	result := children.Count > 0;
end;

function TTreeNode.GetIndex: integer;
var
	i: integer;
	node: TTreeNode;
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

procedure TTreeNode.GetChildrenRecursive (var list: TArray);
var
	child: TTreeNode;
begin	
	for pointer(child) in children do
		begin
			list.AddValue(child);
			child.GetChildrenRecursive(list);
		end;
end;

function TTreeNode.GetAllChildren: TArray;
begin
	result := TArray.Instance;
	GetChildrenRecursive(result);
end;

function TTreeNode.GetRoot: TTreeNode;
var
	node: TTreeNode;
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

function TTreeNode.GetAllChildrenIncludingSelf: TArray;
begin
	result := GetAllChildren;
	result.InsertValue(self, 0);
end;

function TTreeNode.IsExpanded: boolean;
begin
	result := expanded;
end;

function TTreeNode.IsExpandable: boolean;
begin
	if children <> nil then
		result := children.Count > 0
	else
		result := false;
end;

function TTreeNode.IsRoot: boolean;
begin
	result := parent = nil;
end;

procedure TTreeNode.SetParent (newValue: TTreeNode);
var
	changed: boolean;
begin
	changed := parent <> newValue;
	parent := newValue;
	if changed then
		HandleParentChanged;
end;

procedure TTreeNode.AddChild (child: TTreeNode);
begin
	child.SetParent(self);
	children.AddValue(child);
	HandleChildrenChanged;
end;

procedure TTreeNode.InsertChildBefore (child: TTreeNode);
begin
	if GetParent <> nil then
		parent.InsertChild(child, GetIndex)
	else
		AddChild(child);
end;

procedure TTreeNode.InsertChildAfter (child: TTreeNode);
begin
	if GetParent <> nil then
		parent.InsertChild(child, GetIndex + 1)
	else
		AddChild(child);
end;

procedure TTreeNode.InsertChild (child: TTreeNode; index: integer);
begin
	InsertChild(child, index, true);
end;

procedure TTreeNode.InsertChild (child: TTreeNode; index: integer; respectArrayBounds: boolean);
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

procedure TTreeNode.RemoveChild (child: TTreeNode);
begin
	child.SetParent(nil);
	children.RemoveFirstValue(child);
	HandleChildrenChanged;
end;

procedure TTreeNode.RemoveAllChildren;
var
	child: TTreeNode;
begin
	for pointer(child) in children do
		child.SetParent(nil);
	children.RemoveAllValues;
	HandleChildrenChanged;
end;

procedure TTreeNode.RemoveFromParent;
begin
	if parent <> nil then
		parent.RemoveChild(self);
end;

function TTreeNode.ContainsChild (child: TTreeNode; deep: boolean): boolean;
var
	_child: TTreeNode;
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

procedure TTreeNode.RemoveChild (index: integer);
var
	child: TTreeNode;
begin
	child := GetChild(index);
	child.SetParent(nil);
	children.RemoveIndex(index);
end;

procedure TTreeNode.HandleParentChanged;
begin
end;

procedure TTreeNode.HandleChildrenChanged;
begin
end;

procedure TTreeNode.HandleExpandStateChanged;
begin
end;

procedure TTreeNode.CopyInstanceVariables (clone: TObject);
var
	node: TTreeNode;
begin
	inherited CopyInstanceVariables(clone);
	
	node := TTreeNode(clone);
	
	parent := node.parent;
	children := TArray(node.children.Copy);
	expanded := node.expanded;
end;

procedure TTreeNode.Initialize;
begin
	inherited Initialize;
	
	if children = nil then
		children := TArray.Create;
end;

procedure TTreeNode.Deallocate;
begin
	children.Release;
	
	inherited Deallocate;
end;

end.