class_name SVGParser extends RefCounted

# For rendering only a section of the SVG.
static func root_cutout_to_text(root_element: ElementRoot, custom_width: float,
custom_height: float, custom_viewbox: Rect2) -> String:
	var blank_formatter := Formatter.new()
	blank_formatter.xml_shorthand_tags = Formatter.ShorthandTags.ALL_EXCEPT_CONTAINERS
	var new_root_element: ElementRoot = root_element.duplicate(false)
	
	new_root_element.set_attribute("viewBox", custom_viewbox)
	new_root_element.set_attribute("width", custom_width)
	new_root_element.set_attribute("height", custom_height)
	var text := _xnode_to_text(new_root_element, blank_formatter)
	text = text.strip_edges(false, true).left(-6)  # Remove the </svg> at the end.)
	for child_idx in root_element.get_child_count():
		text += _xnode_to_text(root_element.get_xnode(PackedInt32Array([child_idx])),
				blank_formatter, true)
	return text + "</svg>"

static func root_to_text(root_element: ElementRoot,
formatter: Formatter = GlobalSettings.savedata.editor_formatter) -> String:
	var text := _xnode_to_text(root_element, formatter).trim_suffix('\n')
	if formatter.xml_add_trailing_newline:
		text += "\n"
	return text

static func _xnode_to_text(xnode: XNode, formatter: Formatter,
make_attributes_absolute := false) -> String:
	var text := ""
	if formatter.xml_pretty_formatting:
		if formatter.xml_indentation_use_spaces:
			text = ' '.repeat(xnode.xid.size() * formatter.xml_indentation_spaces)
		else:
			text = '\t'.repeat(xnode.xid.size())
	
	if not xnode.is_element():
		match xnode.get_type():
			BasicXNode.NodeType.COMMENT: text += "<!--%s-->" % xnode.get_text()
			BasicXNode.NodeType.CDATA: text += "<![CDATA[%s]]>" % xnode.get_text()
			_: text += xnode.get_text()
		if formatter.xml_pretty_formatting:
			text += "\n"
		return text
	
	var element := xnode as Element
	var attribute_array := element.get_all_attributes()
	if make_attributes_absolute:
		# Add known default value attributes if they are percentage-based.
		for attrib_name in DB.get_recognized_attributes(element.name):
			if DB.get_attribute_type(attrib_name) != DB.AttributeType.NUMERIC:
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
	
	text += '<' + element.name
	for attribute: Attribute in attribute_array:
		var value := attribute.get_value()
		
		if not '"' in value:
			text += ' %s="%s"' % [attribute.name, value]
		else:
			text += " %s='%s'" % [attribute.name, value]
	
	if not element.has_children() and (formatter.xml_shorthand_tags ==\
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
			text += _xnode_to_text(child, formatter)
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
			return Translator.translate("Doesn’t describe an SVG.")
		ParseError.ERR_IMPROPER_NESTING:
			return Translator.translate("Improper nesting.")
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
			
			XMLParser.NODE_COMMENT:
				if formatter.xml_keep_comments:
					unclosed_element_stack.back().insert_child(-1,
							BasicXNode.new(BasicXNode.NodeType.COMMENT, parser.get_node_name()))
			XMLParser.NODE_TEXT:
				var real_text := parser.get_node_data().strip_edges()
				if not real_text.is_empty():
					unclosed_element_stack.back().insert_child(-1,
							BasicXNode.new(BasicXNode.NodeType.TEXT, real_text))
			XMLParser.NODE_CDATA:
				unclosed_element_stack.back().insert_child(-1,
						BasicXNode.new(BasicXNode.NodeType.CDATA, parser.get_node_name()))
			_:
				if formatter.xml_keep_unrecognized:
					unclosed_element_stack.back().insert_child(-1,
							BasicXNode.new(BasicXNode.NodeType.UNKNOWN, parser.get_node_name()))
	
	if not unclosed_element_stack.is_empty():
		return ParseResult.new(ParseError.ERR_IMPROPER_NESTING)
	
	return ParseResult.new(ParseError.OK, root_element)
