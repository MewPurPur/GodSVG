extends AttributeEditor

const named_colors := {  # Dictionary{String: Color}
	"aliceblue": Color("#f0f8ff"),
	"antiquewhite": Color("#faebd7"),
	"aqua": Color("#00ffff"),
	"aquamarine": Color("#7fffd4"),
	"azure": Color("#f0ffff"),
	"beige": Color("#f5f5dc"),
	"bisque": Color("#ffe4c4"),
	"black": Color("#000000"),
	"blanchedalmond": Color("#ffebcd"),
	"blue": Color("#0000ff"),
	"blueviolet": Color("#8a2be2"),
	"brown": Color("#a52a2a"),
	"burlywood": Color("#deb887"),
	"cadetblue": Color("#5f9ea0"),
	"chartreuse": Color("#7fff00"),
	"chocolate": Color("#d2691e"),
	"coral": Color("#ff7f50"),
	"cornflowerblue": Color("#6495ed"),
	"cornsilk": Color("#fff8dc"),
	"crimson": Color("#dc143c"),
	"cyan": Color("#00ffff"),
	"darkblue": Color("#00008b"),
	"darkcyan": Color("#008b8b"),
	"darkgoldenrod": Color("#b8860b"),
	"darkgray": Color("#a9a9a9"),
	"darkgreen": Color("#006400"),
	"darkgrey": Color("#a9a9a9"),
	"darkkhaki": Color("#bdb76b"),
	"darkmagenta": Color("#8b008b"),
	"darkolivegreen": Color("#556b2f"),
	"darkorange": Color("#ff8c00"),
	"darkorchid": Color("#9932cc"),
	"darkred": Color("#8b0000"),
	"darksalmon": Color("#e9967a"),
	"darkseagreen": Color("#8fbc8f"),
	"darkslateblue": Color("#483d8b"),
	"darkslategray": Color("#2f4f4f"),
	"darkslategrey": Color("#2f4f4f"),
	"darkturquoise": Color("#00ced1"),
	"darkviolet": Color("#9400d3"),
	"deeppink": Color("#ff1493"),
	"deepskyblue": Color("#00bfff"),
	"dimgray": Color("#696969"),
	"dimgrey": Color("#696969"),
	"dodgerblue": Color("#1e90ff"),
	"firebrick": Color("#b22222"),
	"floralwhite": Color("#fffaf0"),
	"forestgreen": Color("#228b22"),
	"fuchsia": Color("#ff00ff"),
	"gainsboro": Color("#dcdcdc"),
	"ghostwhite": Color("#f8f8ff"),
	"gold": Color("#ffd700"),
	"goldenrod": Color("#daa520"),
	"gray": Color("#808080"),
	"green": Color("#008000"),
	"greenyellow": Color("#adff2f"),
	"grey": Color("#808080"),
	"honeydew": Color("#f0fff0"),
	"hotpink": Color("#ff69b4"),
	"indianred": Color("#cd5c5c"),
	"indigo": Color("#4b0082"),
	"ivory": Color("#fffff0"),
	"khaki": Color("#f0e68c"),
	"lavender": Color("#e6e6fa"),
	"lavenderblush": Color("#fff0f5"),
	"lawngreen": Color("#7cfc00"),
	"lemonchiffon": Color("#fffacd"),
	"lightblue": Color("#add8e6"),
	"lightcoral": Color("#f08080"),
	"lightcyan": Color("#e0ffff"),
	"lightgoldenrodyellow": Color("#fafad2"),
	"lightgray": Color("#d3d3d3"),
	"lightgreen": Color("#90ee90"),
	"lightgrey": Color("#d3d3d3"),
	"lightpink": Color("#ffb6c1"),
	"lightsalmon": Color("#ffa07a"),
	"lightseagreen": Color("#20b2aa"),
	"lightskyblue": Color("#87cefa"),
	"lightslategray": Color("#778899"),
	"lightslategrey": Color("#778899"),
	"lightsteelblue": Color("#b0c4de"),
	"lightyellow": Color("#ffffe0"),
	"lime": Color("#00ff00"),
	"limegreen": Color("#32cd32"),
	"linen": Color("#faf0e6"),
	"magenta": Color("#ff00ff"),
	"maroon": Color("#800000"),
	"mediumaquamarine": Color("#66cdaa"),
	"mediumblue": Color("#0000cd"),
	"mediumorchid": Color("#ba55d3"),
	"mediumpurple": Color("#9370db"),
	"mediumseagreen": Color("#3cb371"),
	"mediumslateblue": Color("#7b68ee"),
	"mediumspringgreen": Color("#00fa9a"),
	"mediumturquoise": Color("#48d1cc"),
	"mediumvioletred": Color("#c71585"),
	"midnightblue": Color("#191970"),
	"mintcream": Color("#f5fffa"),
	"mistyrose": Color("#ffe4e1"),
	"moccasin": Color("#ffe4b5"),
	"navajowhite": Color("#ffdead"),
	"navy": Color("#000080"),
	"oldlace": Color("#fdf5e6"),
	"olive": Color("#808000"),
	"olivedrab": Color("#6b8e23"),
	"orange": Color("#ffa500"),
	"orangered": Color("#ff4500"),
	"orchid": Color("#da70d6"),
	"palegoldenrod": Color("#eee8aa"),
	"palegreen": Color("#98fb98"),
	"paleturquoise": Color("#afeeee"),
	"palevioletred": Color("#db7093"),
	"papayawhip": Color("#ffefd5"),
	"peachpuff": Color("#ffdab9"),
	"peru": Color("#cd853f"),
	"pink": Color("#ffc0cb"),
	"plum": Color("#dda0dd"),
	"powderblue": Color("#b0e0e6"),
	"purple": Color("#800080"),
	"red": Color("#ff0000"),
	"rosybrown": Color("#bc8f8f"),
	"royalblue": Color("#4169e1"),
	"saddlebrown": Color("#8b4513"),
	"salmon": Color("#fa8072"),
	"sandybrown": Color("#f4a460"),
	"seagreen": Color("#2e8b57"),
	"seashell": Color("#fff5ee"),
	"sienna": Color("#a0522d"),
	"silver": Color("#c0c0c0"),
	"skyblue": Color("#87ceeb"),
	"slateblue": Color("#6a5acd"),
	"slategray": Color("#708090"),
	"slategrey": Color("#708090"),
	"snow": Color("#fffafa"),
	"springgreen": Color("#00ff7f"),
	"steelblue": Color("#4682b4"),
	"tan": Color("#d2b48c"),
	"teal": Color("#008080"),
	"thistle": Color("#d8bfd8"),
	"tomato": Color("#ff6347"),
	"turquoise": Color("#40e0d0"),
	"violet": Color("#ee82ee"),
	"wheat": Color("#f5deb3"),
	"white": Color("#ffffff"),
	"whitesmoke": Color("#f5f5f5"),
	"yellow": Color("#ffff00"),
	"yellowgreen": Color("#9acd32")
}

