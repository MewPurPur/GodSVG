# A syntax highlighter for SVGs, allows for more flexibility than CodeHighlighter.
class_name SVGHighlighter extends SyntaxHighlighter

var unrecognized_element_color: Color
var unrecognized_attribute_color: Color

var symbol_color := Color("abc9ff")
var string_color := Color("a1ffe0")
var comment_color := Color("cdcfd280")
var text_color := Color("cdcfeaac")
var cdata_color := Color("ffeda1ac")
var error_color := Color("ff866b")
var element_color := Color("ff8ccc"):
	set(new_value):
		element_color = new_value
		unrecognized_element_color = Color(new_value, new_value.a * 2 / 3.0)
var attribute_color := Color("bce0ff"):
	set(new_value):
		attribute_color = new_value
		unrecognized_attribute_color = Color(new_value, new_value.a * 2 / 3.0)


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var svg_text := get_text_edit().get_line(line)
	if svg_text.is_empty():
		return {}
	
	# We only return a color map, so this should deal with non-ASCII.
	for i in svg_text.length():
		if svg_text.unicode_at(i) >= 256:
			svg_text[i] = "a"
	
	var color_map: Dictionary[int, Dictionary] = {}
	var parser := XMLParser.new()
	parser.open_buffer(svg_text.to_utf8_buffer())
	while parser.read() == OK:
		var offset := parser.get_node_offset()
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				offset = svg_text.find("<", offset)
				var element_name := parser.get_node_name()
				color_map[offset] = {"color": symbol_color}
				offset += 1
				if element_name.is_empty():
					color_map[offset] = {"color": error_color}
					return color_map
				else:
					color_map[offset] = {"color": get_element_color(element_name)}
				offset += element_name.length()
				
				# Attribute names can't be directly after a quotation or after the element name.
				var expecting_attribute_name := false
				var expecting_end := true
				
				var current_attribute_name := ""
				var expecting_equal_sign := false
				var expecting_attribute_value := false
				# Loop through the attribute section.
				while offset < svg_text.length():
					var c := svg_text[offset]
					if expecting_end:
						if c in " \t\n\r":
							expecting_attribute_name = true
						elif c == ">" or (c == "/" and offset < svg_text.length() - 1 and\
						svg_text[offset + 1] == ">"):
							color_map[offset] = {"color": symbol_color}
							break
						else:
							if not expecting_attribute_name:
								color_map[offset] = {"color": error_color}
								return color_map
							else:
								expecting_end = false
								expecting_attribute_name = false
								current_attribute_name += c
					elif not current_attribute_name.is_empty():
						if c in " \t\n\r":
							color_map[offset - current_attribute_name.length()] = {"color":
									get_attribute_color(element_name, current_attribute_name)}
							current_attribute_name = ""
							expecting_equal_sign = true
						elif c in "/>":
							color_map[offset - current_attribute_name.length()] = {"color":
									get_attribute_color(element_name, current_attribute_name)}
							color_map[offset] = {"color": error_color}
							return color_map
						elif c == "=":
							color_map[offset - current_attribute_name.length()] = {"color":
									get_attribute_color(element_name, current_attribute_name)}
							color_map[offset] = {"color": symbol_color}
							current_attribute_name = ""
							expecting_attribute_value = true
						else:
							current_attribute_name += c
					elif expecting_equal_sign:
						if c == "=":
							color_map[offset] = {"color": symbol_color}
							expecting_equal_sign = false
							expecting_attribute_value = true
						else:
							if not c in " \t\n\r":
								color_map[offset] = {"color": error_color}
								return color_map
					elif expecting_attribute_value:
						if c == "'":
							color_map[offset] = {"color": string_color}
							expecting_attribute_value = false
							var end_pos := svg_text.find("'", offset + 1)
							if end_pos == -1:
								break
							else:
								offset = end_pos
								expecting_end = true
						elif c == '"':
							color_map[offset] = {"color": string_color}
							expecting_attribute_value = false
							var end_pos := svg_text.find('"', offset + 1)
							if end_pos == -1:
								break
							else:
								offset = end_pos
								expecting_end = true
						elif not c in " \t\n\r":
							color_map[offset] = {"color": error_color}
							return color_map
					offset += 1
				if not current_attribute_name.is_empty():
					color_map[svg_text.length() - current_attribute_name.length() - 1] =\
							{"color": get_attribute_color(element_name, current_attribute_name)}
			XMLParser.NODE_ELEMENT_END:
				offset = svg_text.find("<", offset)
				var element_name := parser.get_node_name()
				color_map[offset] = {"color": symbol_color}
				offset += 2
				color_map[offset] = {"color": get_element_color(element_name)}
				offset += element_name.length()
				color_map[offset] = {"color": symbol_color}
			XMLParser.NODE_TEXT:
				color_map[offset] = {"color": text_color}
			XMLParser.NODE_CDATA:
				color_map[offset] = {"color": cdata_color}
			_:
				color_map[offset] = {"color": comment_color}
	
	return color_map


# Helpers.
func get_element_color(element_name: String) -> Color:
	return element_color if element_name in DB.recognized_elements\
			else unrecognized_element_color

func get_attribute_color(element_name: String, attribute_name: String) -> Color:
	return attribute_color if DB.is_attribute_recognized(element_name,
			attribute_name) else unrecognized_attribute_color
