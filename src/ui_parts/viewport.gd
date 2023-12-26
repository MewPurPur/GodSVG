extends SubViewport

const ZoomMenuType = preload("res://src/ui_parts/zoom_menu.gd")

const buffer_view_space = 0.8
const zoom_reset_buffer = 0.875

var zoom := 1.0

@onready var display: TextureRect = %Checkerboard
@onready var view: Camera2D = $ViewCamera
@onready var controls: Control = %Checkerboard/Controls
@onready var display_texture: TextureRect = %Checkerboard/DisplayTexture
@onready var zoom_menu: ZoomMenuType = %ZoomMenu


func _ready() -> void:
	SVG.root_tag.resized.connect(resize)
	resize()
	await get_tree().process_frame
	zoom_menu.zoom_reset()

# Top left corner.
func set_view(new_position: Vector2) -> void:
	var scaled_size := size / zoom
	view.position = new_position.clamp(Vector2(view.limit_left, view.limit_top),
			Vector2(view.limit_right, view.limit_bottom) - scaled_size)
	
	var stripped_left := maxf(view.position.x, 0)
	var stripped_top := maxf(view.position.y, 0)
	var stripped_right := minf(view.position.x + scaled_size.x, SVG.root_tag.width)
	var stripped_bottom := minf(view.position.y + scaled_size.y, SVG.root_tag.height)
	display_texture.view_rect = Rect2(stripped_left, stripped_top,
			stripped_right - stripped_left, stripped_bottom - stripped_top)


# Adjust the SVG dimensions.
func resize() -> void:
	display.size = SVG.root_tag.get_size()
	zoom_menu.zoom_reset()

func center_frame() -> void:
	var available_size := size * zoom_reset_buffer
	var w_ratio := available_size.x / SVG.root_tag.width
	var h_ratio := available_size.y / SVG.root_tag.height
	zoom_menu.zoom_level = nearest_po2(ceili(minf(w_ratio, h_ratio) * 32)) / 64.0
	set_view((SVG.root_tag.get_size() - size / zoom) / 2)


func _unhandled_input(event: InputEvent) -> void:
	if Indications.get_viewport().gui_is_dragging():
		return
	if not event is InputEventMouseMotion or event.button_mask != 0:
		view.queue_redraw()
	
	if event is InputEventMouseMotion and\
	event.button_mask in [MOUSE_BUTTON_MASK_LEFT, MOUSE_BUTTON_MASK_MIDDLE]:
		set_view(view.position - (wrap_mouse(event.relative)\
				if GlobalSettings.wrap_mouse else event.relative) / zoom)
	
	if event is InputEventPanGesture:
		if event.ctrl_pressed:
			zoom_menu.zoom_level *= 1 + event.delta.y / 2
		else:
			set_view(view.position + event.delta * 32 / zoom)
	
	if event is InputEventMagnifyGesture:
		zoom_menu.zoom_level *= event.factor
	
	if event is InputEventMouseButton and event.is_pressed():
		var move_vec := Vector2.ZERO
		var zoom_dir := 0
		if (not event.ctrl_pressed and not event.shift_pressed and\
		not GlobalSettings.use_ctrl_for_zoom) or\
		(event.ctrl_pressed and GlobalSettings.use_ctrl_for_zoom):
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP when GlobalSettings.invert_zoom: zoom_dir -= 1
				MOUSE_BUTTON_WHEEL_DOWN when GlobalSettings.invert_zoom: zoom_dir += 1
				MOUSE_BUTTON_WHEEL_UP: zoom_dir += 1
				MOUSE_BUTTON_WHEEL_DOWN: zoom_dir -= 1
		elif event.shift_pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP: move_vec = Vector2.LEFT
				MOUSE_BUTTON_WHEEL_DOWN: move_vec = Vector2.RIGHT
				MOUSE_BUTTON_WHEEL_LEFT: move_vec = Vector2.UP
				MOUSE_BUTTON_WHEEL_RIGHT: move_vec = Vector2.DOWN
		else:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP: move_vec = Vector2.UP
				MOUSE_BUTTON_WHEEL_DOWN: move_vec = Vector2.DOWN
				MOUSE_BUTTON_WHEEL_LEFT: move_vec = Vector2.LEFT
				MOUSE_BUTTON_WHEEL_RIGHT: move_vec = Vector2.RIGHT
		var fac: float = event.factor
		if fac == roundf(fac):  # Detects unsupported device.
			fac = 1.0
		set_view(view.position + move_vec * fac / zoom * 32)
		if zoom_dir == 1:
			zoom_menu.zoom_in(fac)
		elif zoom_dir == -1:
			zoom_menu.zoom_out(fac)

func _on_zoom_changed(zoom_level: float) -> void:
	zoom = zoom_level
	adjust_view()
	
	display.material.set_shader_parameter(&"uv_scale",
			nearest_po2(int(zoom * 32)) / 32.0)
	controls.zoom = zoom
	display_texture.zoom = zoom
	view.queue_redraw()

var last_size_adjusted := size / zoom
func adjust_view() -> void:
	var old_size := last_size_adjusted
	last_size_adjusted = size / zoom
	
	var svg_size := SVG.root_tag.get_size()
	var zoomed_size := buffer_view_space * size / zoom
	view.zoom = Vector2(zoom, zoom)
	view.limit_left = int(-zoomed_size.x)
	view.limit_right = int(zoomed_size.x + svg_size.x)
	view.limit_top = int(-zoomed_size.y)
	view.limit_bottom = int(zoomed_size.y + svg_size.y)
	set_view(view.position + (old_size - size / zoom) / 2.0)

func _on_size_changed() -> void:
	if is_node_ready():
		adjust_view()

func wrap_mouse(relative: Vector2) -> Vector2:
	var view_rect := get_visible_rect().grow(-1.0)
	var mouse_pos := get_mouse_position()
	var warp_margin := view_rect.size * 0.5
	var relative_sign := relative.sign()
	
	var relative_warped := Vector2(
			fmod(relative.x + relative_sign.x * warp_margin.x, view_rect.size.x),
			fmod(relative.y + relative_sign.y * warp_margin.y, view_rect.size.y)) -\
			relative_sign * warp_margin
	
	if not view_rect.has_point(mouse_pos):
		mouse_pos.x = fposmod(mouse_pos.x, view_rect.size.x)
		mouse_pos.y = fposmod(mouse_pos.y, view_rect.size.y)
		warp_mouse(mouse_pos)
	
	return relative_warped
