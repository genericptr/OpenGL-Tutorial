{$mode objfpc}

unit UPlist;
interface
uses
	DOM, XMLRead, XMLWrite, SysUtils,
	UArchive, UArray, UValue, UDictionary, UString, UData, UObject;

// TO-DO:
// - TData keys are not working yet (see notes below)

type
	TDictionaryPropertyListHelper = class helper (TDictionaryArchiveHelper) for TDictionary
		class function ReadFromFile (path: string): TDictionary;
		function WriteToFile (path: string): boolean;
	end;

function ReadPropertyList (path: string): TDictionary;
function WritePropertyList (dictionary: TDictionary; path: string): boolean;

function AllocateFromArchive (path: string): TObject; overload;

implementation
	
class function TDictionaryPropertyListHelper.ReadFromFile (path: string): TDictionary;
begin
	result := ReadPropertyList(path);
end;	
	
function TDictionaryPropertyListHelper.WriteToFile (path: string): boolean;
begin
	result := WritePropertyList(self, path);
end;

function ObjectForNode (node: TDOMNode): TObject;
begin
	if node.NodeName = 'dict' then
		result := TDictionary.Instance
	else if node.NodeName = 'array' then
		result := TArray.Instance
	else if node.NodeName = 'integer' then
		result := TNumber.From(StrToInt(node.TextContent))
	else if node.NodeName = 'real' then
		result := TNumber.From(StrToFloat(node.TextContent))
	else if node.NodeName = 'string' then
		result := TString.Instance(node.TextContent)
	else if node.NodeName = 'false' then
		result := TNumber.From(false)
	else if node.NodeName = 'true' then
		result := TNumber.From(true)
	else if node.NodeName = 'boolean' then
		begin
			if StrToInt(node.TextContent) = 1 then
				result := TNumber.From(true)
			else
				result := TNumber.From(false)
		end
	else if node.NodeName = 'data' then
		result := TData.Instance(@node.TextContent[1], length(node.TextContent))
	else
		begin
			writeln('no object for "', node.NodeName,'"');
			result := nil;
		end;
end;

procedure DecodeNode (parent: TObject; var key: TDictionaryKey; node: TDOMNode);
var
	objectNode: TObject;
begin
	if (node.ClassType = TDOMText) or (node.ClassType = TDOMComment) then
		exit;
		
	//writeln(node.NodeName, ':', node.TextContent);
	
	if parent.IsMember(TArray) then
		begin
			objectNode := ObjectForNode(node);
			TArray(parent).AddValue(objectNode);
			if objectNode.IsMember(TArray) or objectNode.IsMember(TDictionary) then
				parent := objectNode;
		end
	else if parent.IsMember(TDictionary) then
		begin
			if key = '' then
				key := node.TextContent
			else
				begin
					objectNode := ObjectForNode(node);
					TDictionary(parent).SetValue(key, objectNode);
					if objectNode.IsMember(TArray) or objectNode.IsMember(TDictionary) then
						parent := objectNode;
					key := '';
				end;
		end;
		
	node := node.FirstChild;
	while node <> nil do
		begin
	  	DecodeNode(parent, key, node);
	  	node := node.NextSibling;
		end;
end;

function ReadPropertyList (path: string): TDictionary;
var
  node: TDOMNode;
  xml: TXMLDocument;
	root: TDictionary;
	key: string = '';
begin
	result := nil;
  try
    ReadXMLFile(xml, path);
		
		node := xml.DocumentElement.FirstChild;
		
		// root node
		if node.NodeName = 'dict' then
			root := TDictionary.Create
		else
			begin
				writeln('root type is not dict');
				exit(nil);
			end;
		
		// start inside the root
		node := node.FirstChild;	
			
		while node <> nil do
			begin
		  	DecodeNode(root, key, node);
		  	node := node.NextSibling;
			end;
		//writeln('xml:');
		//root.Show;
		result := root;
  finally
    xml.Free;
  end;
end;

function NodeForObject (var obj: TObject; document: TXMLDocument; var valueNode: TDOMNode; var nodeName: string): boolean;
var
	bytes: pointer;
	data: TDictionary;
	archive: IObjectArchiving;
