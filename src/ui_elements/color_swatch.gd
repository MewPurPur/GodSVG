extends Button

const code_font = preload("res://visual/fonts/FontMono.ttf")
const checkerboard = preload("res://visual/icons/backgrounds/Checkerboard.svg")
const plus_icon = preload("res://visual/icons/Plus.svg")
const gear_icon = preload("res://visual/icons/GearOutlined.svg")

static var ColorSwatch: PackedScene:
	get:
		if ColorSwatch == null:
			ColorSwatch = load("res://src/ui_elements/color_swatch.tscn")
		return ColorSwatch

enum Type {CHOOSE_COLOR, CONFIGURE_COLOR, ADD_COLOR}
var type := Type.CHOOSE_COLOR

var color_palette: ColorPalette
var idx := -1  # Index inside the palette.

var surface := RenderingServer.canvas_item_create()  # Used for the drop indicator.

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	RenderingServer.canvas_item_set_z_index(surface, 1)
	if type == Type.ADD_COLOR:
		tooltip_text = tr("Add color")
	else:
		tooltip_text = "_make_custom_tooltip() requires non-empty tooltip_text."

func _draw() -> void:
	if type == Type.ADD_COLOR:
		plus_icon.draw(get_canvas_item(), (size - plus_icon.get_size()) / 2)
		return
	
	var color := color_palette.colors[idx]
	var parsed_color := Color.from_string(color, Color(0, 0, 0))
	var bounds := Vector2(2, 2)
	if parsed_color.a != 1 or color == "none":
		draw_texture_rect(checkerboard, Rect2(bounds, size - bounds * 2), false)
	if color != "none":
		draw_rect(Rect2(bounds, size - bounds * 2), color)
	if type == Type.CONFIGURE_COLOR and is_hovered() and not is_dragging:
		gear_icon.draw(get_canvas_item(), (size - gear_icon.get_size()) / 2)


func _make_custom_tooltip(_for_text: String) -> Object:
	if type == Type.ADD_COLOR:
		return null
	elif type == Type.CHOOSE_COLOR or type == Type.CONFIGURE_COLOR:
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
	return null

func _get_drag_data(_at_position: Vector2) -> Variant:
	if type == Type.CONFIGURE_COLOR:
		var data: Array = [color_palette, idx]
		# Set up a preview.
		var preview := ColorSwatch.instantiate()
		preview.color_palette = color_palette
		preview.idx = idx
		preview.modulate = Color(1, 1, 1, 0.85)
		set_drag_preview(preview)
		modulate = Color(1, 1, 1, 0.55)
		return data
	return null

var is_dragging := false:
	set(new_value):
		if is_dragging != new_value:
			is_dragging = new_value
			queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		is_dragging = true
	if what == NOTIFICATION_DRAG_END:
		is_dragging = false
		modulate = Color(1, 1, 1)


# For configuration swatches.
func change_color_name(new_name: String) -> void:
	color_palette.modify_color_name(idx, new_name)

func change_color(new_color: String) -> void:
	color_palette.modify_color(idx, new_color)
	queue_redraw()
