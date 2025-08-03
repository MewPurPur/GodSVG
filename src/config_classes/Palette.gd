# A resource for the color palettes that are listed in the color picker.
class_name Palette extends ConfigResource

enum Preset {EMPTY, PURE, GRAYSCALE}

var _presets: Dictionary[Preset, Array] = {
	Preset.EMPTY: [PackedStringArray(), PackedStringArray()],
	Preset.PURE: [PackedStringArray(["#fff", "#000", "#f00", "#0f0", "#00f", "#ff0",
			"#f0f", "#0ff"]), PackedStringArray(["White", "Black", "Red", "Green", "Blue",
			"Yellow", "Magenta", "Cyan"])],
	Preset.GRAYSCALE: [PackedStringArray(["#000", "#1a1a1a", "#333", "#4d4d4d", "#666",
			"#808080", "#999", "#b3b3b3", "#ccc", "#e6e6e6", "#fff"]), PackedStringArray([
			"Black", "10% Gray", "20% Gray", "30% Gray", "40% Gray", "50% Gray", "60% Gray",
			"70% Gray", "80% Gray", "90% Gray", "White"])],
}

signal layout_changed

# The title must be unique.
@export var title: String:
	set(new_value):
		if title != new_value:
			title = new_value
			emit_changed()

@export var _colors: PackedStringArray:
	set(new_value):
		if _colors != new_value:
			_colors = new_value
			_validate()
			emit_changed()

@export var _color_names: PackedStringArray:
	set(new_value):
		if _color_names != new_value:
			_color_names = new_value
			_validate()
			emit_changed()


func _init(new_title := "", new_preset := Preset.EMPTY) -> void:
	title = new_title
	apply_preset(new_preset)
	super()


func get_colors() -> PackedStringArray:
	return _colors

func get_color_names() -> PackedStringArray:
	return _color_names

func get_color(idx: int) -> String:
	return _colors[idx]

func get_color_name(idx: int) -> String:
	return _color_names[idx]

func get_color_count() -> int:
	return _colors.size()

func setup(new_colors: PackedStringArray, new_color_names: PackedStringArray) -> void:
	_colors = new_colors.duplicate()
	_color_names = new_color_names.duplicate()
	_validate()
	emit_changed()

func insert_color(idx: int, color: String, color_name: String) -> void:
	_colors.insert(idx, color)
	_color_names.insert(idx, color_name)
	emit_changed()
	layout_changed.emit()

func add_new_color() -> void:
	_colors.append("black")
	_color_names.append("")
	emit_changed()
	layout_changed.emit()

func remove_color(idx: int) -> void:
	_colors.remove_at(idx)
	_color_names.remove_at(idx)
	emit_changed()
	layout_changed.emit()

func move_color(old_idx: int, new_idx: int) -> void:
	if old_idx == new_idx:
		return
	
	if old_idx < new_idx:
		new_idx -= 1
	
	var old_color := _colors[old_idx]
	_colors.remove_at(old_idx)
	_colors.insert(new_idx, old_color)
	var old_name := _color_names[old_idx]
	_color_names.remove_at(old_idx)
	_color_names.insert(new_idx, old_name)
	emit_changed()
	layout_changed.emit()

func modify_color(idx: int, new_color: String) -> void:
	_colors[idx] = new_color
	emit_changed()

func modify_color_name(idx: int, new_color_name: String) -> void:
	_color_names[idx] = new_color_name
	emit_changed()

func apply_preset(new_preset: Preset) -> void:
	if not is_same_as_preset(new_preset):
		_colors = _presets[new_preset][0].duplicate()
		_color_names = _presets[new_preset][1].duplicate()
		emit_changed()
		layout_changed.emit()

func is_same_as_preset(preset: Preset) -> bool:
	return _colors == _presets[preset][0] and _color_names == _presets[preset][1]

func has_unique_definitions() -> bool:
	var dict: Dictionary[Color, Array] = {}
	for i in _color_names.size():
		var color := ColorParser.text_to_color(_colors[i])
		if dict.has(color) and dict[color].has(_color_names[i]):
			return false
		elif dict.has(color):
			dict[color].append(_color_names[i])
		else:
			dict[color] = [_color_names[i]]
	return true


func to_text() -> String:
	var text := '<palette title="%s">\n' % title
	for i in _colors.size():
		text += '\t<color value="%s"' % _colors[i]
		if not _color_names[i].is_empty():
			text += ' name="%s"' % _color_names[i]
		text += "/>\n"
	return text + "</palette>"

func _validate() -> void:
	for i in range(_colors.size() - 1, -1, -1):
		if not ColorParser.is_valid(_colors[i]):
			_colors[i] = "#000"
	_color_names.resize(_colors.size())


static func text_to_palettes(text: String) -> Array[Palette]:
	var parser := XMLParser.new()
	parser.open_buffer(text.to_utf8_buffer())
	var parsed_title: String
	var parsed_colors := PackedStringArray()
	var parsed_color_names := PackedStringArray()
	var palettes: Array[Palette] = []
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				if parser.get_node_name() == "palette":
					parsed_title = parser.get_named_attribute_value_safe("title").strip_edges()
				elif parser.get_node_name() == "color":
					var invalid_color := Color(255, 255, 255)
					var col_str := parser.get_named_attribute_value_safe("value").strip_edges()
					if ColorParser.text_to_color(col_str, invalid_color) != invalid_color:
						parsed_color_names.append(
								parser.get_named_attribute_value_safe("name").strip_edges())
						parsed_colors.append(col_str)
			XMLParser.NODE_ELEMENT_END:
				if parser.get_node_name() == "palette":
					var new_palette := Palette.new(parsed_title)
					new_palette.setup(parsed_colors, parsed_color_names)
					parsed_colors.clear()
					parsed_color_names.clear()
					parsed_title = ""
					palettes.append(new_palette)
	return palettes

static func is_valid_palette(text: String) -> bool:
	if text.is_empty():
		return false
	
	var parser := XMLParser.new()
	parser.open_buffer(text.to_utf8_buffer())
	parser.read()
	while parser.read() == OK:
		if parser.get_node_type() in [XMLParser.NODE_COMMENT, XMLParser.NODE_TEXT,
		XMLParser.NODE_UNKNOWN]:
			continue
		
		return parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() == "palette"
	return false
