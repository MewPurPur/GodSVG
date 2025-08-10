extends Canvas

const ViewportControls = preload("res://src/ui_parts/viewport.gd")
const HandlesManager = preload("res://src/ui_parts/handles_manager.gd")

const TICKS_INTERVAL = 4
const TICK_DISTANCE = float(TICKS_INTERVAL)

var ci := get_canvas_item()
var grid_ci := RenderingServer.canvas_item_create()
var grid_numbers_ci := RenderingServer.canvas_item_create()

var camera_zoom: float
var camera_position: Vector2
var camera_snapped_position: Vector2

var viewport := ViewportControls.new()
var display_texture := TextureRect.new()
var handles_manager := HandlesManager.new()
var checkerboard := TextureRect.new()
var reference_texture_rect: TextureRect

func _enter_tree() -> void:
	viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	viewport.handle_input_locally = false
	viewport.gui_snap_controls_to_pixels = false
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
	viewport.add_child(handles_manager)

func _ready() -> void:
	State.svg_changed.connect(queue_texture_update)
	State.view_rasterized_changed.connect(_on_view_rasterized_changed)
	queue_texture_update()
	State.zoom_changed.connect(_on_zoom_changed)
	State.svg_resized.connect(_on_svg_resized)
	
	Configs.active_tab_changed.connect(sync_reference_image)
	Configs.active_tab_reference_changed.connect(sync_reference_image)
	Configs.grid_color_changed.connect(queue_redraw)
	State.show_grid_changed.connect(update_show_grid)
	update_show_grid()
	RenderingServer.canvas_item_set_parent(grid_ci, ci)
	RenderingServer.canvas_item_set_parent(grid_numbers_ci, ci)
	State.svg_resized.connect(queue_redraw)

func exit_tree() -> void:
	RenderingServer.free_rid(grid_ci)
	RenderingServer.free_rid(grid_numbers_ci)

func _on_svg_resized() -> void:
	var root_element_size := State.root_element.get_size()
	if root_element_size.is_finite():
		checkerboard.size = root_element_size

func _on_zoom_changed() -> void:
	checkerboard.material.set_shader_parameter("uv_scale", nearest_po2(int(State.zoom * 32.0)) / 32.0)
	camera_zoom = State.zoom
	queue_texture_update()
	queue_redraw()

func update_show_grid() -> void:
	RenderingServer.canvas_item_set_visible(grid_ci, State.show_grid)
	RenderingServer.canvas_item_set_visible(grid_numbers_ci, State.show_grid)


func center_frame() -> void:
	viewport.center_frame()

func zoom_in() -> void:
	viewport.set_zoom(State.zoom * sqrt(2))

func zoom_out() -> void:
	viewport.set_zoom(State.zoom / sqrt(2))

func sync_reference_image() -> void:
	var active_tab := Configs.savedata.get_active_tab()
	if is_instance_valid(active_tab.reference_image):
		if not is_instance_valid(reference_texture_rect):
			reference_texture_rect = TextureRect.new()
			reference_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			reference_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			reference_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			viewport.add_child(reference_texture_rect)
			var _on_checkerboard_resized := func() -> void:
					reference_texture_rect.size = checkerboard.size
			checkerboard.resized.connect(_on_checkerboard_resized)
			reference_texture_rect.tree_exited.connect(checkerboard.resized.disconnect.bind(_on_checkerboard_resized))
			_on_checkerboard_resized.call()
		
		reference_texture_rect.texture = active_tab.reference_image
		reference_texture_rect.visible = active_tab.show_reference
		viewport.move_child(reference_texture_rect, -1 if active_tab.overlay_reference else 0)
	elif is_instance_valid(reference_texture_rect):
		reference_texture_rect.queue_free()

func update() -> void:
	var new_snapped_position := camera_position.snapped(Vector2(1, 1) / camera_zoom)
	if camera_snapped_position != new_snapped_position:
		camera_snapped_position = new_snapped_position
		State.view_changed.emit()
	
	get_child(0).canvas_transform = Transform2D(0.0, Vector2(camera_zoom, camera_zoom), 0.0, -camera_snapped_position * camera_zoom)
	queue_redraw()


