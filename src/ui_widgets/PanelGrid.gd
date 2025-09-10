@icon("res://godot_only/icons/PanelGrid.svg")
class_name PanelGrid extends Control

const copy_icon = preload("res://assets/icons/Copy.svg")

# Can be made into vars if necessary.
const border_width = 1
const side_spacing = 6
const top_spacing = 2
const bottom_spacing = 2

@export var columns: int
@export var items: PackedStringArray
@export var dim_last_item := false

var boxes: Array[Rect2] = []
var copy_button: Button


func _ready() -> void:
	mouse_exited.connect(remove_copy_button)

func _draw() -> void:
	boxes.clear()
	var item_count := items.size()
	if item_count == 0:
		return
	
	var inner_color := ThemeUtils.basic_panel_inner_color.lerp(ThemeUtils.desaturated_color, 0.35)
	var border_color := ThemeUtils.basic_panel_inner_color.lerp(ThemeUtils.desaturated_color, 0.85)
	
	var effective_columns := clampi(columns, 1, item_count)
	var text_color := get_theme_color("font_color", "Label")
	var text_font := get_theme_font("font", "Label")
	var text_font_size := get_theme_font_size("font_size", "Label")
	var text_height := text_font.get_height(text_font_size)
	var box_height := text_height + top_spacing + bottom_spacing
	var box_width := size.x / effective_columns
	var ci := get_canvas_item()
	
	custom_minimum_size.y = box_height * ceili(item_count / float(effective_columns))
	
	# One big filled rect for everything but the last row.
	RenderingServer.canvas_item_add_rect(ci, Rect2(0, 0, size.x, box_height * (item_count / effective_columns)), inner_color)
	
	for idx in item_count:
		var pos_x := (size.x / effective_columns) * (idx % effective_columns)
		var pos_y := box_height * (idx / effective_columns)
		
		# Sigh...
		var box_rect := Rect2(pos_x, pos_y, box_width, box_height)
		if is_zero_approx(pos_x):
			box_rect = Rect2(1, pos_y, box_width - 1, box_height)
		boxes.append(box_rect)
		
		if idx == item_count - 1:
			if item_count % effective_columns != 0:
				RenderingServer.canvas_item_add_rect(ci, box_rect, inner_color)
			if dim_last_item:
				text_color = ThemeUtils.dimmer_text_color
		
		draw_rect(box_rect, border_color, false, 1.0)
		text_font.draw_string(ci, Vector2(pos_x + side_spacing, pos_y + top_spacing + text_font_size),
				items[idx], HORIZONTAL_ALIGNMENT_LEFT, -1, text_font_size, text_color)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion):
		return
	
	for idx in items.size():
		var item := items[idx]
		var item_after_angle_bracket := item.get_slice("<", 1)
		if not item_after_angle_bracket.is_empty():
			if ">" in item_after_angle_bracket:
				var email := item_after_angle_bracket.get_slice(">", 0)
				var box := boxes[idx]
				if box.has_point(event.position):
					if not is_instance_valid(copy_button):
						copy_button = Button.new()
						copy_button.theme_type_variation = "FlatButton"
						copy_button.icon = copy_icon
						copy_button.focus_mode = Control.FOCUS_NONE
						copy_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
						copy_button.mouse_filter = Control.MOUSE_FILTER_PASS
						copy_button.tooltip_text = Translator.translate("Copy email")
						copy_button.pressed.connect(DisplayServer.clipboard_set.bind(email))
						add_child(copy_button)
						copy_button.position = Vector2(box.end.x - copy_button.size.x - 1, box.position.y + 1)
					return
	remove_copy_button()

func remove_copy_button() -> void:
	if is_instance_valid(copy_button):
		copy_button.queue_free()
