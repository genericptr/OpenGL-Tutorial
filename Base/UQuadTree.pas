{$mode objfpc}

unit UQuadTree;
interface
uses
	SysUtils, UGeometry, UArray, UObject;

// http://www.kyleschouviller.com/wsuxna/quadtree-source-included/
// http://www.codeproject.com/Articles/30535/A-Simple-QuadTree-Implementation-in-C		
const
	IQuadTreeItemUUID = 917682322;
	
type
	TQuadTreeNode = class;
	
	IQuadTreeItem = interface (IObject) ['IQuadTreeItem']
		function GetPositioningFrame (root: TQuadTreeNode): TRect;
		procedure SetNode (root: TQuadTreeNode; newValue: TQuadTreeNode);
		function GetNode (root: TQuadTreeNode): TQuadTreeNode;
	end;
	
	TQuadTreeItem = IQuadTreeItem;

	TQuadTreeQueryCallback = function (item: TObject; context: pointer): boolean;
	TQuadTreeQueryRawCallback = procedure (rect: TRect; item: TObject; context: pointer; var stop: boolean);

	TQuadTreeNode = class (TObject)
		public
			{ Constructors }
			constructor Create (size: TSize; _maxItems: integer = 1);
			
			{ Accessors }
			procedure SetSize (newValue: TSize);
			
			function GetParent: TQuadTreeNode;
			function GetRoot: TQuadTreeNode;
			function GetFrame: TRect;
			
			function IsPartitioned: boolean;
			
			{ Methods }
			procedure Insert (item: TQuadTreeItem);
			procedure RemoveItem (item: TQuadTreeItem);
			procedure MoveItem (item: TQuadTreeItem);
			procedure RemoveAll;
			
			{ Querying }
			procedure Query (rect: TRect; var outItems: TPointerArray); overload;
			procedure Query (rect: TRect; callback: TQuadTreeQueryCallback; context: pointer; var outItems: TPointerArray); overload;
			procedure Query (rect: TRect; callback: TQuadTreeQueryRawCallback; context: pointer); overload;
			
			procedure GetAllItems (var outItems: TPointerArray);
			function FindItemNode (item: TQuadTreeItem): TQuadTreeNode;

			{ Other }
			function ContainsRect (rect: TRect): boolean;
			procedure Resize (newSize: TSize);
			
			//procedure Draw (context: CGContextRef);
			
		protected
			procedure Initialize; override;
			procedure Deallocate; override;
		private
			parent: TQuadTreeNode;
			root: TQuadTreeNode;
			topLeftNode: TQuadTreeNode;
			topRightNode: TQuadTreeNode;
			bottomLeftNode: TQuadTreeNode;
			bottomRightNode: TQuadTreeNode;
			items: TArray;
			frame: TRect;
			partitioned: boolean;
			maxItems: integer;
			
			constructor Create (_parent: TQuadTreeNode; _frame: TRect; _maxItems: integer);
			procedure QueryRaw (rect: TRect; callback: TQuadTreeQueryRawCallback; context: pointer; var stop: boolean);
			
			procedure RemoveItemAtIndex (index: integer);
			procedure Partition;
			function InsertInChild (item: TQuadTreeItem): boolean;
			function PushItemDown (index: integer): boolean;
			procedure PushItemUp (index: integer);
	end;

implementation

procedure TQuadTreeNode.SetSize (newValue: TSize);
begin		
	frame := RectMake(0, 0, newValue.width, newValue.height);
end;

function TQuadTreeNode.GetParent: TQuadTreeNode;
begin
	result := parent;
end;

function TQuadTreeNode.GetRoot: TQuadTreeNode;
begin
	result := root;
end;

function TQuadTreeNode.GetFrame: TRect;
begin
	result := frame;
end;

function TQuadTreeNode.IsPartitioned: boolean;
begin
	result := partitioned;
end;

function TQuadTreeNode.InsertInChild (item: TQuadTreeItem): boolean;
var
	rect: TRect;
begin
	if not IsPartitioned then
		exit(false);
	
	rect := item.GetPositioningFrame(GetRoot);
	
	//writeln('InsertInChild: ', rect.str, ' item=', item.GetObject.ClassName);
	//Fatal(rect.IsEmpty, 'The positioning frame for the node is empty');
	if rect.IsEmpty then
		exit(false);
		
	if topLeftNode.ContainsRect(rect) then
		topLeftNode.Insert(item)
	else if topRightNode.ContainsRect(rect) then
		topRightNode.Insert(item)
	else if bottomLeftNode.ContainsRect(rect) then
		bottomLeftNode.Insert(item)
	else if bottomRightNode.ContainsRect(rect) then
		bottomRightNode.Insert(item)
	else
		exit(false);
	
	result := true;
end;

