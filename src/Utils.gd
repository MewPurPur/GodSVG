class_name Utils extends RefCounted

static func is_string_upper(string: String) -> bool:
	return string.to_upper() == string

static func is_string_lower(string: String) -> bool:
	return string.to_lower() == string

static func defocus_control_on_outside_click(control: Control, event: InputEvent) -> void:
	if (control.has_focus() and event is InputEventMouseButton and\
	not control.get_global_rect().has_point(event.position)):
		control.release_focus()
