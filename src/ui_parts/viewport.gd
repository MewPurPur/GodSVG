extends SubViewport

const ZoomMenuType = preload("res://src/ui_parts/zoom_menu.gd")

const buffer_view_space = 0.8
const zoom_reset_buffer = 0.875

var zoom := 1.0
var moving: bool
var last_pos: Vector2
var wrapped: bool

@onready var display: TextureRect = %Checkerboard
@onready var view: Camera2D = $ViewCamera
@onready var controls: Control = %Checkerboard/Controls
@onready var display_texture: Control = %Checkerboard/DisplayTexture
@onready var zoom_menu: ZoomMenuType = %ZoomMenu


func _ready() -> void:
	SVG.root_tag.resized.connect(resize)
	resize()
	await get_tree().process_frame
	zoom_menu.zoom_reset()

# Top left corner.
func set_view(new_position: Vector2) -> void:
	view.position = new_position.clamp(Vector2(view.limit_left, view.limit_top),
			Vector2(view.limit_right, view.limit_bottom) - size / zoom)


# Adjust the SVG dimensions.
func resize() -> void:
	display.size = SVG.root_tag.get_size()
	zoom_menu.zoom_reset()

func center_frame() -> void:
	var available_size := size * zoom_reset_buffer
	var w_ratio: float = available_size.x / SVG.root_tag.get_width()
	var h_ratio: float = available_size.y / SVG.root_tag.get_height()
	zoom_menu.zoom_level = nearest_po2(ceili(minf(w_ratio, h_ratio) * 32)) / 64.0
	set_view((SVG.root_tag.get_size() - size / zoom) / 2)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion or event.button_mask != 0:
		view.queue_redraw()
	
	if event is InputEventMouseMotion and\
	event.button_mask in [MOUSE_BUTTON_MASK_LEFT, MOUSE_BUTTON_MASK_MIDDLE]:
		set_view(view.position - wrap_mouse(moving) / zoom)
		moving = true
	else: 
		moving = false
	
	if event is InputEventPanGesture:
		if event.ctrl_pressed:
			zoom_menu.zoom_level *= 1 + event.delta.y / 2
		else:
			set_view(view.position + event.delta * 32 / zoom)
	
	if event is InputEventMagnifyGesture:
		zoom_menu.zoom_level *= event.factor
	
	if event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP when GlobalSettings.invert_zoom:
				zoom_menu.zoom_out()
			MOUSE_BUTTON_WHEEL_UP:
				zoom_menu.zoom_in()
			MOUSE_BUTTON_WHEEL_DOWN when GlobalSettings.invert_zoom:
				zoom_menu.zoom_in()
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom_menu.zoom_out()
	
	if event is InputEventMouseButton:
		if event.ctrl_pressed:
			pass



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

func wrap_mouse(already_moved: bool) -> Vector2:
	if not already_moved:
		last_pos = get_mouse_position()
	var view_rect:Rect2 = get_visible_rect()
	var mouse_pos: Vector2 = get_mouse_position()
	if not view_rect.has_point(mouse_pos):
		mouse_pos.x = fposmod(mouse_pos.x, view_rect.size.x)
		mouse_pos.y = fposmod(mouse_pos.y, view_rect.size.y)
		wrapped = true
	var win_pos: Vector2 = get_window().get_position()
	warp_mouse(mouse_pos)
	
	var relative: Vector2 = mouse_pos - last_pos
	last_pos = get_mouse_position()
	
	if not wrapped:
		return relative
	else:
		wrapped = false
		return mouse_pos - last_pos