procedure TQuadTreeNode.Insert (item: TQuadTreeItem);
begin		
	// If partitioned, try to find child node to add to
	if not InsertInChild(item) then
		begin
			item.SetNode(GetRoot, self);			
			items.AddValue(item.GetObject);
			
			// Check if this node needs to be partitioned
	    if not IsPartitioned and (items.Count >= maxItems) then
				Partition;
		end;
end;

function TQuadTreeNode.PushItemDown (index: integer): boolean;
begin
	if InsertInChild(IQuadTreeItem(items.GetValue(index).GetInterface(IQuadTreeItemUUID))) then
		begin
			RemoveItemAtIndex(index);
			result := true;
		end
	else
		result := false;
end;

procedure TQuadTreeNode.PushItemUp (index: integer);
var
	item: TObject;
begin
	item := TObject(items.GetValue(index));
	item.Retain;
  RemoveItemAtIndex(index);
  parent.Insert(IQuadTreeItem(item.GetInterface(IQuadTreeItemUUID)));
	item.Release;
end;

procedure TQuadTreeNode.Partition;
var
	i: integer = 0;
begin
	Fatal(frame.size.IsZero, 'Quad tree trying to partition empty node f='+frame.str);

	topLeftNode := TQuadTreeNode.Create(self, RectMake(RectMinX(frame), RectMinY(frame), RectWidth(frame) / 2, RectHeight(frame) / 2), maxItems);
	topRightNode := TQuadTreeNode.Create(self, RectMake(RectMidX(frame), RectMinY(frame), RectWidth(frame) / 2, RectHeight(frame) / 2), maxItems);
	bottomLeftNode := TQuadTreeNode.Create(self, RectMake(RectMinX(frame), RectMidY(frame), RectWidth(frame) / 2, RectHeight(frame) / 2), maxItems);
	bottomRightNode := TQuadTreeNode.Create(self, RectMake(RectMidX(frame), RectMidY(frame), RectWidth(frame) / 2, RectHeight(frame) / 2), maxItems);
	
	partitioned := true;
	
	while i < items.Count do
		if not PushItemDown(i) then
			i += 1;
end;

procedure TQuadTreeNode.RemoveItem (item: TQuadTreeItem);
var
	index: TArrayIndex;
begin	
	index := items.GetIndexOfValue(item.GetObject);
	if index <> kArrayInvalidIndex then
		begin
			item.SetNode(GetRoot, nil);
			items.RemoveIndex(index);
		end;
end;

procedure TQuadTreeNode.RemoveItemAtIndex (index: integer);
begin
	if (index >= 0) and (index < items.Count) then
		items.RemoveIndex(index);
end;

procedure TQuadTreeNode.MoveItem (item: TQuadTreeItem);
var
	index: integer;
	rect: TRect;
begin
	index := items.GetIndexOfValue(item.GetObject);
	if index <> kArrayInvalidIndex then
		begin			
			
			// Try to push the item down to the child
			if not PushItemDown(index) then
				begin
					// otherwise, if not root, push up
					if parent <> nil then
						PushItemUp(index)
					else
						begin
							// NOTE: this is called if a sprite goes outside the root frame
							{rect := item.GetPositioningFrame(GetRoot);
							if not ContainsRect(rect) then
								begin
									Fatal('resize world to contain '+rect.str+' in '+frame.str);
								end;}
						end;
				end;
		end;
end;

procedure TQuadTreeNode.Query (rect: TRect; var outItems: TPointerArray);
begin
	Query(rect, nil, nil, outItems);
end;

procedure TQuadTreeNode.QueryRaw (rect: TRect; callback: TQuadTreeQueryRawCallback; context: pointer; var stop: boolean);
var
	item: TObject;
	itemRect: TRect;
	emptyRect: boolean;
	i: TArrayIndex;
begin
	emptyRect := rect.IsEmpty;
	
	if emptyRect or frame.IntersectsRect(rect) then
		begin
			for i := 0 to items.High do
				begin
					callback(rect, items.GetValue(i), context, stop);
					if stop then
						exit;
				end;

			// query all subtrees
			if IsPartitioned then
				begin
					topLeftNode.QueryRaw(rect, callback, context, stop);
					if stop then
						exit;
					topRightNode.QueryRaw(rect, callback, context, stop);
					if stop then
						exit;
					bottomLeftNode.QueryRaw(rect, callback, context, stop);
					if stop then
						exit;
					bottomRightNode.QueryRaw(rect, callback, context, stop);
				end;
		end;
end;

procedure TQuadTreeNode.Query (rect: TRect; callback: TQuadTreeQueryRawCallback; context: pointer);
var
	stop: boolean = false;
begin
	QueryRaw(rect, callback, context, stop);
end;

procedure TQuadTreeNode.Query (rect: TRect; callback: TQuadTreeQueryCallback; context: pointer; var outItems: TPointerArray);
var
	item: TObject;
	itemRect: TRect;
	emptyRect: boolean;
	i: TArrayIndex;
