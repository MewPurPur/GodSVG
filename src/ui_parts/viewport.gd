extends SubViewport

const buffer_view_space = 0.8

@onready var display: TextureRect = %Checkerboard
@onready var view: Camera2D = $ViewCamera
@onready var controls: Control = %Checkerboard/Controls
@onready var display_texture: Control = %Checkerboard/DisplayTexture
@onready var zoom_menu: HBoxContainer = %ZoomMenu


func _ready() -> void:
	SVG.root_tag.attribute_changed.connect(resize)
	SVG.root_tag.changed_unknown.connect(resize)
	zoom_menu.zoom_reset()
	resize()
	update_view_limits()

func update_view_limits() -> void:
	view.limit_left = int(-size_2d_override.x * buffer_view_space)
	view.limit_right = int(size_2d_override.x * buffer_view_space + display.size.x)
	view.limit_top = int(-size_2d_override.y * buffer_view_space)
	view.limit_bottom = int(size_2d_override.y * buffer_view_space + display.size.y)
	set_view(view.position)  # Ensure the view is still clamped.

# Top left corner.
func set_view(new_position: Vector2) -> void:
	view.position = new_position.clamp(Vector2(view.limit_left, view.limit_top),
			Vector2(view.limit_right, view.limit_bottom) - size_2d_override * 1.0)


func resize() -> void:
	var svg_attribs := SVG.root_tag.attributes
	display.size = Vector2(svg_attribs.width.get_value(), svg_attribs.height.get_value())
	center_frame()

func center_frame() -> void:
	view.position = (display.size - size_2d_override * 1.0) / 2.0


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion or event.button_mask != 0:
		view.queue_redraw()
	
	if event is InputEventMouseMotion and\
	event.button_mask in [MOUSE_BUTTON_MASK_LEFT, MOUSE_BUTTON_MASK_MIDDLE]:
		set_view(view.position - event.relative)
	
	if event is InputEventPanGesture:
		if event.ctrl_pressed:
			zoom_menu.zoom_level *= 1 + event.delta.y / 2
		else:
			set_view(view.position + event.delta * 32)
	
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
	var old_size_2d_override := size_2d_override
	size_2d_override = size / zoom_level
	set_view(view.position + (old_size_2d_override - size_2d_override) / 2.0)
	display.material.set_shader_parameter(&"uv_scale",
			nearest_po2(int(zoom_level * 32)) / 32.0)
	update_view_limits()
	controls.zoom = zoom_level
	display_texture.zoom = zoom_level
	view.queue_redraw()
