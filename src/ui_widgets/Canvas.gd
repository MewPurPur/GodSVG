## A canvas node representing an editing area for an SVG. This node is extended for the main canvas.
## It can be used by itself for previews.
class_name Canvas extends SubViewportContainer

const HandlesManager = preload("res://src/ui_widgets/handles_manager.gd")
const ViewportControls = preload("res://src/ui_widgets/viewport_controls.gd")

const TICKS_INTERVAL = 4
const TICK_DISTANCE = float(TICKS_INTERVAL)
const MIN_ZOOM = 0.125
const MAX_ZOOM = 512.0

## The ratio of empty space the canvas could have when the camera is scrolled to its limits.
const BUFFER_VIEW_SPACE = 0.8

## The ratio of empty space the canvas could have at most after the center frame.
const ZOOM_RESET_BUFFER = 0.875

var root_element: ElementRoot:
	set(new_value):
		if root_element != new_value:
			root_element = new_value
			if is_instance_valid(root_element) and is_instance_valid(checkerboard):
				sync_checkerboard()

var hovered_xid := PackedInt32Array()
var selected_xids: Array[PackedInt32Array] = []
var selection_pivot_xid := PackedInt32Array()

var semi_hovered_xid := PackedInt32Array()
var semi_selected_xid := PackedInt32Array()
var inner_hovered := -1
var inner_selections: Array[int] = []
var inner_selection_pivot := -1

# These methods are duplicated from State.
func is_hovered(xid: PackedInt32Array, inner_idx := -1, propagate := false) -> bool:
	if propagate:
		if XIDUtils.is_ancestor_or_self(hovered_xid, xid):
			return true
		if inner_idx == -1:
			return false
		return inner_hovered == inner_idx and semi_hovered_xid == xid
	if inner_idx == -1:
		return hovered_xid == xid
	return inner_hovered == inner_idx and semi_hovered_xid == xid

func is_selected(xid: PackedInt32Array, inner_idx := -1, propagate := false) -> bool:
	if propagate:
		for selected_xid in selected_xids:
			if XIDUtils.is_ancestor_or_self(selected_xid, xid):
				return true
		if inner_idx == -1:
			return false
		return semi_selected_xid == xid and inner_idx in inner_selections
	if inner_idx == -1:
		return xid in selected_xids
	return semi_selected_xid == xid and inner_idx in inner_selections


signal camera_zoom_changed
signal camera_center_changed

var camera_zoom := -1.0:
	set(new_value):
		if camera_zoom != new_value:
			camera_zoom = new_value
			checkerboard.material.set_shader_parameter("uv_scale", nearest_po2(int(camera_zoom * 32.0)) / 32.0)
			sync_canvas_transform()
			queue_texture_update()
			queue_redraw()
			camera_zoom_changed.emit()

var camera_center := Vector2.ZERO:
	set(new_value):
		if camera_center != new_value:
			camera_center = new_value
			sync_canvas_transform()
			HandlerGUI.throw_mouse_motion_event()
			queue_redraw()
			camera_center_changed.emit()

var view_rasterized := false
var show_grid := true
var show_handles := true

var ci := get_canvas_item()
var grid_ci := RenderingServer.canvas_item_create()
var grid_numbers_ci := RenderingServer.canvas_item_create()

var viewport := ViewportControls.new()
var display_texture := TextureRect.new()
var handles_manager := HandlesManager.new()
var checkerboard := TextureRect.new()


func _init() -> void:
	stretch = true
	clip_contents = true