# Don't ask me to explain this.
func _draw() -> void:
	RenderingServer.canvas_item_clear(grid_ci)
	RenderingServer.canvas_item_clear(grid_numbers_ci)
	
	var axis_line_color := Color(Configs.savedata.grid_color, 0.75)
	var major_grid_color := Color(Configs.savedata.grid_color, 0.35)
	var minor_grid_color := Color(Configs.savedata.grid_color, 0.15)
	
	var grid_size := Vector2(viewport.size) / camera_zoom
	RenderingServer.canvas_item_add_line(grid_ci, Vector2(-camera_snapped_position.x * camera_zoom, 0),
			Vector2(-camera_snapped_position.x * camera_zoom, grid_size.y * camera_zoom), axis_line_color)
	RenderingServer.canvas_item_add_line(grid_ci, Vector2(0, -camera_snapped_position.y * camera_zoom),
			Vector2(grid_size.x * camera_zoom, -camera_snapped_position.y * camera_zoom), axis_line_color)
	
	var major_points := PackedVector2Array()
	var minor_points := PackedVector2Array()
	var draw_minor_lines := (camera_zoom >= 8.0)
	var mark_pixel_lines := (camera_zoom >= 128.0)
	@warning_ignore("integer_division")
	var rate := nearest_po2(roundi(maxf(128.0 / (TICKS_INTERVAL * camera_zoom), 2.0))) / 2
	
	var i := fmod(-camera_snapped_position.x, 1.0)
	var major_line_h_offset := fposmod(-camera_snapped_position.x, TICK_DISTANCE)
	# Horizontal offset.
	while i <= grid_size.x:
		if major_line_h_offset != fposmod(i, TICK_DISTANCE):
			if draw_minor_lines:
				minor_points.append(Vector2(i * camera_zoom, 0))
				minor_points.append(Vector2(i * camera_zoom, grid_size.y * camera_zoom))
				if mark_pixel_lines:
					ThemeUtils.regular_font.draw_string(grid_numbers_ci,
							Vector2(i * camera_zoom + 4, 14), String.num_int64(floori(i + camera_snapped_position.x)),
							HORIZONTAL_ALIGNMENT_LEFT, -1, 14, axis_line_color)
		else:
			var coord := snappedi(i + camera_snapped_position.x, TICKS_INTERVAL)
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
	
	i = fmod(-camera_snapped_position.y, 1.0)
	var major_line_v_offset := fposmod(-camera_snapped_position.y, TICK_DISTANCE)
	# Vertical offset.
	while i < grid_size.y:
		if major_line_v_offset != fposmod(i, TICK_DISTANCE):
			if draw_minor_lines:
				minor_points.append(Vector2(0, i * camera_zoom))
				minor_points.append(Vector2(grid_size.x * camera_zoom, i * camera_zoom))
				if mark_pixel_lines:
					ThemeUtils.regular_font.draw_string(grid_numbers_ci,
							Vector2(4, i * camera_zoom + 14), String.num_int64(floori(i + camera_snapped_position.y)),
							HORIZONTAL_ALIGNMENT_LEFT, -1, 14, axis_line_color)
		else:
			var coord := snappedi(i + camera_snapped_position.y, TICKS_INTERVAL)
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


var view_rect := Rect2():
	set(new_value):
		if view_rect != new_value:
			view_rect = new_value
			queue_texture_update()

var _texture_update_pending := false

func _on_view_rasterized_changed() -> void:
	if State.zoom != 1.0:
		queue_texture_update()


func queue_texture_update() -> void:
	_texture_update.call_deferred()
	_texture_update_pending = true

func _texture_update() -> void:
	if not _texture_update_pending:
		return
	
	_texture_update_pending = false
	
	var image_zoom := 1.0 if State.view_rasterized and State.zoom > 1.0 else State.zoom
	var pixel_size := 1 / image_zoom
	
	# Translate to canvas coords.
	var display_rect := view_rect.grow(pixel_size * 2)
	display_rect.position = display_rect.position.snapped(Vector2(pixel_size, pixel_size))
	display_rect.position.x = maxf(display_rect.position.x, 0.0)
	display_rect.position.y = maxf(display_rect.position.y, 0.0)
	display_rect.size = display_rect.size.snapped(Vector2(pixel_size, pixel_size))
	display_rect.end.x = minf(display_rect.end.x, ceili(State.root_element.width))
	display_rect.end.y = minf(display_rect.end.y, ceili(State.root_element.height))
	
	var svg_text := SVGParser.root_cutout_to_markup(State.root_element, display_rect.size.x,
			display_rect.size.y, Rect2(State.root_element.world_to_canvas(display_rect.position),
			display_rect.size / State.root_element.canvas_transform.get_scale()))
	Utils.set_control_position_fixed(display_texture, display_rect.position)
	display_texture.set_deferred("size", display_rect.size)
	display_texture.texture = SVGTexture.create_from_string(svg_text, image_zoom)
