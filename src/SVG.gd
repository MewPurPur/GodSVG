extends Node

const display_path := "user://display.svg"

var string := ""
var data := SVGData.new()

var selected_tag_idx: int

signal parsing_finished(err_text: String)


func _ready() -> void:
	sync_string()
	SVG.data.resized.connect(sync_string)
	SVG.data.attribute_changed.connect(sync_string)
	SVG.data.tag_added.connect(sync_string)
	SVG.data.tag_deleted.connect(sync_string)
	SVG.data.tag_moved.connect(sync_string)
	SVG.data.changed_unknown.connect(sync_string)

func sync_string() -> void:
	tags_to_string()

func sync_data() -> void:
	var error_text := get_svg_error()
	parsing_finished.emit(error_text)
	if error_text.is_empty():
		string_to_tags()
		data.changed_unknown.emit()


func tags_to_string() -> void:
	var w := data.w
	var h := data.h
	# Opening
	string = '<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}"'.format(
			{"w": w, "h": h})
	string += ' xmlns="http://www.w3.org/2000/svg">'
	# Inner tags
	for tag in data.tags:
		string += '<' + tag.title
		for attribute_key in tag.attributes:
			var attribute: SVGAttribute = tag.attributes[attribute_key]
			if attribute.value == attribute.default:
				continue
			
			match attribute.type:
				SVGAttribute.Type.INT:
					string += ' %s="%d"' % [attribute_key, attribute.value]
				SVGAttribute.Type.FLOAT, SVGAttribute.Type.UFLOAT, SVGAttribute.Type.NFLOAT:
					string += ' %s="' % attribute_key + String.num(attribute.value, 4) + '"'
				SVGAttribute.Type.COLOR, SVGAttribute.Type.PATHDATA, SVGAttribute.Type.ENUM:
					string += ' %s="%s"' % [attribute_key, attribute.value]
		string += '/>'
	# Closing
	string += '</svg>'

func string_to_tags() -> void:
	var new_tags: Array[SVGTag] = []
	var parser := XMLParser.new()
	parser.open_buffer(string.to_ascii_buffer())
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name := parser.get_node_name()
			var attribute_dict := {}
			for i in range(parser.get_attribute_count()):
				attribute_dict[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
			
			if node_name == "svg":
				data.w = attribute_dict["width"] if attribute_dict.has("width") else 0
				data.h = attribute_dict["height"] if attribute_dict.has("height") else 0
			else:
				var tag: SVGTag
				match node_name:
					"circle": tag = SVGTagCircle.new()
					"ellipse": tag = SVGTagEllipse.new()
					"rect": tag = SVGTagRect.new()
					"path": tag = SVGTagPath.new()
					_: tag = SVGTag.new()
				for element in attribute_dict:
					if tag.attributes.has(element):
						tag.attributes[element].value = attribute_dict[element]
				new_tags.append(tag)
	data.tags = new_tags


# TODO Can definitely be improved.
func get_svg_error() -> String:
	# Easy cases.
	if string.is_empty():
		return "SVG is empty."
	
	var parser := XMLParser.new()
	parser.open_buffer(string.to_ascii_buffer())
	if string.begins_with("<?"):
		parser.skip_section()
	
	var nodes: Array[String] = []  # Serves as a sort of stack.
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name := parser.get_node_name()
			# First node must be "svg", last node must be closing "svg".
			if nodes.is_empty():
				if node_name != "svg":
					return "Not a SVG."
			
			var offset := parser.get_node_offset()
			# Don't add tags that were closed right away to the stack.
			var closure_pos := string.find("/>", offset)
			if closure_pos == -1 or not closure_pos < string.find(">", offset):
				nodes.append(node_name)
			
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			var node_name := parser.get_node_name()
			if nodes.is_empty() or node_name != nodes.back():
				return "Improper nesting."
			nodes.pop_back()
	return "" if nodes.is_empty() else "Not all tags are closed."
