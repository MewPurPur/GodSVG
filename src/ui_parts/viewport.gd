extends SubViewport

const ZoomMenuType = preload("res://src/ui_parts/zoom_menu.gd")

const buffer_view_space = 0.8

var zoom := 1.0

@onready var display: TextureRect = %Checkerboard
@onready var view: Camera2D = $ViewCamera
@onready var controls: Control = %Checkerboard/Controls
@onready var display_texture: Control = %Checkerboard/DisplayTexture
@onready var zoom_menu: ZoomMenuType = %ZoomMenu


func _ready() -> void:
	SVG.root_tag.attribute_changed.connect(resize)
	SVG.root_tag.changed_unknown.connect(resize)
	resize()
	zoom_menu.zoom_reset()

# Top left corner.
func set_view(new_position: Vector2) -> void:
	view.position = new_position.clamp(Vector2(view.limit_left, view.limit_top),
			Vector2(view.limit_right, view.limit_bottom) - size / zoom)


func get_svg_size() -> Vector2:
	return Vector2(SVG.root_tag.attributes.width.get_value(),
			SVG.root_tag.attributes.height.get_value())

# Adjust the SVG dimensions.
func resize() -> void:
	display.size = get_svg_size()
	zoom_menu.zoom_reset()

func center_frame() -> void:
	set_view((get_svg_size() - size / zoom) / 2)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion or event.button_mask != 0:
		view.queue_redraw()
	
	if event is InputEventMouseMotion and\
	event.button_mask in [MOUSE_BUTTON_MASK_LEFT, MOUSE_BUTTON_MASK_MIDDLE]:
		set_view(view.position - event.relative / zoom)
	
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
	var svg_size := get_svg_size()
	view.zoom = Vector2(zoom, zoom)
	view.limit_left = int(-size.x / zoom * buffer_view_space)
	view.limit_right = int(size.x / zoom * buffer_view_space + svg_size.x)
	view.limit_top = int(-size.y / zoom * buffer_view_space)
	view.limit_bottom = int(size.y / zoom * buffer_view_space + svg_size.y)
	set_view(view.position + (old_size - size / zoom) / 2.0)

func _on_size_changed() -> void:
	if is_node_ready():
		adjust_view()
