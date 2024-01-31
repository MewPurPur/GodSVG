extends SubViewport

const ZoomMenuType = preload("res://src/ui_parts/zoom_menu.gd")
const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")

const buffer_view_space = 0.8
const zoom_reset_buffer = 0.875

# Holds zoom position for ctrl + middle mouse zooming.
var _zoom_to: Vector2

@onready var display: TextureRect = %Checkerboard
@onready var view: Camera2D = $ViewCamera
@onready var controls: Control = %Checkerboard/Controls
@onready var display_texture: TextureRect = %Checkerboard/DisplayTexture
@onready var zoom_menu: ZoomMenuType = %ZoomMenu


func _ready() -> void:
	SVG.root_tag.resized.connect(resize)
	Indications.viewport_size_changed.connect(adjust_view)
	resize()
	await get_tree().process_frame
	zoom_menu.zoom_reset()

# Top left corner.
func set_view(new_position: Vector2) -> void:
	var scaled_size := size / Indications.zoom
	view.position = new_position.clamp(Vector2(view.limit_left, view.limit_top),
			Vector2(view.limit_right, view.limit_bottom) - scaled_size)
	
	var stripped_left := maxf(view.position.x, 0.0)
	var stripped_top := maxf(view.position.y, 0.0)
	var stripped_right := minf(view.position.x + scaled_size.x, SVG.root_tag.width)
	var stripped_bottom := minf(view.position.y + scaled_size.y, SVG.root_tag.height)
	display_texture.view_rect = Rect2(stripped_left, stripped_top,
			stripped_right - stripped_left, stripped_bottom - stripped_top)
	view.queue_redraw()


# Adjust the SVG dimensions.
func resize() -> void:
	if SVG.root_tag.get_size().is_finite():
		display.size = SVG.root_tag.get_size()
		zoom_menu.zoom_reset()

func center_frame() -> void:
	var available_size := size * zoom_reset_buffer
	var w_ratio := available_size.x / SVG.root_tag.width
	var h_ratio := available_size.y / SVG.root_tag.height
	zoom_menu.set_zoom(nearest_po2(ceili(minf(w_ratio, h_ratio) * 32)) / 64.0)
	adjust_view()
	set_view((SVG.root_tag.get_size() - size / Indications.zoom) / 2)

func create_object_context() -> Popup:
	var btn_array: Array[Button] = []
	var new_tid := PackedInt32Array([SVG.root_tag.get_child_count()])
	var mouse_position := (get_mouse_position() / Indications.zoom + view.position).snapped(Vector2.ONE * GlobalSettings.save_data.snap)
	
	for tag in [TagPath.new(), TagCircle.new(), TagEllipse.new(), TagRect.new(), TagLine.new()]:
		if tag is TagPath:
			tag.attributes["d"]._commands.append(PathCommand.MoveCommand.new(0.0, 0.0, false))
		
		tag.attributes["transform"].set_transform_list([AttributeTransform.TransformTranslate.new(mouse_position.x, mouse_position.y)] as Array[AttributeTransform.Transform])
		btn_array.append(Utils.create_btn(tr(tag.name), SVG.root_tag.add_tag.bind(tag, new_tid), false, tag.icon))

	var object_context := ContextPopup.instantiate()
	add_child(object_context)
	object_context.set_button_array(btn_array, true)
	return object_context

