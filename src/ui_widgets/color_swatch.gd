extends Button

const bounds = Vector2(2, 2)

const checkerboard = preload("res://assets/icons/Checkerboard.svg")

var color: String
var color_name: String

var ci := get_canvas_item()
var gradient_texture: SVGTexture

var current_color := Color.BLACK

func _ready() -> void:
	tooltip_text = "lmofa"  # TODO: Remove this when #101550 is fixed.
	# TODO remove this when #25296 is fixed.
	if ColorParser.is_valid_url(color):
		var id := color.substr(5, color.length() - 6)
		var gradient_element := State.root_element.get_element_by_id(id)
		if is_instance_valid(gradient_element) and gradient_element is ElementBaseGradient:
			gradient_texture = gradient_element.generate_texture()

func _draw() -> void:
	var inside_rect := Rect2(bounds, size - bounds * 2)
	if ColorParser.is_valid_url(color):
		checkerboard.draw_rect(ci, inside_rect, false)
		var id := color.substr(5, color.length() - 6)
		var gradient_element := State.root_element.get_element_by_id(id)
		if gradient_element != null:
			gradient_texture.draw_rect(ci, inside_rect, false)
	else:
		var parsed_color := ColorParser.text_to_color(color)
		if color == "currentColor":
			parsed_color = current_color
		
		if parsed_color.a != 1 or color == "none":
			checkerboard.draw_rect(ci, inside_rect, false)
		if color != "none" and parsed_color.a != 0:
			RenderingServer.canvas_item_add_rect(ci, inside_rect, parsed_color)

func _make_custom_tooltip(_for_text: String) -> Object:
	var rtl := RichTextLabel.new()
	rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	rtl.fit_content = true
	rtl.bbcode_enabled = true
	rtl.add_theme_font_override("mono_font", ThemeUtils.mono_font)
	# Set up the text.
	if not color_name.is_empty():
		rtl.add_text(color_name)
		rtl.newline()
	rtl.push_mono()
	rtl.add_text(color)
	return rtl
