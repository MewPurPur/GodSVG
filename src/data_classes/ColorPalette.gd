class_name ColorPalette extends Resource

@export var title: String  # Color palettes must be uniquely named.
@export var colors: Array[String]  # Colors must be unique within a palette.
@export var color_names: Array[String]

func _init(new_title := "", new_colors: Array[String] = [],
new_color_names: Array[String] = []) -> void:
	title = new_title
	colors = new_colors
	color_names = new_color_names
	color_names.resize(colors.size())
	changed.connect(GlobalSettings.save_palettes)

func add_color() -> void:
	colors.append("none")
	color_names.append("")
	emit_changed()

func remove_color(idx: int) -> void:
	colors.remove_at(idx)
	color_names.remove_at(idx)
	emit_changed()

func move_color(old_idx: int, new_idx: int) -> void:
	if old_idx == new_idx:
		return
	
	if old_idx < new_idx:
		new_idx -= 1
	
	colors.insert(new_idx, colors.pop_at(old_idx))
	color_names.insert(new_idx, color_names.pop_at(old_idx))
	emit_changed()

func modify_title(new_title: String) -> void:
	title = new_title
	emit_changed()

func modify_color(idx: int, new_color: String) -> void:
	colors[idx] = new_color
	emit_changed()

func modify_color_name(idx: int, new_color_name: String) -> void:
	color_names[idx] = new_color_name
	emit_changed()


func to_text() -> String:
	var text := '<palette title="%s">\n' % title
	for i in colors.size():
		text += '\t<color value="%s"' % colors[i]
		if not color_names[i].is_empty():
			text += ' name="%s"' % color_names[i]
		text += "/>\n"
	return text + "</palette>"

static func from_text(text: String) -> ColorPalette:
	var xml_parser := XMLParser.new()
	xml_parser.open_buffer(text.to_utf8_buffer())
	var parsed_title: String
	var parsed_colors: Array[String] = []
	var parsed_color_names: Array[String] = []
	while xml_parser.read() == OK:
		if xml_parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		if xml_parser.get_node_name() == "palette":
			parsed_title = xml_parser.get_named_attribute_value_safe("title")
		elif xml_parser.get_node_name() == "color":
			parsed_colors.append(xml_parser.get_named_attribute_value_safe("value"))
			parsed_color_names.append(xml_parser.get_named_attribute_value_safe("name"))
	return ColorPalette.new(parsed_title, parsed_colors, parsed_color_names)

static func is_valid_palette(text: String) -> bool:
	var xml_parser := XMLParser.new()
	xml_parser.open_buffer(text.to_utf8_buffer())
	xml_parser.read()
	return xml_parser.get_node_type() == XMLParser.NODE_ELEMENT and\
			xml_parser.get_node_name() == "palette"