func _enter_tree() -> void:
	viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	viewport.gui_snap_controls_to_pixels = false
	viewport.canvas = self
	add_child(viewport)
	checkerboard.texture = load("res://assets/icons/Checkerboard.svg")
	checkerboard.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	checkerboard.stretch_mode = TextureRect.STRETCH_TILE
	checkerboard.texture_filter = TEXTURE_FILTER_NEAREST
	var zoom_shader_material := ShaderMaterial.new()
	zoom_shader_material.shader = load("res://src/shaders/zoom_shader.gdshader")
	checkerboard.material = zoom_shader_material
	viewport.add_child(checkerboard)
	display_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display_texture.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	checkerboard.add_child(display_texture)
	handles_manager.mouse_filter = Control.MOUSE_FILTER_PASS
	handles_manager.canvas = self
	viewport.add_child(handles_manager)

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(grid_ci, ci)
	RenderingServer.canvas_item_set_parent(grid_numbers_ci, ci)
	Configs.grid_color_changed.connect(queue_redraw)
	update_show_grid()
	
	resized.connect(sync_canvas_transform)
	resized.connect(adjust_view)
	resized.connect(center_frame)
	for i in 2:
		await get_tree().process_frame
	resized.disconnect(center_frame)

func _exit_tree() -> void:
	RenderingServer.free_rid(grid_ci)
	RenderingServer.free_rid(grid_numbers_ci)


func toggle_view_rasterized() -> void:
	view_rasterized = not view_rasterized
	if camera_zoom != 1.0:
		queue_texture_update()

func toggle_show_grid() -> void:
	show_grid = not show_grid
	update_show_grid()

func toggle_show_handles() -> void:
	show_handles = not show_handles
	handles_manager.update_show_handles()

func center_frame() -> void:
	var available_size := size * ZOOM_RESET_BUFFER
	var ratio := available_size / root_element.get_size()
	if ratio.is_finite():
		var new_zoom := nearest_po2(ceili(minf(ratio.x, ratio.y) * 32.0)) / 64.0
		camera_zoom = new_zoom
	else:
		camera_zoom = 1.0
	
	adjust_view()
	set_view(root_element.get_size() / 2.0)

func sync_canvas_transform() -> void:
	viewport.canvas_transform = Transform2D(0.0, Vector2(camera_zoom, camera_zoom), 0.0, -get_camera_position() * camera_zoom)


var texture_view_rect := Rect2():
	set(new_value):
		if texture_view_rect != new_value:
			texture_view_rect = new_value
			queue_texture_update()

var _texture_update_pending := false
var _texture_update_dirty_inner_markup := false

## Use [param dirty_inner] if the inner markup has changed and needs to be restringified.
func queue_texture_update(dirty_inner := false) -> void:
	_texture_update.call_deferred()
	_texture_update_pending = true
	_texture_update_dirty_inner_markup = _texture_update_dirty_inner_markup or dirty_inner

var last_inner_markup: String

func _texture_update() -> void:
	if not _texture_update_pending:
		return
	
	_texture_update_pending = false
	
	var image_zoom := 1.0 if view_rasterized and camera_zoom > 1.0 else camera_zoom
	var pixel_size := 1 / image_zoom
	
	# Translate to canvas coords.
	var display_rect := texture_view_rect.grow(pixel_size * 2)
	display_rect.position = display_rect.position.snapped(Vector2(pixel_size, pixel_size)).maxf(0.0)
	display_rect.size = display_rect.size.snapped(Vector2(pixel_size, pixel_size))
	display_rect.end = display_rect.end.min(Vector2(ceili(root_element.width), ceili(root_element.height)))
	
	if _texture_update_dirty_inner_markup:
		_texture_update_dirty_inner_markup = false
		last_inner_markup = ""
	
	var svg_text := SVGParser.root_cutout_to_markup(root_element, display_rect.size.x,
			display_rect.size.y, Rect2(root_element.world_to_canvas(display_rect.position),
			display_rect.size / root_element.canvas_transform.get_scale()), last_inner_markup)
	last_inner_markup = svg_text[1]
	Utils.set_control_position_fixed(display_texture, display_rect.position)
	display_texture.size = display_rect.size
	display_texture.texture = SVGTexture.create_from_string(svg_text[0], image_zoom)


