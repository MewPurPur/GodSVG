## A syntax highlighter for SVGs, allows for more flexibility than CodeHighlighter.
class_name SVGHighlighter extends SyntaxHighlighter

@export var symbol_color := Color("abc9ff")
@export var known_tag_color := Color("ff8ccc")
@export var known_attribute_color := Color("bce0ff")
@export var string_color := Color("a1ffe0")
@export var comment_color := Color("cdcfd280")

var unknown_tag_color := known_tag_color.darkened(0.3)
var unknown_attribute_color := known_attribute_color.darkened(0.3)

func is_attribute_symbol(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "-"

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	var color_map := {}  # Dictionary{int: Dictionary{String: Color}}
	var parser := XMLParser.new()
	var svg_text := get_text_edit().get_line(line)
	parser.open_buffer(svg_text.to_ascii_buffer())
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_COMMENT, XMLParser.NODE_CDATA, XMLParser.NODE_TEXT:
				var offset := parser.get_node_offset()
				color_map[offset] = {"color": comment_color}
			XMLParser.NODE_ELEMENT_END:
				var offset := parser.get_node_offset()
				var tag_name := parser.get_node_name()
				color_map[offset] = {"color": symbol_color}
				offset += 2
				color_map[offset] = {"color":
						known_tag_color if SVGDB.is_tag_known(tag_name) else unknown_tag_color}
				offset += tag_name.length()
				color_map[offset] = {"color": symbol_color}
			XMLParser.NODE_ELEMENT:
				var offset := parser.get_node_offset()
				var tag_name := parser.get_node_name()
				color_map[offset] = {"color": symbol_color}
				offset += 1
				color_map[offset] = {"color":
						known_tag_color if SVGDB.is_tag_known(tag_name) else unknown_tag_color}
				offset += tag_name.length()
				color_map[offset] = {"color": symbol_color}
				
				# Parsing stuff inside an element.
				offset += 1
				var attributes_parsed := 0
				while offset < svg_text.length() and\
				attributes_parsed < parser.get_attribute_count():
					# Parse attribute name.
					var attribute_start_offset := offset
					while not is_attribute_symbol(svg_text[offset]):
						if offset == svg_text.length():
							break
						offset += 1
					var attribute_name := ""
					while is_attribute_symbol(svg_text[offset]):
						if offset == svg_text.length():
							break
						attribute_name += svg_text[offset]
						offset += 1
					
					color_map[attribute_start_offset] = {"color": known_attribute_color\
							if SVGDB.is_attribute_known(tag_name, attribute_name)\
							else unknown_attribute_color}
					
					# Parse equal sign.
					var next_equal_pos := svg_text.find("=", offset)
					var next_end_a := svg_text.find("/>", offset)
					var next_end_b := svg_text.find(">", offset)
					var next_end: int
					if next_end_a == -1 and next_end_b != -1:
						next_end = next_end_b
					elif next_end_b == -1 and next_end_a != -1:
						next_end = next_end_a
					elif next_end_b != -1 and next_end_a != -1:
						next_end = mini(next_end_a, next_end_b)
					else:
						next_end = -1
					
					if next_end == -1:
						return color_map
					if next_equal_pos == -1 or next_equal_pos > next_end:
						offset = next_end
						break
					else:
						offset = next_equal_pos
						color_map[offset] = {"color": symbol_color}
					
					# Parse attribute value.
					var next_quote_pos := svg_text.find('"', offset)
					if next_quote_pos == -1 or next_quote_pos >\
					minf(svg_text.find("/", offset), svg_text.find(">", offset)):
						offset = mini(svg_text.find("/", offset), svg_text.find(">", offset))
						break
					else:
						offset = next_quote_pos
						color_map[offset] = {"color": string_color}
						next_quote_pos = svg_text.find('"', offset + 1)
						if next_quote_pos == -1:
							return color_map
						else:
							offset = next_quote_pos + 1
							attributes_parsed += 1
				
				# Finish parsing.
				color_map[offset] = {"color": symbol_color}
	
	return color_map

