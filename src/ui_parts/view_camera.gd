extends Camera2D

const default_font = preload("res://visual/fonts/Font.ttf")
const axis_line_color = Color(0.5, 0.5, 0.5, 0.75)
const major_grid_color = Color(0.5, 0.5, 0.5, 0.35)
const minor_grid_color = Color(0.5, 0.5, 0.5, 0.15)
const ticks_interval = 4

var surface := RenderingServer.canvas_item_create()  # Used for drawing the numbers.

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	SVG.root_tag.resized.connect(queue_redraw)
	Indications.zoom_changed.connect(change_zoom)
	Indications.zoom_changed.connect(queue_redraw)

func change_zoom() -> void:
	zoom = Vector2(Indications.zoom, Indications.zoom)

# Don't ask me to explain this.
func _draw() -> void:
	var size: Vector2 = Indications.viewport_size * 1.0 / zoom
	draw_line(Vector2(-position.x, 0), Vector2(-position.x, size.y), axis_line_color)
	draw_line(Vector2(0, -position.y), Vector2(size.x, -position.y), axis_line_color)
	
	var major_points := PackedVector2Array()
	var minor_points := PackedVector2Array()
	var x_offset := fmod(-position.x, 1.0)
	var y_offset := fmod(-position.y, 1.0)
	var tick_distance := float(ticks_interval)
	var zoom_level := zoom.x
	var draw_minor_lines := zoom_level >= 3.0
	var rate := nearest_po2(roundi(maxf(64.0 / (ticks_interval * zoom_level), 1.0)))
	
	# The grid lines are always 1px wide, but the numbers need to be resized.
	RenderingServer.canvas_item_clear(surface)
	RenderingServer.canvas_item_set_transform(surface,
			Transform2D(0, Vector2(1, 1) / zoom, 0, Vector2.ZERO))
	
	var i := x_offset
	while i <= size.x:
		if fposmod(-position.x, tick_distance) != fposmod(i, tick_distance):
			if draw_minor_lines:
				minor_points.append(Vector2(i, 0))
				minor_points.append(Vector2(i, size.y))
		else:
			var coord := snappedi(i + position.x, ticks_interval)
			if int(float(coord) / ticks_interval) % rate == 0:
				major_points.append(Vector2(i, 0))
				major_points.append(Vector2(i, size.y))
				default_font.draw_string(surface, Vector2(i * zoom_level + 4, 14),
						String.num_int64(coord), HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
						axis_line_color)
			elif coord % rate == 0:
				minor_points.append(Vector2(i, 0))
				minor_points.append(Vector2(i, size.y))
		i += 1.0
	i = y_offset
	while i < size.y:
		if fposmod(-position.y, tick_distance) != fposmod(i, tick_distance):
			if draw_minor_lines:
				minor_points.append(Vector2(0, i))
				minor_points.append(Vector2(size.x, i))
		else:
			var coord := snappedi(i + position.y, ticks_interval)
			if int(coord / float(ticks_interval)) % rate == 0:
				major_points.append(Vector2(0, i))
				major_points.append(Vector2(size.x, i))
				default_font.draw_string(surface, Vector2(4, i * zoom_level + 14),
						String.num_int64(coord), HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
						axis_line_color)
			elif coord % rate == 0:
				minor_points.append(Vector2(0, i))
				minor_points.append(Vector2(size.x, i))
		i += 1.0
	if not major_points.is_empty():
		draw_multiline(major_points, major_grid_color)
	draw_multiline(minor_points, minor_grid_color)
