## Parser for SVG markup.
@abstract class_name SVGParser

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
		var node_offset := parser.get_node_offset()
		var closure_pos := _find_closure_string_in_utf8_buffer(buffer, node_offset)
		if closure_pos != -1 and closure_pos <= buffer.find(ord(">"), node_offset):
			return true  # If the svg tag is immediately closed, i.e. <svg/>, then it's empty.
		break
	
	# If the SVG tag isn't immediately closed, then check if the next XML node is an </svg> element end.
	return describes_svg and parser.read() == OK and parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == "svg"

## Creates markup for an SVG that only represents a rectangular cutout of the original.
static func root_cutout_to_markup(root_element: ElementRoot, custom_width: float, custom_height: float, custom_viewbox: Rect2) -> String:
	# Build a new root element, set it up, and convert it to markup.
	var new_root_element: ElementRoot = root_element.duplicate(false)
	new_root_element.set_attribute("viewBox", ListParser.rect_to_list(custom_viewbox))
	new_root_element.set_attribute("width", custom_width)
	new_root_element.set_attribute("height", custom_height)
	var markup := _xnode_to_markup(new_root_element, Configs.savedata.editor_formatter)
	# Since we only converted a single root element to markup, it would have closed.
	# Remove the closure and add all the other elements' markup before closing it manually.
	markup = markup.left(maxi(markup.find("/>"), markup.find("</svg>"))) + ">"
	for child_idx in root_element.get_child_count():
		markup += _xnode_to_markup(root_element.get_xnode(PackedInt32Array([child_idx])), Configs.savedata.editor_formatter, true)
	return markup + "</svg>"


## Converts the child elements of a root element into markup, excluding the root tag itself.
static func root_children_to_markup(root_element: ElementRoot, formatter: Formatter) -> String:
	var markup := ""
	for child in root_element.get_children():
		var new_markup := _xnode_to_markup(child, formatter)
		# Remove one level of indentation from each line to maintain proper formatting.
		var lines := new_markup.split('\n')
		for i in lines.size():
			lines[i] = lines[i].trim_prefix(formatter.get_indent_string())
		markup += '\n'.join(lines)
	return markup.trim_suffix('\n')

## Converts a root element into markup using the editor formatter.
static func root_to_editor_markup(root_element: ElementRoot) -> String:
	return root_to_markup(root_element, Configs.savedata.editor_formatter)

## Converts a root element into markup using the export formatter.
static func root_to_export_markup(root_element: ElementRoot) -> String:
	return root_to_markup(root_element, Configs.savedata.export_formatter)

## Converts a root element into markup using an arbitrary formatter.
static func root_to_markup(root_element: ElementRoot, formatter: Formatter) -> String:
	var markup := _xnode_to_markup(root_element, formatter).trim_suffix('\n')
	if formatter.xml_add_trailing_newline:
		markup += "\n"
	return markup

