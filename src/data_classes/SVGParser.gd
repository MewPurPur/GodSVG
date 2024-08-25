class_name SVGParser extends RefCounted

# For rendering only a section of the SVG.
static func root_to_text_custom(root_element: ElementRoot, custom_width: float,
custom_height: float, custom_viewbox: Rect2) -> String:
	var blank_formatter := Formatter.new()
	blank_formatter.xml_shorthand_tags = Formatter.ShorthandTags.ALL_EXCEPT_CONTAINERS
	var new_root_element: ElementRoot = root_element.duplicate(false)
	
	new_root_element.set_attribute("viewBox", custom_viewbox)
	new_root_element.set_attribute("width", custom_width)
	new_root_element.set_attribute("height", custom_height)
	var text := _element_to_text(new_root_element, blank_formatter)
	text = text.strip_edges(false, true).left(-6)  # Remove the </svg> at the end.)
	for child_idx in root_element.get_child_count():
		text += _element_to_text(root_element.get_element(PackedInt32Array([child_idx])),
				blank_formatter, true)
	return text + "</svg>"

static func root_to_text(root_element: ElementRoot,
formatter: Formatter = GlobalSettings.savedata.editor_formatter) -> String:
	var text := _element_to_text(root_element, formatter).trim_suffix('\n')
	if formatter.xml_add_trailing_newline:
		text += "\n"
	return text

static func _element_to_text(element: Element, formatter: Formatter,
make_attributes_absolute := false) -> String:
	if make_attributes_absolute:
		element.make_all_attributes_absolute()
	
	var text := ""
	if formatter.xml_pretty_formatting:
		if formatter.xml_indentation_use_spaces:
			text += ' '.repeat(element.xid.size() * formatter.xml_indentation_spaces)
		else:
			text += '\t'.repeat(element.xid.size())
	text += '<' + element.name
	for attribute: Attribute in element.get_all_attributes():
		var value := attribute.get_value()
		
		if not '"' in value:
			text += ' %s="%s"' % [attribute.name, value]
		else:
			text += " %s='%s'" % [attribute.name, value]
	
	if element.has_children() and (formatter.xml_shorthand_tags ==\
	Formatter.ShorthandTags.ALWAYS or (formatter.xml_shorthand_tags ==\
	Formatter.ShorthandTags.ALL_EXCEPT_CONTAINERS and\
	not element.name in Formatter.container_elements)):
		text += ' />' if formatter.xml_shorthand_tags_space_out_slash else '/>'
		if formatter.xml_pretty_formatting:
			text += '\n'
	else:
		text += '>'
		if formatter.xml_pretty_formatting:
			text += '\n'
		for child in element.get_children():
			text += _element_to_text(child, formatter)
		if formatter.xml_pretty_formatting:
			text += '\t'.repeat(element.xid.size())
		text += '</%s>' % element.name
		if formatter.xml_pretty_formatting:
			text += '\n'
	
	return text


enum ParseError {OK, ERR_NOT_SVG, ERR_IMPROPER_NESTING}

class ParseResult extends RefCounted:
	var error: SVGParser.ParseError
	var svg: ElementRoot
	
	func _init(err_id: SVGParser.ParseError, result: ElementSVG = null) -> void:
		error = err_id
		svg = result

static func get_error_string(parse_error: ParseError) -> String:
	match parse_error:
		ParseError.ERR_NOT_SVG:
			return TranslationServer.translate("Doesn’t describe an SVG.")
		ParseError.ERR_IMPROPER_NESTING:
			return TranslationServer.translate("Improper nesting.")
		_: return ""

static func text_to_root(text: String, formatter: Formatter) -> ParseResult:
	if text.is_empty():
		return ParseResult.new(ParseError.ERR_NOT_SVG)
	
	var root_element := ElementRoot.new(formatter)
	root_element.formatter = formatter
	root_element.xid = PackedInt32Array()
	root_element.root = root_element
	var parser := XMLParser.new()
	parser.open_buffer(text.to_utf8_buffer())
	var unclosed_element_stack: Array[Element] = []
	
	# Remove everything before the first SVG tag.
	var describes_svg := false
	
	# Parse the first svg tag that's encountered.
	while parser.read() == OK:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT or\
		parser.get_node_name() != "svg":
			continue
		
		describes_svg = true
		
		for i in parser.get_attribute_count():
			root_element.set_attribute(parser.get_attribute_name(i),
					parser.get_attribute_value(i))
		
		var node_offset := parser.get_node_offset()
		var closure_pos := text.find("/>", node_offset)
		if closure_pos == -1 or closure_pos > text.find(">", node_offset):
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
				var closure_pos := text.find("/>", node_offset)
				
				unclosed_element_stack.back().insert_child(-1, element)
				for i in parser.get_attribute_count():
					element.set_attribute(parser.get_attribute_name(i),
							parser.get_attribute_value(i))
				
				if closure_pos == -1 or closure_pos > text.find(">", node_offset):
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
	
	if not unclosed_element_stack.is_empty():
		return ParseResult.new(ParseError.ERR_IMPROPER_NESTING)
	
	return ParseResult.new(ParseError.OK, root_element)
