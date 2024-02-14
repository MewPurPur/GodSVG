## A syntax highlighter for SVGs, allows for more flexibility than CodeHighlighter.
class_name SVGHighlighter extends SyntaxHighlighter

@export var symbol_color := Color("abc9ff")
@export var tag_color := Color("ff8ccc")
@export var attribute_color := Color("bce0ff")
@export var string_color := Color("a1ffe0")
@export var comment_color := Color("cdcfd280")
@export var text_color := Color("cdcfeaac")
@export var error_color := Color("ff866b")

var unknown_tag_color := tag_color.darkened(0.3)
var unknown_attribute_color := attribute_color.darkened(0.3)

func is_attribute_symbol(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or\
	(c >= "0" and c <= "9") or c == "-" or c == ":"

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var svg_text := get_text_edit().get_line(line)
	if svg_text.is_empty():
		return {}
	
	var color_map := {}  # Dictionary{int: Dictionary{String: Color}}
	var parser := XMLParser.new()
	parser.open_buffer(svg_text.to_utf8_buffer())
	while parser.read() == OK:
		var offset := parser.get_node_offset()
		match parser.get_node_type():
			XMLParser.NODE_COMMENT:
				color_map[offset] = {"color": comment_color}
			XMLParser.NODE_CDATA, XMLParser.NODE_TEXT:
				color_map[offset] = {"color": text_color}
			XMLParser.NODE_ELEMENT_END:
				offset = svg_text.find("<", offset)
				var tag_name := parser.get_node_name()
				color_map[offset] = {"color": symbol_color}
				offset += 2
				color_map[offset] = {"color":
						tag_color if SVGDB.is_tag_known(tag_name) else unknown_tag_color}
				offset += tag_name.length()
				color_map[offset] = {"color": symbol_color}
			XMLParser.NODE_ELEMENT:
				offset = svg_text.find("<", offset)
				var tag_name := parser.get_node_name()
				color_map[offset] = {"color": symbol_color}
				offset += 1
				color_map[offset] = {"color":
						tag_color if SVGDB.is_tag_known(tag_name) else unknown_tag_color}
				offset += tag_name.length()
				color_map[offset] = {"color": symbol_color}
				
				# Parsing stuff inside an element.
				if offset >= svg_text.length() or svg_text[offset] == ">":
					continue
				offset += 1
				# Find where the current tag ends to be safe.
				var next_end: int
				var next_end_a := svg_text.find("/>", offset)
				var next_end_b := svg_text.find(">", offset)
				if next_end_a == -1 and next_end_b != -1:
					next_end = next_end_b
				elif next_end_b == -1 and next_end_a != -1:
					next_end = next_end_a
				elif next_end_b != -1 and next_end_a != -1:
					next_end = mini(next_end_a, next_end_b)
				else:
					return color_map
				
				# Highlight the attribute name and equal sign.
				while offset < next_end:
					var next_equal_sign := svg_text.find("=", offset)
					if next_equal_sign != -1 and next_equal_sign < next_end:
						var is_known := SVGDB.is_attribute_known(tag_name,
								svg_text.substr(offset, next_equal_sign - offset).strip_edges())
						while not is_attribute_symbol(svg_text[offset]):
							offset += 1
						color_map[offset] = {"color": attribute_color if is_known\
								else unknown_attribute_color}
						while offset < next_equal_sign:
							if not is_attribute_symbol(svg_text[offset]):
								color_map[offset] = {"color": error_color}
								break
							offset += 1
						offset = next_equal_sign
						color_map[offset] = {"color": symbol_color}
					
					# Highlight the attribute value.
					offset += 1
					color_map[offset] = {"color": error_color}
					var next_double_quote_pos := svg_text.find('"', offset)
					var next_single_quote_pos := svg_text.find("'", offset)
					var in_double_quote := true
					var next_quote_pos := next_double_quote_pos
					if next_single_quote_pos != -1 and (next_double_quote_pos == -1 or\
					next_single_quote_pos < next_double_quote_pos):
						in_double_quote = false
						next_quote_pos = next_single_quote_pos
					offset = next_quote_pos
					color_map[offset] = {"color": string_color}
					if next_quote_pos == -1 or next_quote_pos >\
					mini(svg_text.find("/", offset), svg_text.find(">", offset)):
						offset = mini(svg_text.find("/", offset), svg_text.find(">", offset))
						break
					else:
						next_quote_pos = svg_text.find(
								'"' if in_double_quote else "'", offset + 1)
						offset = next_quote_pos + 1
						color_map[offset] = {"color": symbol_color}
						if next_quote_pos == -1:
							return color_map
						else:
							offset = next_quote_pos + 1
				# Finish parsing.
				color_map[offset] = {"color": symbol_color}
	
	return color_map

