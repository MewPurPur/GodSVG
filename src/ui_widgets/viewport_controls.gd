extends SubViewport

var canvas: Canvas

# Holds zoom position for Ctrl + MMB zooming.
var _zoom_to: Vector2

func _unhandled_input(event: InputEvent) -> void:
	if HandlerGUI.get_viewport().gui_is_dragging():
		return
	
	if event is InputEventMouseMotion and event.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_MIDDLE):
		# Zooming with Ctrl + MMB.
		if event.ctrl_pressed and event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			if _zoom_to == Vector2.ZERO:  # Set zoom position if starting action.
				_zoom_to = get_mouse_position() / canvas.size
			var relative_y: float = canvas.wrap_mouse(event.relative).y if Configs.savedata.wraparound_panning else event.relative.y
			var new_zoom := canvas.camera_zoom * (1.0 + (1 if Configs.savedata.invert_zoom else -1) * relative_y / 128.0)
			canvas.set_zoom(new_zoom, _zoom_to)
		else:
			# Panning with LMB or MMB. This gives a reliable way to adjust the view without dragging the things on it.
			var relative: Vector2 = canvas.wrap_mouse(event.relative) if Configs.savedata.wraparound_panning else event.relative
			canvas.set_view(canvas.camera_center - relative / canvas.camera_zoom)
	
	elif event is InputEventPanGesture and DisplayServer.get_name() != "Android":
		if event.ctrl_pressed:
			# Zooming with Ctrl + touch?
			canvas.set_zoom(canvas.camera_zoom * (1.0 + event.delta.y / 2.0))
		else:
			# Panning with touch.
			canvas.set_view(canvas.camera_center + event.delta * 32.0 / canvas.camera_zoom)
	elif event is InputEventMagnifyGesture:
		# Zooming with touch.
		canvas.set_zoom(canvas.camera_zoom * event.factor)
	elif event is InputEventMouseButton and event.is_pressed():
		# Actions with scrolling.
		var move_vec := Vector2.ZERO
		var zoom_direction := 0
		
		if (not event.ctrl_pressed and not event.shift_pressed and not Configs.savedata.use_ctrl_for_zoom) or\
		(event.ctrl_pressed and Configs.savedata.use_ctrl_for_zoom):
			# Zooming with scrolling.
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP: zoom_direction = -1 if Configs.savedata.invert_zoom else 1
				MOUSE_BUTTON_WHEEL_DOWN: zoom_direction = 1 if Configs.savedata.invert_zoom else -1
				_: return
		elif event.shift_pressed:
			# Inverted panning with Shift + scrolling.
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP: move_vec = Vector2.LEFT
				MOUSE_BUTTON_WHEEL_DOWN: move_vec = Vector2.RIGHT
				MOUSE_BUTTON_WHEEL_LEFT: move_vec = Vector2.UP
				MOUSE_BUTTON_WHEEL_RIGHT: move_vec = Vector2.DOWN
				_: return
		else:
			# Panning with scrolling.
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP: move_vec = Vector2.UP
				MOUSE_BUTTON_WHEEL_DOWN: move_vec = Vector2.DOWN
				MOUSE_BUTTON_WHEEL_LEFT: move_vec = Vector2.LEFT
				MOUSE_BUTTON_WHEEL_RIGHT: move_vec = Vector2.RIGHT
				_: return
		
		var mouse_offset := get_mouse_position() / canvas.size
		# Apply scroll data from above.
		var factor: float = event.factor
		if factor == roundf(factor):  # Detects if precise factor is unsupported.
			factor = 1.0
		
		var multiplied_factor := sqrt(2) * factor
		if zoom_direction == 1:
			canvas.set_zoom(canvas.camera_zoom * multiplied_factor, mouse_offset)
		elif zoom_direction == -1:
			canvas.set_zoom(canvas.camera_zoom / multiplied_factor, mouse_offset)
		
		canvas.set_view(canvas.camera_center + move_vec * factor / canvas.camera_zoom * 32)
	
	else:
		if not event.is_echo():
			# Filter out fake mouse movement events.
			if not (event is InputEventMouseMotion and event.relative == Vector2.ZERO):
				_zoom_to = Vector2.ZERO  # Reset Ctrl + MMB zoom position if released.