func sync_checkerboard() -> void:
	var root_element_size := root_element.get_size()
	if root_element_size.is_finite():
		checkerboard.size = root_element_size


func update_show_grid() -> void:
	RenderingServer.canvas_item_set_visible(grid_ci, show_grid)
	RenderingServer.canvas_item_set_visible(grid_numbers_ci, show_grid)
	queue_redraw()

# Don't ask me to explain this.
func _draw() -> void:
	RenderingServer.canvas_item_clear(grid_ci)
	RenderingServer.canvas_item_clear(grid_numbers_ci)
	
	var snapped_pos := get_camera_position()
	var axis_line_color := Color(Configs.savedata.grid_color, 0.75)
	var major_grid_color := Color(Configs.savedata.grid_color, 0.35)
	var minor_grid_color := Color(Configs.savedata.grid_color, 0.15)
	
	var grid_size := size / camera_zoom
	RenderingServer.canvas_item_add_line(grid_ci, Vector2(-snapped_pos.x * camera_zoom, 0),
			Vector2(-snapped_pos.x * camera_zoom, grid_size.y * camera_zoom), axis_line_color)
	RenderingServer.canvas_item_add_line(grid_ci, Vector2(0, -snapped_pos.y * camera_zoom),
			Vector2(grid_size.x * camera_zoom, -snapped_pos.y * camera_zoom), axis_line_color)
	
	var major_points := PackedVector2Array()
	var minor_points := PackedVector2Array()
	var draw_minor_lines := (camera_zoom >= 8.0)
	var mark_pixel_lines := (camera_zoom >= 128.0)
	@warning_ignore("integer_division")
	var rate := nearest_po2(roundi(maxf(128.0 / (TICKS_INTERVAL * camera_zoom), 2.0))) / 2
	
	var i := fmod(-snapped_pos.x, 1.0)
	var major_line_h_offset := fposmod(-snapped_pos.x, TICK_DISTANCE)
	# Horizontal offset.
	while i <= grid_size.x:
		if major_line_h_offset != fposmod(i, TICK_DISTANCE):
			if draw_minor_lines:
				minor_points.append(Vector2(i * camera_zoom, 0))
				minor_points.append(Vector2(i * camera_zoom, grid_size.y * camera_zoom))
				if mark_pixel_lines:
					ThemeUtils.regular_font.draw_string(grid_numbers_ci,
							Vector2(i * camera_zoom + 4, 14), String.num_int64(floori(i + snapped_pos.x)),
							HORIZONTAL_ALIGNMENT_LEFT, -1, 14, axis_line_color)
		else:
			var coord := snappedi(i + snapped_pos.x, TICKS_INTERVAL)
			if int(coord / TICK_DISTANCE) % rate == 0:
				major_points.append(Vector2(i * camera_zoom, 0))
				major_points.append(Vector2(i * camera_zoom, grid_size.y * camera_zoom))
				ThemeUtils.regular_font.draw_string(grid_numbers_ci,
						Vector2(i * camera_zoom + 4, 14), String.num_int64(coord),
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14, axis_line_color)
			elif coord % rate == 0:
				minor_points.append(Vector2(i * camera_zoom, 0))
				minor_points.append(Vector2(i * camera_zoom, grid_size.y * camera_zoom))
		i += 1.0
	
	i = fmod(-snapped_pos.y, 1.0)
	var major_line_v_offset := fposmod(-snapped_pos.y, TICK_DISTANCE)
	# Vertical offset.
	while i < grid_size.y:
		if major_line_v_offset != fposmod(i, TICK_DISTANCE):
			if draw_minor_lines:
				minor_points.append(Vector2(0, i * camera_zoom))
				minor_points.append(Vector2(grid_size.x * camera_zoom, i * camera_zoom))
				if mark_pixel_lines:
					ThemeUtils.regular_font.draw_string(grid_numbers_ci,
							Vector2(4, i * camera_zoom + 14), String.num_int64(floori(i + snapped_pos.y)),
							HORIZONTAL_ALIGNMENT_LEFT, -1, 14, axis_line_color)
		else:
			var coord := snappedi(i + snapped_pos.y, TICKS_INTERVAL)
			if int(coord / TICK_DISTANCE) % rate == 0:
				major_points.append(Vector2(0, i * camera_zoom))
				major_points.append(Vector2(grid_size.x * camera_zoom, i * camera_zoom))
				ThemeUtils.regular_font.draw_string(grid_numbers_ci,
						Vector2(4, i * camera_zoom + 14), String.num_int64(coord),
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14, axis_line_color)
			elif coord % rate == 0:
				minor_points.append(Vector2(0, i * camera_zoom))
				minor_points.append(Vector2(grid_size.x * camera_zoom, i * camera_zoom))
		i += 1.0
	
	if not major_points.is_empty():
		var pca := PackedColorArray()
		@warning_ignore("integer_division")
		pca.resize(major_points.size() / 2)
		pca.fill(major_grid_color)
		RenderingServer.canvas_item_add_multiline(grid_ci, major_points, pca)
	if not minor_points.is_empty():
		var pca := PackedColorArray()
		@warning_ignore("integer_division")
		pca.resize(minor_points.size() / 2)
		pca.fill(minor_grid_color)
		RenderingServer.canvas_item_add_multiline(grid_ci, minor_points, pca)


