class_name SVGParser extends RefCounted

# Tags that don't make sense without other tags inside them.
const shorthand_tag_exceptions = ["svg", "g", "linearGradient, radialGradient"]

# For rendering only a section of the SVG.
static func svg_to_text_custom(svg_tag: TagSVG, custom_width: float,
custom_height: float, custom_viewbox: Rect2) -> String:
	var new_svg_tag: TagSVG = svg_tag.duplicate(false)
	new_svg_tag.attributes.viewBox.set_rect(custom_viewbox)
	new_svg_tag.attributes.width.set_num(custom_width)
	new_svg_tag.attributes.height.set_num(custom_height)
	var text := _tag_to_text(new_svg_tag)
	text = text.left(-6)  # Removee the </svg> at the end.
	for child_idx in svg_tag.get_child_count():
		text += _tag_to_text(svg_tag.get_tag(PackedInt32Array([child_idx])))
	return text + "</svg>"

static func svg_to_text(tag: TagSVG) -> String:
	if GlobalSettings.xml_add_trailing_newline:
		return _tag_to_text(tag) + "\n"
	else:
		return _tag_to_text(tag)

static func _tag_to_text(tag: Tag) -> String:
	var text := ""
	text += '<' + tag.name
	for attribute_key in tag.attributes:
		var attribute: Attribute = tag.attributes[attribute_key]
		var value := attribute.get_value()
		
		if value.is_empty():
			continue
		
		if not '"' in value:
			text += ' %s="%s"' % [attribute_key, value]
		else:
			text += " %s='%s'" % [attribute_key, value]
	
	for attribute in tag.unknown_attributes:
		var value := attribute.get_value()
		if not '"' in value:
			text += ' %s="%s"' % [attribute.name, value]
		else:
			text += " %s='%s'" % [attribute.name, value]
	
	if tag.is_standalone() and GlobalSettings.xml_shorthand_tags and\
	not tag.name in shorthand_tag_exceptions:
		text += '/>'
	else:
		text += '>'
		for child_tag in tag.child_tags:
			text += _tag_to_text(child_tag)
		text += '</' + tag.name + '>'
	
	return text


enum ParseError {OK, ERR_NOT_SVG, ERR_IMPROPER_NESTING}

class ParseResult extends RefCounted:
	var error: SVGParser.ParseError
	var svg: TagSVG
	
	func _init(err_id: SVGParser.ParseError, result: TagSVG = null) -> void:
		error = err_id
		svg = result

static func get_error_string(parse_error: ParseError) -> String:
	match parse_error:
		ParseError.ERR_NOT_SVG:
			return TranslationServer.translate("Doesn’t describe an SVG.")
		ParseError.ERR_IMPROPER_NESTING:
			return TranslationServer.translate("Improper nesting.")
		_: return ""

static func text_to_svg(text: String) -> ParseResult:
	if text.is_empty():
		return ParseResult.new(ParseError.ERR_NOT_SVG)
	
	var svg_tag := TagSVG.new()
	var parser := XMLParser.new()
	parser.open_buffer(text.to_utf8_buffer())
	var unclosed_tag_stack: Array[Tag] = []
	
	# Remove everything before the first SVG tag.
	var describes_svg := false
	
	# Parse the first svg tag that's encountered.
	while parser.read() == OK:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT or\
		parser.get_node_name() != "svg":
			continue
		
		describes_svg = true
		
		var attrib_dict := {}
		for i in parser.get_attribute_count():
			attrib_dict[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
		# width, height, and viewBox don't have defaults.
		if attrib_dict.has("width"):
			svg_tag.attributes.width.set_value(attrib_dict["width"],
					Attribute.SyncMode.SILENT)
		if attrib_dict.has("height"):
			svg_tag.attributes.height.set_value(attrib_dict["height"],
					Attribute.SyncMode.SILENT)
		if attrib_dict.has("viewBox"):
			svg_tag.attributes.viewBox.set_value(attrib_dict["viewBox"],
					Attribute.SyncMode.SILENT)
		svg_tag.update_cache()
		
		var unknown: Array[Attribute] = []
		for element in attrib_dict:
			if svg_tag.attributes.has(element):
				var attribute: Attribute = svg_tag.attributes[element]
				attribute.set_value(attrib_dict[element], Attribute.SyncMode.SILENT)
			else:
				unknown.append(Attribute.new(element, attrib_dict[element]))
		svg_tag.set_unknown_attributes(unknown)
		
		var node_offset := parser.get_node_offset()
		var closure_pos := text.find("/>", node_offset)
		if closure_pos == -1 or closure_pos > text.find(">", node_offset):
			unclosed_tag_stack.append(svg_tag)
			break
		else:
			return ParseResult.new(ParseError.OK, svg_tag)
	
	if not describes_svg:
		return ParseResult.new(ParseError.ERR_NOT_SVG)
	
	# Parse everything until the SVG closing tag.
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var node_name := parser.get_node_name()
				var attrib_dict := {}
				for i in parser.get_attribute_count():
					attrib_dict[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
				
				var tag: Tag
				match node_name:
					"circle": tag = TagCircle.new()
					"ellipse": tag = TagEllipse.new()
					"rect": tag = TagRect.new()
					"path": tag = TagPath.new()
					"line": tag = TagLine.new()
					"stop": tag = TagStop.new()
					_: tag = TagUnknown.new(node_name)
				
				var unknown: Array[Attribute] = []
				for element in attrib_dict:
					if tag.attributes.has(element):
						var attribute: Attribute = tag.attributes[element]
						attribute.set_value(attrib_dict[element], Attribute.SyncMode.SILENT)
					else:
						unknown.append(Attribute.new(element, attrib_dict[element]))
				tag.set_unknown_attributes(unknown)
				
				# Check if we're entering or exiting the tag.
				var node_offset := parser.get_node_offset()
				var closure_pos := text.find("/>", node_offset)
				if closure_pos == -1 or closure_pos > text.find(">", node_offset):
					unclosed_tag_stack.append(tag)
				else:
					unclosed_tag_stack.back().child_tags.append(tag)
			XMLParser.NODE_ELEMENT_END:
				if unclosed_tag_stack.is_empty():
					return ParseResult.new(ParseError.ERR_IMPROPER_NESTING)
				else:
					var closed_tag: Tag = unclosed_tag_stack.pop_back()
					if closed_tag.name != parser.get_node_name():
						return ParseResult.new(ParseError.ERR_IMPROPER_NESTING)
					if unclosed_tag_stack.size() >= 1:
						unclosed_tag_stack.back().child_tags.append(closed_tag)
					else:
						break
	
	if not unclosed_tag_stack.is_empty():
		return ParseResult.new(ParseError.ERR_IMPROPER_NESTING)
	
	return ParseResult.new(ParseError.OK, svg_tag)
