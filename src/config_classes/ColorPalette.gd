# A resource for the color palettes that are listed in the color picker.
class_name ColorPalette extends Resource

enum Preset {EMPTY, PURE, GRAYSCALE}

signal layout_changed

# The title must be unique.
@export var title: String:
	set(new_value):
		if title != new_value:
			title = new_value
			emit_changed()

@export var colors: PackedStringArray  # Colors must be unique within a palette.
@export var color_names: PackedStringArray

func _init(new_title := "", new_preset := Preset.EMPTY) -> void:
	title = new_title
	apply_preset(new_preset)
	changed.connect(GlobalSettings.save, CONNECT_DEFERRED)

func add_color() -> void:
	colors.append("none")
	color_names.append("")
	emit_changed()
	layout_changed.emit()

func remove_color(idx: int) -> void:
	colors.remove_at(idx)
	color_names.remove_at(idx)
	emit_changed()
	layout_changed.emit()

func move_color(old_idx: int, new_idx: int) -> void:
	if old_idx == new_idx:
		return
	
	if old_idx < new_idx:
		new_idx -= 1
	
	var old_color := colors[old_idx]
	colors.remove_at(old_idx)
	colors.insert(new_idx, old_color)
	var old_name := color_names[old_idx]
	color_names.remove_at(old_idx)
	color_names.insert(new_idx, old_name)
	emit_changed()
	layout_changed.emit()

func modify_color(idx: int, new_color: String) -> void:
	colors[idx] = new_color
	emit_changed()

func modify_color_name(idx: int, new_color_name: String) -> void:
	color_names[idx] = new_color_name
	emit_changed()

func apply_preset(new_preset: Preset) -> void:
	var new_colors: PackedStringArray
	var new_color_names: PackedStringArray
	
	match new_preset:
		Preset.EMPTY:
			new_colors = PackedStringArray()
			new_color_names = PackedStringArray()
		Preset.PURE:
			new_colors = PackedStringArray(["#fff", "#000", "#f00", "#0f0", "#00f", "#ff0",
					"#f0f", "#0ff"])
			new_color_names = PackedStringArray(["White", "Black", "Red", "Green", "Blue",
					"Yellow", "Magenta", "Cyan"])
		Preset.GRAYSCALE:
			new_colors = PackedStringArray(["#000", "#1a1a1a", "#333", "#4d4d4d", "#666",
					"#808080", "#999", "#b3b3b3", "#ccc", "#e6e6e6", "#fff"])
			new_color_names = PackedStringArray(["Black", "10% Gray", "20% Gray", "30% Gray",
					"40% Gray", "50% Gray", "60% Gray", "70% Gray", "80% Gray", "90% Gray",
					"White"])
	
	if colors != new_colors or color_names != new_color_names:
		colors = new_colors
		color_names = new_color_names
		emit_changed()
		layout_changed.emit()


func to_text() -> String:
	var text := '<palette title="%s">\n' % title
	for i in colors.size():
		text += '\t<color value="%s"' % colors[i]
		if not color_names[i].is_empty():
			text += ' name="%s"' % color_names[i]
		text += "/>\n"
	return text + "</palette>"

static func text_to_palettes(text: String) -> Array[ColorPalette]:
	var parser := XMLParser.new()
	parser.open_buffer(text.to_utf8_buffer())
	var parsed_title: String
	var parsed_colors := PackedStringArray()
	var parsed_color_names := PackedStringArray()
	var palettes: Array[ColorPalette] = []
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				if parser.get_node_name() == "palette":
					parsed_title = parser.get_named_attribute_value_safe("title")
				elif parser.get_node_name() == "color":
					parsed_colors.append(parser.get_named_attribute_value_safe("value"))
					parsed_color_names.append(parser.get_named_attribute_value_safe("name"))
			XMLParser.NODE_ELEMENT_END:
				var new_palette := ColorPalette.new(parsed_title)
				new_palette.colors = parsed_colors.duplicate()
				new_palette.color_names = parsed_color_names.duplicate()
				parsed_colors.clear()
				parsed_color_names.clear()
				parsed_title = ""
	return palettes

static func is_valid_palette(text: String) -> bool:
	var parser := XMLParser.new()
	parser.open_buffer(text.to_utf8_buffer())
	parser.read()
	return parser.get_node_type() == XMLParser.NODE_ELEMENT and\
			parser.get_node_name() == "palette"
