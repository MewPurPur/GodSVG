class_name OverlayRect extends ColorRect

func _enter_tree() -> void:
	color = Color(0, 0, 0, 0.4)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		HandlerGUI.remove_overlay()
		accept_event()
