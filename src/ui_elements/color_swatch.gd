extends Button

const code_font = preload("res://visual/fonts/FontMono.ttf")
const checkerboard = preload("res://visual/icons/backgrounds/Checkerboard.svg")
const plus_icon = preload("res://visual/icons/Plus.svg")
const gear_icon = preload("res://visual/icons/GearOutlined.svg")

const ColorSwatch = preload("res://src/ui_elements/color_swatch.tscn")

enum Type {CHOOSE_COLOR, CONFIGURE_COLOR, ADD_COLOR}
var type := Type.CHOOSE_COLOR

var named_color: NamedColor

func _ready() -> void:
	if type == Type.ADD_COLOR:
		tooltip_text = tr(&"Add color")

func _draw() -> void:
	if type == Type.ADD_COLOR:
		plus_icon.draw(get_canvas_item(), (size - plus_icon.get_size()) / 2)
		return
	
	var color := Color.from_string(named_color.color, Color(0, 0, 0))
	var bounds := Vector2(2, 2)
	if color.a != 1 or named_color.color == "none":
		draw_texture_rect(checkerboard, Rect2(bounds, size - bounds * 2), false)
	if named_color.color != "none":
		draw_rect(Rect2(bounds, size - bounds * 2), color)
	if type == Type.CONFIGURE_COLOR and is_hovered():
		gear_icon.draw(get_canvas_item(), (size - gear_icon.get_size()) / 2)

func _make_custom_tooltip(_for_text: String) -> Object:
	if type == Type.ADD_COLOR:
		return null
	elif type == Type.CHOOSE_COLOR or type == Type.CONFIGURE_COLOR:
		var rtl := RichTextLabel.new()
		rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
		rtl.fit_content = true
		rtl.bbcode_enabled = true
		rtl.add_theme_font_override(&"mono_font", code_font)
		# Set up the text.
		if not named_color.name.is_empty():
			rtl.add_text(named_color.name)
			rtl.newline()
		rtl.push_mono()
		if named_color.color == "none":
			rtl.add_text("none")
		else:
			rtl.add_text("#" + named_color.color)
		return rtl
	return null

func _get_drag_data(_at_position: Vector2) -> Variant:
	if type == Type.CONFIGURE_COLOR:
		var data: NamedColor = named_color
		# Set up a preview.
		var preview := ColorSwatch.instantiate()
		preview.named_color = named_color
		set_drag_preview(preview)
		return data
	return null


# For configuration swatches.
func change_color_name(new_name: String) -> void:
	named_color.name = new_name
	GlobalSettings.save_user_data()

func change_color(new_color: String) -> void:
	named_color.color = new_color
	GlobalSettings.save_user_data()
	queue_redraw()
