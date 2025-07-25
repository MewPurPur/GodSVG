extends Canvas

func change_zoom() -> void:
	camera_zoom = State.zoom

func update_show_grid() -> void:
	RenderingServer.canvas_item_set_visible(grid_ci, State.show_grid)
	RenderingServer.canvas_item_set_visible(grid_numbers_ci, State.show_grid)


func update() -> void:
	var new_position := camera_unsnapped_position.snapped(Vector2(1, 1) / camera_zoom)
	if camera_position != new_position:
		camera_position = new_position
		State.view_changed.emit()
	
	get_child(0).canvas_transform = Transform2D(0.0, Vector2(camera_zoom, camera_zoom),
			0.0, -camera_position * camera_zoom)
	queue_redraw()


# Don't ask me to explain this.
func _draw() -> void:
	RenderingServer.canvas_item_clear(grid_ci)
	RenderingServer.canvas_item_clear(grid_numbers_ci)
	
	var axis_line_color := Color(Configs.savedata.grid_color, 0.75)
	var major_grid_color := Color(Configs.savedata.grid_color, 0.35)
	var minor_grid_color := Color(Configs.savedata.grid_color, 0.15)
	
	var grid_size := Vector2(State.viewport_size) / camera_zoom
	RenderingServer.canvas_item_add_line(grid_ci, Vector2(-camera_position.x * camera_zoom, 0),
			Vector2(-camera_position.x * camera_zoom, grid_size.y * camera_zoom), axis_line_color)
	RenderingServer.canvas_item_add_line(grid_ci, Vector2(0, -camera_position.y * camera_zoom),
			Vector2(grid_size.x * camera_zoom, -camera_position.y * camera_zoom), axis_line_color)
	
	var major_points := PackedVector2Array()
	var minor_points := PackedVector2Array()
	var draw_minor_lines := (camera_zoom >= 8.0)
	var mark_pixel_lines := (camera_zoom >= 128.0)
	@warning_ignore("integer_division")
	var rate := nearest_po2(roundi(maxf(128.0 / (GRID_TICKS_INTERVAL * camera_zoom), 2.0))) / 2
	
	var i := fmod(-camera_position.x, 1.0)
	var major_line_h_offset := fposmod(-camera_position.x, GRID_TICK_DISTANCE)
	# Horizontal offset.
	while i <= grid_size.x:
		if major_line_h_offset != fposmod(i, GRID_TICK_DISTANCE):
			if draw_minor_lines:
				minor_points.append(Vector2(i * camera_zoom, 0))
				minor_points.append(Vector2(i * camera_zoom, grid_size.y * camera_zoom))
				if mark_pixel_lines:
					ThemeUtils.regular_font.draw_string(grid_numbers_ci,
							Vector2(i * camera_zoom + 4, 14), String.num_int64(floori(i + camera_position.x)),
							HORIZONTAL_ALIGNMENT_LEFT, -1, 14, axis_line_color)
		else:
			var coord := snappedi(i + camera_position.x, GRID_TICKS_INTERVAL)
			if int(coord / GRID_TICK_DISTANCE) % rate == 0:
				major_points.append(Vector2(i * camera_zoom, 0))
				major_points.append(Vector2(i * camera_zoom, grid_size.y * camera_zoom))
				ThemeUtils.regular_font.draw_string(grid_numbers_ci,
						Vector2(i * camera_zoom + 4, 14), String.num_int64(coord),
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14, axis_line_color)
			elif coord % rate == 0:
				minor_points.append(Vector2(i * camera_zoom, 0))
				minor_points.append(Vector2(i * camera_zoom, grid_size.y * camera_zoom))
		i += 1.0
	
	i = fmod(-camera_position.y, 1.0)
	var major_line_v_offset := fposmod(-camera_position.y, GRID_TICK_DISTANCE)
	# Vertical offset.
	while i < grid_size.y:
		if major_line_v_offset != fposmod(i, GRID_TICK_DISTANCE):
			if draw_minor_lines:
				minor_points.append(Vector2(0, i * camera_zoom))
				minor_points.append(Vector2(grid_size.x * camera_zoom, i * camera_zoom))
				if mark_pixel_lines:
					ThemeUtils.regular_font.draw_string(grid_numbers_ci,
							Vector2(4, i * camera_zoom + 14), String.num_int64(floori(i + camera_position.y)),
							HORIZONTAL_ALIGNMENT_LEFT, -1, 14, axis_line_color)
		else:
			var coord := snappedi(i + camera_position.y, GRID_TICKS_INTERVAL)
			if int(coord / GRID_TICK_DISTANCE) % rate == 0:
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
