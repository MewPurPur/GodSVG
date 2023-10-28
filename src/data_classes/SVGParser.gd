class_name SVGParser extends RefCounted

static func svg_to_text(svg_tag: TagSVG) -> String:
	var w: float = svg_tag.attributes.width.get_value()
	var h: float = svg_tag.attributes.height.get_value()
	var viewbox: Rect2 = svg_tag.attributes.viewBox.get_value()
	# Opening
	var text := '<svg width="%s" height="%s" viewBox="%s"' % [String.num(w, 4),
			String.num(h, 4), AttributeRect.rect_to_string(viewbox)]
	text += ' xmlns="http://www.w3.org/2000/svg">'
	
	for inner_tag in svg_tag.child_tags:
		text += '<' + inner_tag.title
		for attribute_key in inner_tag.attributes:
			var attribute: Attribute = inner_tag.attributes[attribute_key]
			var value: Variant = attribute.get_value()
			if value == attribute.default:
				continue
			
			text += " " + attribute_key + '="'
			match attribute.type:
				Attribute.Type.INT:
					text += value.to_int()
				Attribute.Type.FLOAT, Attribute.Type.UFLOAT, Attribute.Type.NFLOAT:
					text += String.num(value, 4)
				Attribute.Type.COLOR, Attribute.Type.PATHDATA, Attribute.Type.ENUM:
					text += value
				Attribute.Type.RECT:
					text += AttributeRect.rect_to_string(value)
			text += '"'
		for attribute in inner_tag.unknown_attributes:
			text += " " + attribute.name + '="' + attribute.get_value() + '"'
		text += '/>'
	# Closing
	return text + '</svg>'

static func text_to_svg(text: String) -> TagSVG:
	var svg_tag := TagSVG.new()
	var parser := XMLParser.new()
	parser.open_buffer(text.to_ascii_buffer())
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name := parser.get_node_name()
			var attribute_dict := {}
			for i in range(parser.get_attribute_count()):
				attribute_dict[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
			
			# SVG tag requires width and height without defaults, so do the logic early.
			if node_name == "svg":
				var new_w: float = attribute_dict["width"].to_float() if\
						attribute_dict.has("width") else 0.0
				var new_h: float = attribute_dict["height"].to_float() if\
						attribute_dict.has("height") else 0.0
				var new_viewbox := AttributeRect.string_to_rect(attribute_dict["viewBox"])\
						if attribute_dict.has("viewBox") else Rect2(0, 0, new_w, new_h)
				svg_tag.set_canvas(new_w, new_h, new_viewbox)
			else:
				var tag: Tag
				match node_name:
					"circle": tag = TagCircle.new()
					"ellipse": tag = TagEllipse.new()
					"rect": tag = TagRect.new()
					"path": tag = TagPath.new()
					"line": tag = TagLine.new()
					_:
						tag = TagUnknown.new(node_name)
				
				var unknown: Array[AttributeUnknown] = []
				for element in attribute_dict:
					if tag.attributes.has(element):
						var attribute: Attribute = tag.attributes[element]
						if typeof(attribute.get_value()) == Variant.Type.TYPE_STRING:
							attribute.set_value(attribute_dict[element], false)
						elif typeof(attribute.get_value()) == Variant.Type.TYPE_FLOAT:
							attribute.set_value(attribute_dict[element].to_float())
					else:
						unknown.append(AttributeUnknown.new(element, attribute_dict[element]))
				tag.set_unknown_attributes(unknown)
				svg_tag.child_tags.append(tag)
	return svg_tag


# TODO Can definitely be improved.
static func get_svg_syntax_error(text: String) -> StringName:
	# Easy cases.
	if text.is_empty():
		return &"#err_empty_svg"
	
	if text.count("<") != text.count(">"):
		return &"#err_improper_nesting"
	
	var parser := XMLParser.new()
	parser.open_buffer(text.to_ascii_buffer())
	if text.begins_with("<?"):
		parser.skip_section()
	
	var nodes: Array[String] = []  # Serves as a sort of stack.
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name := parser.get_node_name()
			# First node must be "svg", last node must be closing "svg".
			if nodes.is_empty():
				if node_name != "svg":
					return &"#err_not_svg"
			
			var offset := parser.get_node_offset()
			# Don't add tags that were closed right away to the stack.
			var closure_pos := text.find("/>", offset)
			if closure_pos == -1 or not closure_pos < text.find(">", offset):
				nodes.append(node_name)
		
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			var node_name := parser.get_node_name()
			if nodes.is_empty() or node_name != nodes.back():
				return &"#err_improper_nesting"
			nodes.pop_back()
	return &"" if nodes.is_empty() else &"#err_improper_closing"
