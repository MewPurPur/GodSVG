## Parser for SVG markup.
@abstract class_name ParserSVG

## Checks if the SVG markup describes an SVG element without child elements.
static func markup_check_is_root_empty(markup: String) -> bool:
	if markup.is_empty():
		return false
	
	var buffer := markup.to_utf8_buffer()
	var parser := XMLParser.new()
	parser.open_buffer(buffer)
	
	# Ignore everything before the first svg tag.
	var describes_svg := false
	
	# Parse the first svg tag that's encountered.
	while parser.read() == OK:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT or parser.get_node_name() != "svg":
			continue
		describes_svg = true
		if parser.is_empty():
			return true
		break
	
	# If the SVG tag isn't immediately closed, then check if the next XML node is an </svg> element end.
	return describes_svg and parser.read() == OK and parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == "svg"

## Creates markup for an SVG that only represents a rectangular cutout of the original.
## inner_markup can be retrieved from the get_inner_markup_with_percentages_converted() method.
static func root_cutout_to_markup(root_element: ElementRoot, custom_dimensions: Vector2, custom_viewbox: Rect2, inner_markup: String = "") -> String:
	# Build a new root element, set it up, and convert it to markup.
	var new_root_element: ElementRoot = root_element.duplicate(false)
	new_root_element.set_attribute("viewBox", ParserList.rect_to_list(custom_viewbox))
	new_root_element.set_attribute("width", custom_dimensions.x)
	new_root_element.set_attribute("height", custom_dimensions.y)
	
	var root_markup := Configs.savedata.editor_formatter.xnode_to_markup(new_root_element).strip_edges(false, true)
	if root_markup.ends_with("/>"):
		root_markup = root_markup.erase(root_markup.length() - 2)
	else:
		root_markup = root_markup.left(-6)
	return root_markup + inner_markup + "</svg>"

static func get_inner_markup_with_percentages_converted(root_element: ElementRoot) -> String:
	var inner_markup := ""
	for child_idx in root_element.get_child_count():
		inner_markup += Configs.savedata.editor_formatter.xnode_to_markup(root_element.get_xnode(PackedInt32Array([child_idx])), true)
	return inner_markup


enum ParseError {OK, ERR_NOT_SVG, ERR_IMPROPER_NESTING}

class ParseResult:
	var error: ParserSVG.ParseError
	var svg: ElementRoot
	
	func _init(err_id: ParserSVG.ParseError, result: ElementSVG = null) -> void:
		error = err_id
		svg = result

## Returns the human-readable text that should be shown to users to represent a ParseError.
static func get_parsing_error_string(parse_error: ParseError) -> String:
	match parse_error:
		ParseError.ERR_NOT_SVG:
			return Translator.translate("Doesn't describe an SVG.")
		ParseError.ERR_IMPROPER_NESTING:
			return Translator.translate("Improper nesting.")
		_: return ""

## The main entry point for converting SVG markup into the internal element tree structure.
## Returns a parse result, which contains either the ElementRoot or an error from an enum.
static func markup_to_root(markup: String) -> ParseResult:
	if markup.is_empty():
		return ParseResult.new(ParseError.ERR_NOT_SVG)
	
	var buffer := markup.to_utf8_buffer()
	var root_element := ElementRoot.new()
	var parser := XMLParser.new()
	parser.open_buffer(buffer)
	var unclosed_element_stack: Array[Element] = []
	
	# Ignore everything before the first SVG tag.
	var describes_svg := false
	
	# Parse the first svg tag that's encountered.
	while parser.read() == OK:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT or parser.get_node_name() != "svg":
			continue
		
		describes_svg = true
		
		for i in parser.get_attribute_count():
			root_element.set_attribute(parser.get_attribute_name(i), parser.get_attribute_value(i))
		
		if not parser.is_empty():
			unclosed_element_stack.append(root_element)
			break
		else:
			return ParseResult.new(ParseError.OK, root_element)
	
	if not describes_svg:
		return ParseResult.new(ParseError.ERR_NOT_SVG)
	
	# Parse everything until the SVG closing tag.
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var element := DB.element(parser.get_node_name())
				# Check if we're entering or exiting the element.
				unclosed_element_stack.back().insert_child(-1, element)
				for i in parser.get_attribute_count():
					element.set_attribute(parser.get_attribute_name(i), parser.get_attribute_value(i))
				
				if not parser.is_empty():
					unclosed_element_stack.append(element)
			
			XMLParser.NODE_ELEMENT_END:
				if unclosed_element_stack.is_empty():
					return ParseResult.new(ParseError.ERR_IMPROPER_NESTING)
				else:
					var closed_element: Element = unclosed_element_stack.pop_back()
					if closed_element.name != parser.get_node_name():
						return ParseResult.new(ParseError.ERR_IMPROPER_NESTING)
					if unclosed_element_stack.is_empty():
						break
			
			XMLParser.NODE_COMMENT:
				unclosed_element_stack.back().insert_child(-1, BasicXNode.new(BasicXNode.NodeType.COMMENT, parser.get_node_name()))
			XMLParser.NODE_TEXT:
				var node_offset := parser.get_node_offset()
				# Trick to read XML text as is, without parsing stuff like "&lt;".
				if parser.read() == OK:
					var real_text := buffer.slice(node_offset, parser.get_node_offset()).get_string_from_utf8().strip_edges()
					parser.seek(node_offset)
					if not real_text.is_empty():
						unclosed_element_stack.back().insert_child(-1, BasicXNode.new(BasicXNode.NodeType.TEXT, real_text))
			XMLParser.NODE_CDATA:
				unclosed_element_stack.back().insert_child(-1, BasicXNode.new(BasicXNode.NodeType.CDATA, parser.get_node_name()))
	
	if not unclosed_element_stack.is_empty():
		return ParseResult.new(ParseError.ERR_IMPROPER_NESTING)
	
	return ParseResult.new(ParseError.OK, root_element)


# Helper to find "/>" strings inside a buffer.
static func _find_closure_string_in_utf8_buffer(buffer: PackedByteArray, offset: int) -> int:
	while true:
		offset = buffer.find(ord("/"), offset)
		if offset == -1 or offset == buffer.size() - 1:
			return -1
		elif buffer[offset + 1] == ord(">"):
			return offset
		offset += 1
	return -1
