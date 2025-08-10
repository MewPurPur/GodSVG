extends SubViewport

const BUFFER_VIEW_SPACE = 0.8
const ZOOM_RESET_BUFFER = 0.875

# Holds zoom position for Ctrl + MMB zooming.
var _zoom_to: Vector2

var limit_top_left := Vector2.ZERO
var limit_bottom_right := Vector2.ZERO

@onready var view: SubViewportContainer = get_parent()

func _ready() -> void:
	size_changed.connect(adjust_view)
	State.svg_resized.connect(center_frame)
	center_frame()
	Configs.active_tab_changed.connect(center_frame)
	await get_tree().process_frame
	center_frame()


func set_zoom(new_zoom: float, offset := Vector2(0.5, 0.5)) -> void:
	new_zoom = clampf(new_zoom, Canvas.MIN_ZOOM, Canvas.MAX_ZOOM)
	State.set_zoom(new_zoom)
	adjust_view(offset)
	view.update()

# Top left corner.
func set_view(new_position: Vector2) -> void:
	var scaled_size := size / State.zoom
	view.camera_position = new_position.clamp(limit_top_left, limit_bottom_right - scaled_size)
	
	var stripped_left := maxf(view.camera_position.x, 0.0)
	var stripped_top := maxf(view.camera_position.y, 0.0)
	var stripped_right := minf(view.camera_position.x + scaled_size.x, State.root_element.width)
	var stripped_bottom := minf(view.camera_position.y + scaled_size.y, State.root_element.height)
	view.view_rect = Rect2(stripped_left, stripped_top, stripped_right - stripped_left, stripped_bottom - stripped_top)
	view.update()


func center_frame() -> void:
	var available_size := size * ZOOM_RESET_BUFFER
	var w_ratio := available_size.x / State.root_element.width
	var h_ratio := available_size.y / State.root_element.height
	if is_finite(w_ratio) and is_finite(h_ratio):
		var new_zoom := nearest_po2(ceili(minf(w_ratio, h_ratio) * 32)) / 64.0
		State.set_zoom(new_zoom)
	else:
		State.set_zoom(1.0)
	
	adjust_view()
	set_view((State.root_element.get_size() - size / State.zoom) / 2)


func _unhandled_input(event: InputEvent) -> void:
	if State.get_viewport().gui_is_dragging():
		return
	
	if event is InputEventMouseMotion and event.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_MIDDLE):
		# Zooming with Ctrl + MMB.
		if event.ctrl_pressed and event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			if _zoom_to == Vector2.ZERO:  # Set zoom position if starting action.
				_zoom_to = get_mouse_position() / Vector2(size)
			var relative_y: float = wrap_mouse(event.relative).y if Configs.savedata.wraparound_panning else event.relative.y
			var new_zoom := State.zoom * (1.0 + (1 if Configs.savedata.invert_zoom else -1) * relative_y / 128.0)
			set_zoom(new_zoom, _zoom_to)
		else:
			# Panning with LMB or MMB. This gives a reliable way to adjust the view without dragging the things on it.
			var relative: Vector2 = wrap_mouse(event.relative) if Configs.savedata.wraparound_panning else event.relative
			set_view(view.camera_position - relative / State.zoom)
	
	elif event is InputEventPanGesture and DisplayServer.get_name() != "Android":
		if event.ctrl_pressed:
			# Zooming with Ctrl + touch?
			set_zoom(State.zoom * (1.0 + event.delta.y / 2.0))
		else:
			# Panning with touch.
			set_view(view.camera_position + event.delta * 32.0 / State.zoom)
	elif event is InputEventMagnifyGesture:
		# Zooming with touch.
		set_zoom(State.zoom * event.factor)
	elif event is InputEventMouseButton and event.is_pressed():
		# Actions with scrolling.
		var move_vec := Vector2.ZERO
		var zoom_dir := 0
		
		if (not event.ctrl_pressed and not event.shift_pressed and not Configs.savedata.use_ctrl_for_zoom) or\
		(event.ctrl_pressed and Configs.savedata.use_ctrl_for_zoom):
			# Zooming with scrolling.
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP: zoom_dir = -1 if Configs.savedata.invert_zoom else 1
				MOUSE_BUTTON_WHEEL_DOWN: zoom_dir = 1 if Configs.savedata.invert_zoom else -1
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
		
		var mouse_offset := get_mouse_position() / Vector2(size)
		# Apply scroll data from above.
		var factor: float = event.factor
		if factor == roundf(factor):  # Detects if precise factor is unsuported.
			factor = 1.0
		
		var multiplied_factor := sqrt(2) * factor
		if zoom_dir == 1:
			set_zoom(State.zoom * multiplied_factor, mouse_offset)
		elif zoom_dir == -1:
			set_zoom(State.zoom / multiplied_factor, mouse_offset)
		
		set_view(view.camera_position + move_vec * factor / State.zoom * 32)
	
	else:
		if not event.is_echo():
			# Filter out fake mouse movement events.
			if not (event is InputEventMouseMotion and event.relative == Vector2.ZERO):
				_zoom_to = Vector2.ZERO  # Reset Ctrl + MMB zoom position if released.


var last_size_adjusted := size / State.zoom

func adjust_view(offset := Vector2(0.5, 0.5)) -> void:
	var old_size := last_size_adjusted
	last_size_adjusted = size / State.zoom
	
	var zoomed_size := BUFFER_VIEW_SPACE * size / State.zoom
	limit_top_left = -zoomed_size
	limit_bottom_right = zoomed_size + Vector2(State.root_element.width if State.root_element.has_attribute("width") else 16384.0,
			State.root_element.height if State.root_element.has_attribute("height") else 16384.0)
	
	set_view(Vector2(lerpf(view.camera_position.x, view.camera_position.x + old_size.x - size.x / State.zoom, offset.x),
			lerpf(view.camera_position.y, view.camera_position.y + old_size.y - size.y / State.zoom, offset.y)))

func wrap_mouse(relative: Vector2) -> Vector2:
	var view_rect := get_visible_rect().grow(-1.0)
	var warp_margin := view_rect.size * 0.5
	var mouse_pos := get_mouse_position()
	
	if not view_rect.has_point(mouse_pos):
		warp_mouse(Vector2(fposmod(mouse_pos.x, view_rect.size.x), fposmod(mouse_pos.y, view_rect.size.y)))
	
	return Vector2(fmod(relative.x + signf(relative.x) * warp_margin.x, view_rect.size.x),
			fmod(relative.y + signf(relative.y) * warp_margin.y, view_rect.size.y)) - relative.sign() * warp_margin
