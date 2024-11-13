extends Button

func _process(_delta: float) -> void:
	var condition := ColorPalette.is_valid_palette(DisplayServer.clipboard_get())
	disabled = not condition
	mouse_default_cursor_shape = CURSOR_POINTING_HAND if condition else CURSOR_ARROW
