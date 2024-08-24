extends Button

const checkerboard = preload("res://visual/icons/backgrounds/Checkerboard.svg")
const gear_icon = preload("res://visual/icons/GearOutlined.svg")

const ColorSwatch = preload("res://src/ui_widgets/color_swatch.tscn")

var color_palette: ColorPalette
var idx := -1  # Index inside the palette.

var proposed_drop_data: Array = []  # Used to sync with drag-and-dropping information.
var surface := RenderingServer.canvas_item_create()

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	RenderingServer.canvas_item_set_z_index(surface, 1)
	# _make_custom_tooltip() requires some text to work.
	tooltip_text = "lmofa"  # _make_custom_tooltip() requires some text to work.

func _exit_tree() -> void:
	RenderingServer.free_rid(surface)

func _draw() -> void:
	if idx >= color_palette.colors.size():
		return
	
	var color := color_palette.colors[idx]
	var parsed_color := Color.from_string(color, Color(0, 0, 0))
	var bounds := Vector2(2, 2)
	if parsed_color.a != 1 or color == "none":
		draw_texture_rect(checkerboard, Rect2(bounds, size - bounds * 2), false)
	if color != "none":
		draw_rect(Rect2(bounds, size - bounds * 2), color)
	
	RenderingServer.canvas_item_clear(surface)
	if proposed_drop_data.size() != 2 or proposed_drop_data[0] != color_palette:
		# Gear indicator.
		if is_hovered():
			gear_icon.draw(get_canvas_item(), (size - gear_icon.get_size()) / 2)
		return
	
	var drop_idx: int = proposed_drop_data[1]
	# Draw the drag-and-drop indicator.
	var drop_sb := StyleBoxFlat.new()
	drop_sb.draw_center = false
	drop_sb.border_color = Color.GREEN
	drop_sb.set_corner_radius_all(3)
	if drop_idx == idx:
		drop_sb.border_width_left = 2
		drop_sb.draw(surface, Rect2(Vector2.ZERO, size))
	elif drop_idx == idx + 1:
		drop_sb.border_width_right = 2
		drop_sb.draw(surface, Rect2(Vector2.ZERO, size))


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

var is_dragging := false

func _get_drag_data(_at_position: Vector2) -> Variant:
	var data: Array = [color_palette, idx]
	# Set up a preview.
	var preview := ColorSwatch.instantiate()
	preview.color_palette = color_palette
	preview.idx = idx
	preview.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(preview)
	modulate = Color(1, 1, 1, 0.55)
	queue_redraw()
	return data

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		proposed_drop_data.clear()
		modulate = Color(1, 1, 1)
		queue_redraw()


# For configuration swatches.
func change_color_name(new_name: String) -> void:
	color_palette.modify_color_name(idx, new_name)

func change_color(new_color: String) -> void:
	color_palette.modify_color(idx, new_color)
	queue_redraw()
