extends SubViewport

const min_zoom = 0.125
const max_zoom = 64.0
const minimum_visible_proportion = 0.3

@onready var display: TextureRect = $Checkerboard
@onready var snap_lines: Control = $SnapLines
@onready var main_node: VBoxContainer = %Display
@onready var display_texture: TextureRect = $Checkerboard/DisplayTexture
@onready var controls: Control = $Checkerboard/Controls

var zoom_level: float:
	set(new_value):
		zoom_level = clampf(new_value, min_zoom, max_zoom)
		main_node.update_zoom_widget(zoom_level)
		size_2d_override = size / zoom_level
		display.material.set_shader_parameter(&"uv_scale",
				nearest_po2(int(zoom_level * 32)) / 32.0)
		clamp_view()
		controls.zoom = zoom_level
		display_texture.zoom = zoom_level
		snap_lines.queue_redraw()


func _ready() -> void:
	zoom_reset()  # Do this first so zoom_level is not 0.
	SVG.root_tag.attribute_changed.connect(resize)
	resize()

func clamp_view() -> void:
	var min_pos := Utils.vec_min((minimum_visible_proportion - 1) * display.size,
			minimum_visible_proportion * size / zoom_level - display.size)
	var max_pos := Utils.vec_max(size / zoom_level - minimum_visible_proportion *\
			display.size, (1 - minimum_visible_proportion) * size / zoom_level)
	display.position = display.position.clamp(min_pos, max_pos)


# TODO implement the ability to zoom in a specific area.
func zoom_in() -> void:
	zoom_level *= sqrt(2)
	center_frame()

func zoom_out() -> void:
	zoom_level /= sqrt(2)
	center_frame()

func zoom_reset() -> void:
	var svg_attribs := SVG.root_tag.attributes
	zoom_level = float(nearest_po2(int(8192 / maxf(svg_attribs.width.get_value(),
			svg_attribs.height.get_value()))) / 32.0)
	center_frame()


func resize() -> void:
	var svg_attribs := SVG.root_tag.attributes
	display.size = Vector2(svg_attribs.width.get_value(), svg_attribs.height.get_value())
	center_frame()

func center_frame() -> void:
	display.position = (size / zoom_level - display.size) / 2.0


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion or event.button_mask != 0:
		snap_lines.queue_redraw()
	if event is InputEventMouseMotion and\
	event.button_mask in [MOUSE_BUTTON_MASK_LEFT, MOUSE_BUTTON_MASK_MIDDLE]:
		display.position += event.relative
		clamp_view()
	
	if event is InputEventPanGesture:
		if event.ctrl_pressed:
			zoom_level *= 1 + event.delta.y / 2
		else:
			display.position -= event.delta * 32
			clamp_view()
	
	if event is InputEventMagnifyGesture:
		zoom_level *= event.factor
	
	if event is InputEventMouseButton and event.is_pressed():
		# "event.position / zoom_level - display.position"
		# Use this to get the position according to the texture.
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				zoom_in()
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out()
		clamp_view()
	
	if event is InputEventMouseButton:
		if event.ctrl_pressed:
			pass
