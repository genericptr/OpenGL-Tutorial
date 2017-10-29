
{$ifdef INTERFACE}
operator + (a: OUTPUT; b: INPUT): OUTPUT; overload;
operator + (a: OUTPUT; b: OUTPUT): OUTPUT; overload;
operator - (a: OUTPUT; b: INPUT): OUTPUT; overload;
operator in (a: INPUT; b: OUTPUT): boolean; overload;
{$endif}

{$ifdef IMPLEMENTATION}
operator + (a: OUTPUT; b: INPUT): OUTPUT; overload;
begin
	a.AddValue(b);
	result := a;
end;

operator + (a: OUTPUT; b: OUTPUT): OUTPUT; overload;
begin
	a.AddValuesFromArray(b);
	result := a;
end;

operator - (a: OUTPUT; b: INPUT): OUTPUT; overload;
begin
	a.RemoveFirstValue(b);
	result := a;
end;

operator in (a: INPUT; b: OUTPUT): boolean; overload;
begin
	result := b.ContainsValue(a);
end;
{$endif}