extends Button

const bounds = Vector2(2, 2)

const checkerboard = preload("res://visual/icons/backgrounds/Checkerboard.svg")

var color_palette: ColorPalette
var idx := -1  # Index inside the palette.

var ci := get_canvas_item()
var gradient_texture: GradientTexture2D

func _ready() -> void:
	tooltip_text = "lmofa"  # _make_custom_tooltip() requires some text to work.
	# TODO remove this when #94584 is fixed.
	var color := color_palette.colors[idx]
	if ColorParser.is_valid_url(color):
		var id := color.substr(5, color.length() - 6)
		var gradient_element := SVG.root_element.get_element_by_id(id)
		if gradient_element != null:
			gradient_texture = gradient_element.generate_texture()

func _draw() -> void:
	var color := color_palette.colors[idx]
	var inside_rect := Rect2(bounds, size - bounds * 2)
	if ColorParser.is_valid_url(color):
		checkerboard.draw_rect(ci, inside_rect, false)
		var id := color.substr(5, color.length() - 6)
		var gradient_element := SVG.root_element.get_element_by_id(id)
		if gradient_element != null:
			gradient_texture.draw_rect(ci, inside_rect, false)
	else:
		var parsed_color := ColorParser.text_to_color(color)
		if parsed_color.a != 1 or color == "none":
			checkerboard.draw_rect(ci, inside_rect, false)
		if color != "none":
			RenderingServer.canvas_item_add_rect(ci,inside_rect, parsed_color)

func _make_custom_tooltip(_for_text: String) -> Object:
	var rtl := RichTextLabel.new()
	rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	rtl.fit_content = true
	rtl.bbcode_enabled = true
	rtl.add_theme_font_override("mono_font", ThemeUtils.mono_font)
	# Set up the text.
	var color_name := color_palette.color_names[idx]
	if not color_name.is_empty():
		rtl.add_text(color_name)
		rtl.newline()
	rtl.push_mono()
	rtl.add_text(color_palette.colors[idx])
	return rtl
