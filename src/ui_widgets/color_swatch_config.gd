extends Button

const checkerboard = preload("res://assets/icons/backgrounds/Checkerboard.svg")
const gear_icon = preload("res://assets/icons/GearOutlined.svg")

const ColorSwatchScene = preload("res://src/ui_widgets/color_swatch.tscn")

var palette: Palette
var idx := -1  # Index inside the palette.

var proposed_drop_data: DragData  # Used to sync with drag-and-dropping information.
var surface := RenderingServer.canvas_item_create()

func _ready() -> void:
	tooltip_text = "lmofa"  # TODO: Remove this when #101550 is fixed.
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	RenderingServer.canvas_item_set_z_index(surface, 1)

func _exit_tree() -> void:
	RenderingServer.free_rid(surface)

func _draw() -> void:
	if idx >= palette.get_color_count():
		return
	
	var color := palette.get_color(idx)
	var parsed_color := ColorParser.text_to_color(color)
	var bounds := Vector2(2, 2)
	var inside_rect := Rect2(bounds, size - bounds * 2)
	if parsed_color.a != 1 or color == "none":
		draw_texture_rect(checkerboard, inside_rect, false)
	if color != "none" and parsed_color.a != 0:
		draw_rect(inside_rect, parsed_color)
	
	RenderingServer.canvas_item_clear(surface)
	if not is_instance_valid(proposed_drop_data) or proposed_drop_data.palette != palette:
		# Gear indicator.
		if is_hovered():
			gear_icon.draw(get_canvas_item(), (size - gear_icon.get_size()) / 2)
		return
	
	var drop_idx := proposed_drop_data.index
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
	var color_name := palette.get_color_name(idx)
	if not color_name.is_empty():
		rtl.add_text(color_name)
		rtl.newline()
	rtl.push_mono()
	rtl.add_text(palette.get_color(idx))
	return rtl

var is_dragging := false

class DragData:
	var palette: Palette
	var index: int
	
	func _init(new_palette: Palette, new_index: int) -> void:
		palette = new_palette
		index = new_index

func _get_drag_data(_at_position: Vector2) -> Variant:
	var data := DragData.new(palette, idx)
	# Set up a preview.
	var preview := ColorSwatchScene.instantiate()
	preview.color = palette.get_color(idx)
	preview.color_name = palette.get_color_name(idx)
	preview.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(preview)
	modulate = Color(1, 1, 1, 0.55)
	queue_redraw()
	return data

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		proposed_drop_data = null
		modulate = Color(1, 1, 1)
		queue_redraw()


# For configuration swatches.
func change_color_name(new_name: String) -> void:
	palette.modify_color_name(idx, new_name)

func change_color(new_color: String) -> void:
	palette.modify_color(idx, new_color)
	queue_redraw()
