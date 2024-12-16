# Titled panels have two children: The first is on top and it's the title,
# the second one is on the bottom and it's the panel.
# The children after won't be resized.
class_name TitledPanel extends Container

@export var border_width: int
@export var corner_radius_top_left: int
@export var corner_radius_top_right: int
@export var corner_radius_bottom_left: int
@export var corner_radius_bottom_right: int
@export var color: Color  # Background color; the title panel is in front of it.
@export var border_color: Color
@export var title_color := Color.TRANSPARENT
@export var title_margin: int
@export var panel_margin: int

func _get_minimum_size_common_logic(vertical: bool) -> Vector2:
	if get_child_count() < 2:
		return Vector2.ZERO
	
	var title_minimum_size: Vector2 = get_child(0).get_combined_minimum_size()
	var panel_minimum_size: Vector2 = get_child(1).get_combined_minimum_size()
	var stack_axis := 1 if vertical else 0
	var other_axis := 0 if vertical else 1
	# The border width counts as part of both the title and the panel.
	var output: Vector2
	output[stack_axis] = title_minimum_size[stack_axis] + panel_minimum_size[stack_axis] +\
			title_margin * 2 + panel_margin * 2 - border_width
	output[other_axis] = maxf(title_minimum_size[other_axis] + title_margin * 2,
			panel_minimum_size[other_axis] + panel_margin * 2)
	return output


func _notification_common_logic(what: int, vertical: bool) -> void:
	if get_child_count() < 2:
		return
	
	var stack_axis := 1 if vertical else 0
	var other_axis := 0 if vertical else 1
	
	if what == NOTIFICATION_SORT_CHILDREN:
		var title: Control = get_child(0)
		var panel: Control = get_child(1)
		
		var title_size: Vector2
		title_size[stack_axis] = title.size[stack_axis]
		title_size[other_axis] = size[other_axis] - title_margin * 2
		fit_child_in_rect(title, Rect2(Vector2(title_margin, title_margin), title_size))
		
		var panel_position: Vector2
		panel_position[stack_axis] = title.size[stack_axis] + title_margin * 2 +\
				panel_margin - border_width
		panel_position[other_axis] = panel_margin
		var panel_size: Vector2
		panel_size[stack_axis] = size[stack_axis] - title_margin * 2 - panel_margin * 2 -\
				title.size[stack_axis] + border_width
		panel_size[other_axis] = size[other_axis] - panel_margin * 2
		fit_child_in_rect(panel, Rect2(panel_position, panel_size))
	elif what == NOTIFICATION_DRAW:
		var separator_pos: float = get_child(0).size[stack_axis] +\
				title_margin * 2 - floor(border_width / 2.0)
		if title_color.a > 0:
			var title_stylebox := StyleBoxFlat.new()
			title_stylebox.bg_color = title_color
			if vertical:
				title_stylebox.corner_radius_top_left = corner_radius_top_left
				title_stylebox.corner_radius_top_right = corner_radius_top_right
			else:
				title_stylebox.corner_radius_top_left = corner_radius_top_left
				title_stylebox.corner_radius_bottom_left = corner_radius_bottom_left
			var title_size: Vector2
			title_size[stack_axis] = separator_pos
			title_size[other_axis] = size[other_axis]
			draw_style_box(title_stylebox, Rect2(Vector2.ZERO, title_size))
			
			var panel_stylebox := StyleBoxFlat.new()
			panel_stylebox.bg_color = color
			if vertical:
				panel_stylebox.corner_radius_bottom_left = corner_radius_bottom_left
				panel_stylebox.corner_radius_bottom_right = corner_radius_bottom_right
			else:
				panel_stylebox.corner_radius_top_right = corner_radius_top_right
				panel_stylebox.corner_radius_bottom_right = corner_radius_bottom_right
			var panel_position: Vector2
			panel_position[stack_axis] = separator_pos
			panel_position[other_axis] = 0
			var panel_size: Vector2
			panel_size[stack_axis] = size[stack_axis] - separator_pos
			panel_size[other_axis] = size[other_axis]
			draw_style_box(panel_stylebox, Rect2(panel_position, panel_size))
			
			var border_stylebox := StyleBoxFlat.new()
			border_stylebox.border_color = border_color
			border_stylebox.draw_center = false
			border_stylebox.set_border_width_all(border_width)
			border_stylebox.corner_radius_bottom_left = corner_radius_bottom_left
			border_stylebox.corner_radius_bottom_right = corner_radius_bottom_right
			border_stylebox.corner_radius_top_left = corner_radius_top_left
			border_stylebox.corner_radius_top_right = corner_radius_top_right
			draw_style_box(border_stylebox, Rect2(Vector2.ZERO, size))
		else:
			var stylebox := StyleBoxFlat.new()
			stylebox.border_color = border_color
			stylebox.bg_color = color
			stylebox.set_border_width_all(border_width)
			stylebox.corner_radius_bottom_left = corner_radius_bottom_left
			stylebox.corner_radius_bottom_right = corner_radius_bottom_right
			stylebox.corner_radius_top_left = corner_radius_top_left
			stylebox.corner_radius_top_right = corner_radius_top_right
			draw_style_box(stylebox, Rect2(Vector2.ZERO, size))
		var line_start: Vector2
		line_start[stack_axis] = separator_pos
		line_start[other_axis] = 0
		var line_end: Vector2
		line_end[stack_axis] = separator_pos
		line_end[other_axis] = size[other_axis]
		draw_line(line_start, line_end, border_color, border_width)
