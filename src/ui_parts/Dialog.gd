class_name Dialog extends ColorRect

func _enter_tree() -> void:
	color = Color(0, 0, 0, 0.4)
	anchors_preset = PRESET_FULL_RECT
	process_mode = PROCESS_MODE_ALWAYS
	get_tree().paused = true

func _exit_tree() -> void:
	get_tree().paused = false