func _unhandled_input(event: InputEvent) -> void:
	if Indications.get_viewport().gui_is_dragging():
		return
	
	if event is InputEventMouseMotion and\
	event.button_mask in [MOUSE_BUTTON_MASK_LEFT, MOUSE_BUTTON_MASK_MIDDLE]:
		
		# Zooming with ctrl + middle mouse button.
		if event.ctrl_pressed and event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			if _zoom_to == Vector2.ZERO:  # Set zoom posiion if starting action. 
				_zoom_to = get_mouse_position() / (size * 1.0)
			zoom_menu.set_zoom(
				Indications.zoom * (1.0 + \
				(1 if GlobalSettings.invert_zoom else -1) \
				 * (wrap_mouse(event.relative).y \
				if GlobalSettings.wrap_mouse else event.relative.y) / 128.0),
				_zoom_to)
				
		# Panning with left or middle mouse button.
		else:
			set_view(view.position - (wrap_mouse(event.relative)\
					if GlobalSettings.wrap_mouse else event.relative) / Indications.zoom)
	
	elif event is InputEventPanGesture:
		
		# Zooming with ctrl + touch?
		if event.ctrl_pressed:
			zoom_menu.set_zoom(Indications.zoom * (1 + event.delta.y / 2))
		
		# Panning with touch.
		else:
			set_view(view.position + event.delta * 32 / Indications.zoom)
	
	# Zooming with touch.
	elif event is InputEventMagnifyGesture:
		zoom_menu.set_zoom(Indications.zoom * event.factor)
	
	# Actions with scrolling.
	elif event is InputEventMouseButton and event.is_pressed():
		var move_vec := Vector2.ZERO
		var zoom_dir := 0
		var mouse_offset := get_mouse_position() / (size * 1.0)
		
		if event.button_index == MOUSE_BUTTON_RIGHT and $Checkerboard/Controls.hovered_handle == null:
			Utils.popup_under_mouse(create_object_context(), get_parent().get_viewport().get_mouse_position())
		
		# Zooming with scrolling.
		if (not event.ctrl_pressed and not event.shift_pressed and\
		not GlobalSettings.use_ctrl_for_zoom) or\
		(event.ctrl_pressed and GlobalSettings.use_ctrl_for_zoom):
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP when GlobalSettings.invert_zoom: zoom_dir = -1
				MOUSE_BUTTON_WHEEL_DOWN when GlobalSettings.invert_zoom: zoom_dir = 1
				MOUSE_BUTTON_WHEEL_UP: zoom_dir = 1
				MOUSE_BUTTON_WHEEL_DOWN: zoom_dir = -1
		
		# Inverted panning with shift + scrolling.
		elif event.shift_pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP: move_vec = Vector2.LEFT
				MOUSE_BUTTON_WHEEL_DOWN: move_vec = Vector2.RIGHT
				MOUSE_BUTTON_WHEEL_LEFT: move_vec = Vector2.UP
				MOUSE_BUTTON_WHEEL_RIGHT: move_vec = Vector2.DOWN
		
		# Panning with scrolling.
		else:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP: move_vec = Vector2.UP
				MOUSE_BUTTON_WHEEL_DOWN: move_vec = Vector2.DOWN
				MOUSE_BUTTON_WHEEL_LEFT: move_vec = Vector2.LEFT
				MOUSE_BUTTON_WHEEL_RIGHT: move_vec = Vector2.RIGHT
		
		# Apply scroll data from above.
		var factor: float = event.factor
		if factor == roundf(factor):  # Detects if precise factor is unsuported.
			factor = 1.0
		if zoom_dir == 1:
			zoom_menu.zoom_in(factor, mouse_offset)
		elif zoom_dir == -1:
			zoom_menu.zoom_out(factor, mouse_offset)
		
		set_view(view.position + move_vec * factor / Indications.zoom * 32)
	
	else:
		_zoom_to = Vector2.ZERO  # Reset ctrl + middle mouse zoom position if released.


func _on_zoom_changed(new_zoom_level: float, offset: Vector2) -> void:
	Indications.set_zoom(new_zoom_level)
	adjust_view(offset)
	display.material.set_shader_parameter(&"uv_scale",
			nearest_po2(int(Indications.zoom * 32.0)) / 32.0)

var last_size_adjusted := size / Indications.zoom
func adjust_view(offset := Vector2(0.5, 0.5)) -> void:
	var old_size := last_size_adjusted
	last_size_adjusted = size / Indications.zoom
	
	var zoomed_size := buffer_view_space * size / Indications.zoom
	view.limit_left = int(-zoomed_size.x)
	view.limit_right = int(zoomed_size.x + SVG.root_tag.width)
	view.limit_top = int(-zoomed_size.y)
	view.limit_bottom = int(zoomed_size.y + SVG.root_tag.height)
	set_view(Vector2(lerpf(view.position.x,
			view.position.x + old_size.x - size.x / Indications.zoom, offset.x),
			lerpf(view.position.y, view.position.y + old_size.y - size.y / Indications.zoom,
			offset.y)))

func _on_size_changed() -> void:
	Indications.set_viewport_size(size)

func wrap_mouse(relative: Vector2) -> Vector2:
	var view_rect := get_visible_rect().grow(-1.0)
	var warp_margin := view_rect.size * 0.5
	var mouse_pos := get_mouse_position()
	
	if not view_rect.has_point(mouse_pos):
		warp_mouse(Vector2(fposmod(mouse_pos.x, view_rect.size.x),
				fposmod(mouse_pos.y, view_rect.size.y)))
	
	return Vector2(fmod(relative.x + signf(relative.x) * warp_margin.x, view_rect.size.x),
			fmod(relative.y + signf(relative.y) * warp_margin.y, view_rect.size.y)) -\
			relative.sign() * warp_margin
