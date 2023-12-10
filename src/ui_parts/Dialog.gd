## Translucent black rectangle to be used for modals.
class_name Dialog extends ColorRect

static var is_open: bool

func _enter_tree() -> void:
	is_open = true
	color = Color(0, 0, 0, 0.4)
	anchors_preset = PRESET_FULL_RECT
	process_mode = PROCESS_MODE_ALWAYS
	get_tree().paused = true

func _exit_tree() -> void:
	is_open = false
	get_tree().paused = false
