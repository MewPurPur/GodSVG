class_name Utils extends RefCounted

static func is_string_upper(string: String) -> bool:
	return string.to_upper() == string

static func is_string_lower(string: String) -> bool:
	return string.to_lower() == string

static func defocus_control_on_outside_click(control: Control, event: InputEvent) -> void:
	if (control.has_focus() and event is InputEventMouseButton and\
	not control.get_global_rect().has_point(event.position)):
		control.release_focus()

static func calculate_popup_rect(button_global_pos: Vector2,
button_size: Vector2, popup_size: Vector2, align_center := false) -> Rect2:
	var screen_h: int =\
			ProjectSettings.get_setting("display/window/size/viewport_height", 640)
	var popup_pos := Vector2.ZERO
	# Popup below if there's enough space or we're in the bottom half of the screen.
	if button_global_pos.y + button_size.y + popup_size.y < screen_h or\
	button_global_pos.y + button_size.y / 2 <= screen_h / 2.0:
		popup_pos.y = button_global_pos.y + button_size.y
	else:
		popup_pos.y = button_global_pos.y - popup_size.y
	# Align horizontally.
	if align_center:
		popup_pos.x = button_global_pos.x - popup_size.x / 2 + button_size.x / 2
	else:
		popup_pos.x = button_global_pos.x
	return Rect2(popup_pos, popup_size)

static func vec_min(vec1: Vector2, vec2: Vector2) -> Vector2:
	return Vector2(minf(vec1.x, vec2.x), minf(vec1.y, vec2.y))

static func vec_max(vec1: Vector2, vec2: Vector2) -> Vector2:
	return Vector2(maxf(vec1.x, vec2.x), maxf(vec1.y, vec2.y))