func get_camera_position() -> Vector2:
	return (camera_center - size / camera_zoom / 2.0).snapped(Vector2(1, 1) / camera_zoom)


var limit_top_left := Vector2.ZERO
var limit_bottom_right := Vector2.ZERO


func set_zoom(new_zoom: float, offset := Vector2(0.5, 0.5)) -> void:
	camera_zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	adjust_view(offset)

# Top left corner.
func set_view(new_center: Vector2) -> void:
	camera_center = new_center.clamp(limit_top_left, limit_bottom_right)
	
	var stripped_left := maxf(camera_center.x - size.x / camera_zoom / 2.0, 0.0)
	var stripped_top := maxf(camera_center.y - size.y / camera_zoom / 2.0, 0.0)
	var stripped_right := minf(camera_center.x + size.x / camera_zoom / 2.0, root_element.width)
	var stripped_bottom := minf(camera_center.y + size.y / camera_zoom / 2.0, root_element.height)
	texture_view_rect = Rect2(stripped_left, stripped_top, stripped_right - stripped_left, stripped_bottom - stripped_top)


var last_size_adjusted := Vector2.ZERO

func adjust_view(offset := Vector2(0.5, 0.5)) -> void:
	var old_size := last_size_adjusted
	last_size_adjusted = size / camera_zoom
	
	var buffer_size := (BUFFER_VIEW_SPACE - 0.5) * size / camera_zoom
	limit_top_left = -buffer_size
	limit_bottom_right = buffer_size + Vector2(root_element.width if root_element.has_attribute("width") else 16384.0,
			root_element.height if root_element.has_attribute("height") else 16384.0)
	
	set_view(camera_center + (offset - Vector2(0.5, 0.5)) * (old_size - size / camera_zoom))


func wrap_mouse(relative: Vector2) -> Vector2:
	var view_rect := Rect2(Vector2.ZERO, size).grow(-1.0)
	var warp_margin := view_rect.size * 0.5
	var mouse_pos := get_local_mouse_position()
	
	if not view_rect.has_point(mouse_pos):
		warp_mouse(Vector2(fposmod(mouse_pos.x, view_rect.size.x), fposmod(mouse_pos.y, view_rect.size.y)))
	
	return Vector2(fmod(relative.x + signf(relative.x) * warp_margin.x, view_rect.size.x),
			fmod(relative.y + signf(relative.y) * warp_margin.y, view_rect.size.y)) - relative.sign() * warp_margin
