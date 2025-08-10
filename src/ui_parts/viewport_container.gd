extends SubViewportContainer

const TICKS_INTERVAL = 4
const TICK_DISTANCE = float(TICKS_INTERVAL)

var ci := get_canvas_item()
var grid_ci := RenderingServer.canvas_item_create()
var grid_numbers_ci := RenderingServer.canvas_item_create()

var camera_zoom: float:
	set(new_value):
		if camera_zoom != new_value:
			camera_zoom = new_value
			sync_canvas_transform()

var camera_center: Vector2:
	set(new_value):
		if camera_center != new_value:
			camera_center = new_value
			sync_canvas_transform()

@onready var viewport: SubViewport = $Viewport
@onready var checkerboard: TextureRect = $Viewport/Checkerboard

var reference_texture_rect: TextureRect

func _ready() -> void:
	Configs.active_tab_changed.connect(sync_reference_image)
	Configs.active_tab_reference_changed.connect(sync_reference_image)
	Configs.grid_color_changed.connect(queue_redraw)
	State.show_grid_changed.connect(update_show_grid)
	update_show_grid()
	RenderingServer.canvas_item_set_parent(grid_ci, ci)
	RenderingServer.canvas_item_set_parent(grid_numbers_ci, ci)
	State.svg_resized.connect(queue_redraw)
	Configs.active_tab_view_changed.connect(sync_view)

func _exit_tree() -> void:
	RenderingServer.free_rid(grid_ci)
	RenderingServer.free_rid(grid_numbers_ci)

func sync_view() -> void:
	camera_center = Configs.savedata.get_active_tab().camera_center
	camera_zoom = Configs.savedata.get_active_tab().camera_zoom

func update_show_grid() -> void:
	RenderingServer.canvas_item_set_visible(grid_ci, State.show_grid)
	RenderingServer.canvas_item_set_visible(grid_numbers_ci, State.show_grid)


func sync_canvas_transform() -> void:
	viewport.canvas_transform = Transform2D(0.0, Vector2(camera_zoom, camera_zoom), 0.0, -get_camera_position() * camera_zoom)
	queue_redraw()

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


# Don't ask me to explain this.
func _draw() -> void:
	RenderingServer.canvas_item_clear(grid_ci)
	RenderingServer.canvas_item_clear(grid_numbers_ci)
	
	var camera_pos := get_camera_position()
	var axis_line_color := Color(Configs.savedata.grid_color, 0.75)
	var major_grid_color := Color(Configs.savedata.grid_color, 0.35)
	var minor_grid_color := Color(Configs.savedata.grid_color, 0.15)
	
	var grid_size := Vector2(viewport.size) / camera_zoom
	RenderingServer.canvas_item_add_line(grid_ci, Vector2(-camera_pos.x * camera_zoom, 0),
			Vector2(-camera_pos.x * camera_zoom, grid_size.y * camera_zoom), axis_line_color)
	RenderingServer.canvas_item_add_line(grid_ci, Vector2(0, -camera_pos.y * camera_zoom),
			Vector2(grid_size.x * camera_zoom, -camera_pos.y * camera_zoom), axis_line_color)
	
	var major_points := PackedVector2Array()
	var minor_points := PackedVector2Array()
	var draw_minor_lines := (camera_zoom >= 8.0)
	var mark_pixel_lines := (camera_zoom >= 128.0)
	@warning_ignore("integer_division")
	var rate := nearest_po2(roundi(maxf(128.0 / (TICKS_INTERVAL * camera_zoom), 2.0))) / 2
	
	var i := fmod(-camera_pos.x, 1.0)
	var major_line_h_offset := fposmod(-camera_pos.x, TICK_DISTANCE)
	# Horizontal offset.
	while i <= grid_size.x:
		if major_line_h_offset != fposmod(i, TICK_DISTANCE):
			if draw_minor_lines:
				minor_points.append(Vector2(i * camera_zoom, 0))
				minor_points.append(Vector2(i * camera_zoom, grid_size.y * camera_zoom))
				if mark_pixel_lines:
					ThemeUtils.regular_font.draw_string(grid_numbers_ci,
							Vector2(i * camera_zoom + 4, 14), String.num_int64(floori(i + camera_pos.x)),
							HORIZONTAL_ALIGNMENT_LEFT, -1, 14, axis_line_color)
		else:
			var coord := snappedi(i + camera_pos.x, TICKS_INTERVAL)
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
	
	i = fmod(-camera_pos.y, 1.0)
	var major_line_v_offset := fposmod(-camera_pos.y, TICK_DISTANCE)
	# Vertical offset.
	while i < grid_size.y:
		if major_line_v_offset != fposmod(i, TICK_DISTANCE):
			if draw_minor_lines:
				minor_points.append(Vector2(0, i * camera_zoom))
				minor_points.append(Vector2(grid_size.x * camera_zoom, i * camera_zoom))
				if mark_pixel_lines:
					ThemeUtils.regular_font.draw_string(grid_numbers_ci,
							Vector2(4, i * camera_zoom + 14), String.num_int64(floori(i + camera_pos.y)),
							HORIZONTAL_ALIGNMENT_LEFT, -1, 14, axis_line_color)
		else:
			var coord := snappedi(i + camera_pos.y, TICKS_INTERVAL)
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
	return (camera_center - viewport.size / 2.0).snapped(Vector2(1, 1) / camera_zoom)