@onready var color_button: Button = $Button
@onready var color_edit: LineEdit = $LineEdit
@onready var color_picker: Popup = $ColorPopup

@export var checkerboard: Texture2D

signal value_changed(new_value: String)
var _value: String  # Must not be updated directly.

func set_value(new_value: String, emit_value_changed := true):
	var old_value := _value
	_value = validate(new_value)
	set_text_tint()
	if _value != old_value and emit_value_changed:
		value_changed.emit(_value if (is_color_named_or_none(_value)) else "#" + _value)

func get_value() -> String:
	return _value


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		set_value(attribute.get_value())
	color_edit.text = get_value()
	color_edit.tooltip_text = attribute_name

func validate(new_value: String) -> String:
	if is_color_named_or_none(new_value) or new_value.is_valid_html_color():
		return new_value.trim_prefix("#")
	return "000"

func _on_value_changed(new_value: String) -> void:
	color_edit.text = new_value.trim_prefix("#")
	queue_redraw()
	if attribute != null:
		attribute.set_value(new_value)

func _on_button_pressed() -> void:
	color_picker.popup(Utils.calculate_popup_rect(
			color_edit.global_position, color_edit.size, color_picker.size))

func _draw() -> void:
	var button_size := color_button.get_size()
	var line_edit_size := color_edit.get_size()
	draw_set_transform(Vector2(line_edit_size.x, 1))
	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	if named_colors.has(get_value()):
		stylebox.bg_color = named_colors[get_value()]
	else:
		stylebox.bg_color = Color.from_string(get_value(), Color(0, 0, 0, 0))
	draw_texture(checkerboard, Vector2.ZERO)
	draw_style_box(stylebox, Rect2(Vector2.ZERO, button_size - Vector2(1, 2)))


func _on_focus_exited() -> void:
	set_value(color_edit.text)

func _on_text_submitted(new_text: String) -> void:
	set_value(new_text)


func _on_color_picked(new_color: String) -> void:
	set_value(new_color)

func is_color_named_or_none(color: String) -> bool:
	return color == "none" or named_colors.has(color)

func is_color_valid(color: String) -> bool:
	return color.is_valid_html_color() or is_color_named_or_none(color)


func _on_button_resized() -> void:
	# Not sure why this is needed, but the button doesn't have a correct size at first
	# which screws with the drawing logic.
	queue_redraw()


func set_text_tint() -> void:
	if color_edit != null:
		if attribute != null and get_value() == attribute.default.trim_prefix("#"):
			color_edit.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
		else:
			color_edit.remove_theme_color_override(&"font_color")

func _on_line_edit_text_changed(new_text: String) -> void:
	if is_color_valid(new_text):
		color_edit.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.6))
	else:
		color_edit.add_theme_color_override(&"font_color", Color(1.0, 0.6, 0.6))
