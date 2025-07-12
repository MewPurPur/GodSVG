@icon("res://godot_only/icons/PanelGrid.svg")
class_name PanelGrid extends Control

# Can be made into vars if necessary.
const border_width = 1
const side_spacing = 6
const top_spacing = 2
const bottom_spacing = 2

@export var columns: int
@export var items: PackedStringArray
@export var dim_last_item := false


func _draw() -> void:
	var item_count := items.size()
	if item_count == 0:
		return
	
	var inner_color := ThemeUtils.desaturated_color.lerp(ThemeUtils.extreme_theme_color, 0.75)
	var border_color := ThemeUtils.desaturated_color.lerp(ThemeUtils.extreme_theme_color, 0.55)
	
	var effective_columns := clampi(columns, 1, item_count)
	var text_color := get_theme_color("font_color", "Label")
	var text_font := get_theme_font("font", "Label")
	var text_font_size := get_theme_font_size("font_size", "Label")
	var text_height := text_font.get_height(text_font_size)
	var box_height := text_height + top_spacing + bottom_spacing
	var box_width := size.x / effective_columns
	var ci := get_canvas_item()
	
	custom_minimum_size.y = box_height * ceili(item_count / float(effective_columns))
	
	@warning_ignore("integer_division")
	RenderingServer.canvas_item_add_rect(ci, Rect2(0, 0, size.x,
			box_height * (item_count / effective_columns)), inner_color)
	
	for item_idx in item_count:
		var pos_x := (size.x / effective_columns) * (item_idx % effective_columns)
		@warning_ignore("integer_division")
		var pos_y := box_height * (item_idx / effective_columns)
		
		if item_idx == item_count - 1:
			if item_count % effective_columns != 0:
				RenderingServer.canvas_item_add_rect(ci,
						Rect2(pos_x, pos_y, box_width, box_height), inner_color)
			if dim_last_item:
				text_color = ThemeUtils.dim_text_color
		
		# Sigh...
		if is_zero_approx(pos_x):
			draw_rect(Rect2(1, pos_y, box_width - 1, box_height), border_color, false, 1.0)
		else:
			draw_rect(Rect2(pos_x, pos_y, box_width, box_height), border_color, false, 1.0)
		
		
		text_font.draw_string(ci, Vector2(pos_x + side_spacing, pos_y + top_spacing +\
				text_font_size), items[item_idx], HORIZONTAL_ALIGNMENT_LEFT, -1,
				text_font_size, text_color)
