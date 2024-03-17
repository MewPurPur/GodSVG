extends Button

const code_font = preload("res://visual/fonts/FontMono.ttf")
const checkerboard = preload("res://visual/icons/backgrounds/Checkerboard.svg")

var color_palette: ColorPalette
var idx := -1  # Index inside the palette.

func _ready() -> void:
	# _make_custom_tooltip() requires some text to work.
	tooltip_text = "lmofa"

func _draw() -> void:
	var color := color_palette.colors[idx]
	var parsed_color := Color.from_string(color, Color(0, 0, 0))
	var bounds := Vector2(2, 2)
	if parsed_color.a != 1 or color == "none":
		draw_texture_rect(checkerboard, Rect2(bounds, size - bounds * 2), false)
	if color != "none":
		draw_rect(Rect2(bounds, size - bounds * 2), color)

func _make_custom_tooltip(_for_text: String) -> Object:
	var rtl := RichTextLabel.new()
	rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	rtl.fit_content = true
	rtl.bbcode_enabled = true
	rtl.add_theme_font_override("mono_font", code_font)
	# Set up the text.
	var color_name := color_palette.color_names[idx]
	if not color_name.is_empty():
		rtl.add_text(color_name)
		rtl.newline()
	rtl.push_mono()
	rtl.add_text(color_palette.colors[idx])
	return rtl