begin
	valueNode := nil;
	nodeName := '';
		
	if obj.IsMember(TString) then
		begin
			valueNode := document.CreateTextNode(TString(obj).GetString);
			nodeName := 'string';
		end
	else if obj.IsMember(TNumber) then
		begin
			case TNumber(obj).GetKind of
				kNumberKindInteger:
					begin
						valueNode := document.CreateTextNode(IntToStr(TNumber(obj).IntegerValue));
						nodeName := 'integer';
					end;
				kNumberKindSingle:
					begin
						valueNode := document.CreateTextNode(FloatToStr(TNumber(obj).IntegerValue));
						nodeName := 'real';
					end;
				kNumberKindBoolean:
					begin
						if TNumber(obj).BooleanValue then
							nodeName := 'true'
						else
							nodeName := 'false';
					end;
				otherwise
					exit(false);
			end;
		end
	else if obj.IsMember(TData) then
		begin
			{
			http://stackoverflow.com/questions/19677946/converting-string-to-byte-array-wont-work
			
			we probably need to convert to a byte array first
			}
			raise exception.create('archiving TData is unsupported');
			valueNode := document.CreateTextNode('N/A');
			nodeName := 'data';
		end
	else if obj.IsMember(TArray) then
		begin
			nodeName := 'array';
		end
	else if obj.IsMember(TDictionary) then
		begin
			nodeName := 'dict';
		end
	else if Supports(obj, IObjectArchiving, archive) then
		begin
			nodeName := 'dict';
			data := TDictionary.Instance;
			archive.EncodeData(data);
			// return the decoded data
			obj := data;
		end
	else
		begin
			raise Exception.Create(obj.ClassName+' can''t be encoded for plist.');
			exit(false);
		end;
	
	result := true;
end;

procedure EncodeNode (parent: TObject; parentNode: TDOMNode; document: TXMLDocument);
var
	keys: TDictionaryKeyArray;
	values: TArrayValues;
	key: TDictionaryKey;
	value: TObject;
	childNode: TDOMNode;
	valueNode: TDOMNode;
	nodeName: string;
	i: integer;
begin
	if parent.IsMember(TDictionary) then
		begin
			keys := TDictionary(parent).GetAllKeys;
			for key in keys do
				begin
					value := TDictionary(parent).GetValue(key);
					//writeln(key, ':', value.classname);
					
					// key node
					childNode := document.CreateElement('key'); 
					valueNode := document.CreateTextNode(key);
			    childNode.AppendChild(valueNode);
			    parentNode.AppendChild(childNode);
			    
					// value node
					if NodeForObject(value, document, valueNode, nodeName) then
						begin
							childNode := document.CreateElement(nodeName); 
							if valueNode <> nil then
					    	childNode.AppendChild(valueNode);
					    parentNode.AppendChild(childNode);
					
							// recurse
							if value.IsMember(TArray) or value.IsMember(TDictionary) then
								EncodeNode(value, childNode, document);
						end;
				end;
		end
	else if parent.IsMember(TArray) then
		begin
			values := TArray(parent).GetAllValues;
			for i := 0 to high(values) do
				begin
					value := values[i];
					//writeln(i, ':', value.classname);
					
					if NodeForObject(value, document, valueNode, nodeName) then
						begin
							childNode := document.CreateElement(nodeName); 
							if valueNode <> nil then
					    	childNode.AppendChild(valueNode);
					    parentNode.AppendChild(childNode);

							// recurse
							if value.IsMember(TArray) or value.IsMember(TDictionary) then
								EncodeNode(value, childNode, document);
						end;
				end;
				
			{for value in TArray(parent).GetAllValues do
				if NodeForObject(value, document, valueNode, nodeName) then
					begin
						childNode := document.CreateElement(nodeName); 
						if valueNode <> nil then
				    	childNode.AppendChild(valueNode);
				    parentNode.AppendChild(childNode);

						// recurse
						if value.IsMember(TArray) or value.IsMember(TDictionary) then
							EncodeNode(value, childNode, document);
					end;}
		end
	else
		begin
			writeln('invalid value to encode: ', parent.ClassName);
			halt;
		end;
end;

function WritePropertyList (dictionary: TDictionary; path: string): boolean;
var
	document: TXMLDocument;
	node: TDOMNode;
	root: TDOMNode;
begin
	document := TXMLDocument.Create;

	// property list node
	node := document.CreateElement('plist');
	TDOMElement(node).SetAttribute('version', '1.0');
	document.AppendChild(node);
  root := document.DocumentElement;

	// root dictionary
  node := document.CreateElement('dict');
	root.AppendChild(node);

  EncodeNode(dictionary, node, document);

	WriteXMLFile(document, path); 
end;

function AllocateFromArchive (path: string): TObject;
var
	data: TDictionary;
begin
	data := ReadPropertyList(path);
	if data <> nil then
		begin
			result := AllocateFromArchive(data);
			data.Release;
		end
	else
		result := nil;
end;

end.