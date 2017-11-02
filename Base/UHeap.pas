{$mode objfpc}
{$interfaces CORBA}

unit UHeap;
interface
uses
	UArray, UObject, UValue, SysUtils, Math;

const
	IHeapItemUUID = 177997573;
	
type
	THeap = class;
	
	IHeapItem = interface (IObject) ['IHeapItem']
		function GetHeapIndex (heap: THeap): integer;
		procedure SetHeapIndex (heap: THeap; newValue: integer);
		function CompareHeapItem (heap: THeap; item: IHeapItem): integer;
	end;
	
	THeap = class (TObject)
		public			
			constructor Create (maxHeapSize: integer);
			
			procedure Add (item: IHeapItem); 
			procedure Update (item: IHeapItem); 
			function Extract: IHeapItem; 
			function Count: integer;
			
		protected
			procedure Deallocate; override;
		private
			currentItemCount: integer;
			items: TFixedArray;
			
			procedure Swap (itemA, itemB: IHeapItem); 
			procedure SortUp (item: IHeapItem); 
			procedure SortDown (item: IHeapItem); 
			function GetItem (index: integer): IHeapItem; inline;
	end;

implementation

function THeap.GetItem (index: integer): IHeapItem;
begin
	result := IHeapItem(items.GetValue(index).GetInterface(IHeapItemUUID));
end;

procedure THeap.Swap (itemA, itemB: IHeapItem); 
var
	itemAIndex: integer;
begin
	items.SetValue(itemA.GetHeapIndex(self), itemB.GetObject);
	items.SetValue(itemB.GetHeapIndex(self), itemA.GetObject);
	itemAIndex := itemA.GetHeapIndex(self);
	itemA.SetHeapIndex(self, itemB.GetHeapIndex(self));
	itemB.SetHeapIndex(self, itemAIndex);
end;

procedure THeap.SortUp (item: IHeapItem); 
var
	parentIndex: integer;
	parentItem: IHeapItem;
begin
	parentIndex := (item.GetHeapIndex(self) - 1) div 2;
	while true do
		begin
			parentItem := GetItem(parentIndex);
			if item.CompareHeapItem(self, parentItem) > 0 then
				Swap(item, parentItem)
			else
				break;
			parentIndex := (item.GetHeapIndex(self) - 1) div 2;
		end;
end;

procedure THeap.SortDown (item: IHeapItem); 
var
	childIndexLeft, childIndexRight, swapIndex: integer;
begin
	while true do
		begin
			childIndexLeft := item.GetHeapIndex(self) * 2 + 1;
			childIndexRight := item.GetHeapIndex(self) * 2 + 2;
			swapIndex := 0;
			
			if (childIndexLeft < currentItemCount) then
				begin
					swapIndex := childIndexLeft;
					
					if childIndexRight < currentItemCount then
						if GetItem(childIndexLeft).CompareHeapItem(self, GetItem(childIndexRight)) < 0 then
							swapIndex := childIndexRight;
					
					if item.CompareHeapItem(self, GetItem(swapIndex)) < 0 then
						Swap(item, GetItem(swapIndex))
					else
						break;
					
				end
			else
				break;
		end;
end;

function THeap.Count: integer;
begin
	result := currentItemCount;
end;

procedure THeap.Update (item: IHeapItem); 
begin
	SortUp(item);
end;

function THeap.Extract: IHeapItem; 
var
	firstItem, item: IHeapItem;
begin
	firstItem := GetItem(0);
	currentItemCount -= 1;
	item := GetItem(currentItemCount);
	item.GetObject.Retain;
	firstItem.GetObject.Retain;
	//writeln('set value ', currentItemCount);
	items.SetValue(0, item.GetObject);
	item.SetHeapIndex(self, 0);
	SortDown(item);
	item.GetObject.Release;
	//writeln('done');
	
	result := firstItem;
end;

procedure THeap.Add (item: IHeapItem); 
begin
	item.SetHeapIndex(self, currentItemCount);
	items.SetValue(currentItemCount, item.GetObject);
	SortUp(item);
	currentItemCount += 1;
end;

procedure THeap.Deallocate; 
begin
	ReleaseObject(items);

	inherited;
end;

constructor THeap.Create (maxHeapSize: integer);
begin
	items := TFixedArray.Create(maxHeapSize);
	Initialize;
end;

end.