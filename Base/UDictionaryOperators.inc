
{$ifdef INTERFACE}
operator in (a: INPUT; b: OUTPUT): boolean; overload;
{$endif}

{$ifdef IMPLEMENTATION}
operator in (a: INPUT; b: OUTPUT): boolean; overload;
begin
	result := b.KeyOfValue(a) <> '';
end;
{$endif}