begin
	emptyRect := rect.IsEmpty;
	//writeln('quad: ', frame.str, ' items=', items.count);
	
	if emptyRect or frame.IntersectsRect(rect) then
		begin
			for i := 0 to items.High do
				begin
					item := items.Values[i];
					itemRect := TQuadTreeItem(item.GetInterface(IQuadTreeItemUUID)).GetPositioningFrame(GetRoot);						
					if emptyRect or itemRect.IntersectsRect(rect) then
						begin
							if callback <> nil then
								begin
									if callback(item, context) then
										begin
											if outItems = nil then
												outItems := TPointerArray.Instance;
											outItems.AddValue(item);
										end;
								end
							else
								begin
									if outItems = nil then
										outItems := TPointerArray.Instance;
									outItems.AddValue(item);
								end;
						end;
				end;

			// query all subtrees
			if IsPartitioned then
				begin
					topLeftNode.Query(rect, callback, context, outItems);
					topRightNode.Query(rect, callback, context, outItems);
					bottomLeftNode.Query(rect, callback, context, outItems);
					bottomRightNode.Query(rect, callback, context, outItems);
				end;
		end;
end;

procedure TQuadTreeNode.GetAllItems (var outItems: TPointerArray);
begin
	if outItems = nil then
		outItems := TPointerArray.Instance;
	
	outItems.AddValuesFromArray(TPointerArray(items));
	
	// query all subtrees
	if IsPartitioned then
		begin
			topLeftNode.GetAllItems(outItems);
      topRightNode.GetAllItems(outItems);
      bottomLeftNode.GetAllItems(outItems);
      bottomRightNode.GetAllItems(outItems);
		end;
end;

function TQuadTreeNode.FindItemNode (item: TQuadTreeItem): TQuadTreeNode;			
var
	node: TQuadTreeNode = nil;
	rect: TRect;
begin
	if items.ContainsValue(item.GetObject) then
		exit(self);
	
	if IsPartitioned then
		begin
			rect := item.GetPositioningFrame(GetRoot);
			
			if topLeftNode.ContainsRect(rect) then
			 	node := topLeftNode.FindItemNode(item)
			else if topRightNode.ContainsRect(rect) then
			 	node := topRightNode.FindItemNode(item)
      else if bottomLeftNode.ContainsRect(rect) then
			 	node := bottomLeftNode.FindItemNode(item)
			else if bottomRightNode.ContainsRect(rect) then
			 	node := bottomRightNode.FindItemNode(item)
			else
				result := nil;
		end
	else
		result := nil;
end;

function TQuadTreeNode.ContainsRect (rect: TRect): boolean;
begin
	result := RectContainsRect(frame, rect);
end;

procedure TQuadTreeNode.Resize (newSize: TSize);
var
	tmp: TArray;
	item: TQuadTreeNode; 
begin
	Fatal(parent <> nil, 'Resize can only be called on root node.');
	// retain all items from root node
	tmp := TArray.Create;
	GetAllItems(TPointerArray(tmp));
	SetSize(newSize);
	RemoveAll;
	for pointer(item) in tmp do
		Insert(IQuadTreeItem(item.GetInterface(IQuadTreeItemUUID)));
	tmp.Release;
end;

procedure TQuadTreeNode.RemoveAll;
var
	item: TObject;
begin
	{for pointer(item) in items do
		begin
			item.SetNode(GetRoot, nil);
			item.Release;
		end;
	items.Reset;}
	// NOTE: we iterate twice over the array
	for pointer(item) in items do
		IQuadTreeItem(item.GetInterface(IQuadTreeItemUUID)).SetNode(GetRoot, nil);
	items.RemoveAllValues;
	
	if IsPartitioned then
		begin
			ReleaseObject(topLeftNode);
			ReleaseObject(topRightNode);
			ReleaseObject(bottomLeftNode);
			ReleaseObject(bottomRightNode);
			partitioned := false;
		end;
end;

procedure TQuadTreeNode.Initialize;
begin
	inherited Initialize;
	
	items := TArray.Create;
end;

procedure TQuadTreeNode.Deallocate;
begin
	RemoveAll;
	
	inherited Deallocate;
end;

constructor TQuadTreeNode.Create (_parent: TQuadTreeNode; _frame: TRect; _maxItems: integer);
begin
	root := _parent.GetRoot;
	parent := _parent;
	frame := _frame;
	maxItems := _maxItems;
	//writeln('new node ', frame.str, ' of ', parent.frame.str);
	Initialize;
end;

constructor TQuadTreeNode.Create (size: TSize; _maxItems: integer = 1);
begin
	root := self;
	parent := nil;
	frame := RectMake(0, 0, size.width, size.height);
	maxItems := _maxItems;
	Initialize;
end;

end.