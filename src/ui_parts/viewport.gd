extends SubViewport

const ZoomMenu = preload("res://src/ui_widgets/zoom_menu.gd")
const HandlesManager = preload("res://src/ui_parts/handles_manager.gd")
const DisplayTexture = preload("res://src/ui_parts/display_texture.gd")

const BUFFER_VIEW_SPACE = 0.8
const ZOOM_RESET_BUFFER = 0.875

# Holds zoom position for Ctrl + MMB zooming.
var _zoom_to: Vector2

var limit_left := 0.0
var limit_right := 0.0
var limit_top := 0.0
var limit_bottom := 0.0

@onready var checkerboard: TextureRect = $Checkerboard
@onready var view: SubViewportContainer = get_parent()
@onready var controls: HandlesManager = $Controls
@onready var display_texture: DisplayTexture = $Checkerboard/DisplayTexture
@onready var zoom_menu: ZoomMenu = %ZoomMenu


func _ready() -> void:
	zoom_menu.zoom_changed.connect(_on_zoom_changed)
	zoom_menu.zoom_reset_pressed.connect(center_frame)
	zoom_menu.zoom_changed.connect(view.update.unbind(2))
	size_changed.connect(_on_size_changed)
	State.svg_resized.connect(resize)
	resize()
	Configs.active_tab_changed.connect(zoom_menu.zoom_reset)
	State.viewport_size_changed.connect(adjust_view)
	await get_tree().process_frame
	zoom_menu.zoom_reset()

# Top left corner.
func set_view(new_position: Vector2) -> void:
	var scaled_size := size / State.zoom
	view.camera_position = new_position.clamp(Vector2(limit_left, limit_top), Vector2(limit_right, limit_bottom) - scaled_size)
	
	var stripped_left := maxf(view.camera_position.x, 0.0)
	var stripped_top := maxf(view.camera_position.y, 0.0)
	var stripped_right := minf(view.camera_position.x + scaled_size.x, State.root_element.width)
	var stripped_bottom := minf(view.camera_position.y + scaled_size.y, State.root_element.height)
	display_texture.view_rect = Rect2(stripped_left, stripped_top, stripped_right - stripped_left, stripped_bottom - stripped_top)
	view.update()


# Adjust the SVG dimensions.
func resize() -> void:
	var root_element_size := State.root_element.get_size()
	if root_element_size.is_finite():
		checkerboard.size = root_element_size
	zoom_menu.zoom_reset()

func center_frame() -> void:
	var available_size := size * ZOOM_RESET_BUFFER
	var w_ratio := available_size.x / State.root_element.width
	var h_ratio := available_size.y / State.root_element.height
	if is_finite(w_ratio) and is_finite(h_ratio):
		zoom_menu.set_zoom(nearest_po2(ceili(minf(w_ratio, h_ratio) * 32)) / 64.0)
	else:
		zoom_menu.set_zoom(1.0)
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
			zoom_menu.set_zoom(State.zoom * (1.0 + (1 if Configs.savedata.invert_zoom else -1) *\
					(wrap_mouse(event.relative).y if Configs.savedata.wraparound_panning else event.relative.y) / 128.0), _zoom_to)
		# Panning with LMB or MMB. This gives a reliable way to adjust the view without dragging the things on it.
		else:
			set_view(view.camera_position - (wrap_mouse(event.relative) if Configs.savedata.wraparound_panning else event.relative) / State.zoom)
	
	elif event is InputEventPanGesture and not DisplayServer.get_name() == "Android":
		# Zooming with Ctrl + touch?
		if event.ctrl_pressed:
			zoom_menu.set_zoom(State.zoom * (1 + event.delta.y / 2))
		# Panning with touch.
		else:
			set_view(view.camera_position + event.delta * 32 / State.zoom)
	# Zooming with touch.
	elif event is InputEventMagnifyGesture:
		zoom_menu.set_zoom(State.zoom * event.factor)
	# Actions with scrolling.
	elif event is InputEventMouseButton and event.is_pressed():
		var move_vec := Vector2.ZERO
		var zoom_dir := 0
		
		# Zooming with scrolling.
		if (not event.ctrl_pressed and not event.shift_pressed and not Configs.savedata.use_ctrl_for_zoom) or\
		(event.ctrl_pressed and Configs.savedata.use_ctrl_for_zoom):
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP when Configs.savedata.invert_zoom: zoom_dir = -1
				MOUSE_BUTTON_WHEEL_DOWN when Configs.savedata.invert_zoom: zoom_dir = 1
				MOUSE_BUTTON_WHEEL_UP: zoom_dir = 1
				MOUSE_BUTTON_WHEEL_DOWN: zoom_dir = -1
				_: return
		# Inverted panning with Shift + scrolling.
		elif event.shift_pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP: move_vec = Vector2.LEFT
				MOUSE_BUTTON_WHEEL_DOWN: move_vec = Vector2.RIGHT
				MOUSE_BUTTON_WHEEL_LEFT: move_vec = Vector2.UP
				MOUSE_BUTTON_WHEEL_RIGHT: move_vec = Vector2.DOWN
				_: return
		# Panning with scrolling.
		else:
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
		if zoom_dir == 1:
			zoom_menu.zoom_in(factor, mouse_offset)
		elif zoom_dir == -1:
			zoom_menu.zoom_out(factor, mouse_offset)
		
		set_view(view.camera_position + move_vec * factor / State.zoom * 32)
	
	else:
		if not event.is_echo():
			# Filter out fake mouse movement events.
			if not (event is InputEventMouseMotion and event.relative == Vector2.ZERO):
				_zoom_to = Vector2.ZERO  # Reset Ctrl + MMB zoom position if released.


func _on_zoom_changed(new_zoom_level: float, offset: Vector2) -> void:
	State.set_zoom(new_zoom_level)
	adjust_view(offset)
	checkerboard.material.set_shader_parameter("uv_scale", nearest_po2(int(State.zoom * 32.0)) / 32.0)

var last_size_adjusted := size / State.zoom

func adjust_view(offset := Vector2(0.5, 0.5)) -> void:
	var old_size := last_size_adjusted
	last_size_adjusted = size / State.zoom
	
	var svg_w := State.root_element.width if State.root_element.has_attribute("width") else 16384.0
	var svg_h := State.root_element.height if State.root_element.has_attribute("height") else 16384.0
	
	var zoomed_size := BUFFER_VIEW_SPACE * size / State.zoom
	limit_left = -zoomed_size.x
	limit_right = zoomed_size.x + svg_w
	limit_top = -zoomed_size.y
	limit_bottom = zoomed_size.y + svg_h
	
	set_view(Vector2(lerpf(view.camera_position.x, view.camera_position.x + old_size.x - size.x / State.zoom, offset.x),
			lerpf(view.camera_position.y, view.camera_position.y + old_size.y - size.y / State.zoom, offset.y)))

func _on_size_changed() -> void:
	State.set_viewport_size(size)

func wrap_mouse(relative: Vector2) -> Vector2:
	var view_rect := get_visible_rect().grow(-1.0)
	var warp_margin := view_rect.size * 0.5
	var mouse_pos := get_mouse_position()
	
	if not view_rect.has_point(mouse_pos):
		warp_mouse(Vector2(fposmod(mouse_pos.x, view_rect.size.x), fposmod(mouse_pos.y, view_rect.size.y)))
	
	return Vector2(fmod(relative.x + signf(relative.x) * warp_margin.x, view_rect.size.x),
			fmod(relative.y + signf(relative.y) * warp_margin.y, view_rect.size.y)) - relative.sign() * warp_margin