# The main entry point for converting any XML node and its descendants into markup.
# If make_attributes_absolute is true, converts percentage-based attributes into absolute values so cutouts can be safely made.
static func _xnode_to_markup(xnode: XNode, formatter: Formatter, make_attributes_absolute := false) -> String:
	var markup := ""
	if formatter.xml_pretty_formatting:
		markup = formatter.get_indent_string().repeat(xnode.xid.size())
	
	if not xnode.is_element():
		if (not formatter.xml_keep_comments and xnode.get_type() == BasicXNode.NodeType.COMMENT):
			return ""
		
		match xnode.get_type():
			BasicXNode.NodeType.COMMENT: markup += "<!--%s-->" % xnode.get_text()
			BasicXNode.NodeType.CDATA: markup += "<![CDATA[%s]]>" % xnode.get_text()
			_: markup += xnode.get_text()
		if formatter.xml_pretty_formatting:
			markup += "\n"
		return markup
	
	var element := xnode as Element
	var attribute_array := element.get_all_attributes()
	if make_attributes_absolute:
		# Add known default value attributes if they are percentage-based.
		for attrib_name in DB.get_recognized_attributes(element.name):
			if element.get_percentage_handling(attrib_name) == DB.PercentageHandling.FRACTION:
				continue
			
			var already_exists := false
			for attrib in attribute_array:
				if attrib.name == attrib_name:
					already_exists = true
					break
			if already_exists:
				continue
			
			if element.is_attribute_percentage(attrib_name):
				attribute_array.append(element._create_attribute(attrib_name))
		# Turn percentages into numbers.
		for attrib_idx in attribute_array.size():
			var attrib: Attribute = attribute_array[attrib_idx]
			if attrib is AttributeNumeric and element.is_attribute_percentage(attrib.name):
				var new_attrib := element._create_attribute(attrib.name)
				new_attrib.set_num(element.get_attribute_num(attrib.name))
				attribute_array[attrib_idx] = new_attrib
	
	markup += '<' + element.name
	for attribute: Attribute in attribute_array:
		var value := attribute.get_formatted_value(formatter)
		
		if not '"' in value:
			markup += ' %s="%s"' % [attribute.name, value]
		else:
			markup += " %s='%s'" % [attribute.name, value]
	
	if not element.has_children() and (formatter.xml_shorthand_tags == Formatter.ShorthandTags.ALWAYS or\
	(formatter.xml_shorthand_tags == Formatter.ShorthandTags.ALL_EXCEPT_CONTAINERS and not element.name in Formatter.CONTAINER_ELEMENTS)):
		markup += ' />' if formatter.xml_shorthand_tags_space_out_slash else '/>'
		if formatter.xml_pretty_formatting:
			markup += '\n'
	else:
		markup += '>'
		if formatter.xml_pretty_formatting:
			markup += '\n'
		for child in element.get_children():
			markup += _xnode_to_markup(child, formatter, make_attributes_absolute)
		if formatter.xml_pretty_formatting:
			markup += formatter.get_indent_string().repeat(element.xid.size())
		markup += '</%s>' % element.name
		if formatter.xml_pretty_formatting:
			markup += '\n'
	return markup


enum ParseError {OK, ERR_NOT_SVG, ERR_IMPROPER_NESTING}

class ParseResult:
	var error: SVGParser.ParseError
	var svg: ElementRoot
	
	func _init(err_id: SVGParser.ParseError, result: ElementSVG = null) -> void:
		error = err_id
		svg = result

## Returns the human-readable text that should be shown to users to represent a ParseError.
static func get_parsing_error_string(parse_error: ParseError) -> String:
	match parse_error:
		ParseError.ERR_NOT_SVG:
			return Translator.translate("Doesn’t describe an SVG.")
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
		
		var node_offset := parser.get_node_offset()
		
		var closure_pos := _find_closure_string_in_utf8_buffer(buffer, node_offset)
		if closure_pos == -1 or closure_pos > buffer.find(ord(">"), node_offset):
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
				var node_offset := parser.get_node_offset()
				var closure_pos := _find_closure_string_in_utf8_buffer(buffer, node_offset)
				
				unclosed_element_stack.back().insert_child(-1, element)
				for i in parser.get_attribute_count():
					element.set_attribute(parser.get_attribute_name(i), parser.get_attribute_value(i))
				
				if closure_pos == -1 or closure_pos > buffer.find(ord(">"), node_offset):
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
				if Configs.savedata.editor_formatter.xml_keep_comments:
					unclosed_element_stack.back().insert_child(-1, BasicXNode.new(BasicXNode.NodeType.COMMENT, parser.get_node_name()))
			XMLParser.NODE_TEXT:
				var real_text := parser.get_node_data().strip_edges()
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
		if offset == -1:
			return -1
		elif buffer[offset + 1] == ord(">"):
			return offset
		offset += 1
	return -1
