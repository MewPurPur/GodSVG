extends Camera2D

const default_font = preload("res://visual/fonts/Font.ttf")
const main_line_color = Color(0.5, 0.5, 0.5, 0.8)
const primary_grid_color = Color(0.5, 0.5, 0.5, 0.4)
const pixel_grid_color = Color(0.5, 0.5, 0.5, 0.16)
const ticks_interval = 4

var surface := RenderingServer.canvas_item_create()  # Used for drawing the numbers.

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	SVG.root_tag.attribute_changed.connect(queue_redraw)

# Don't ask me to explain this.
func _draw() -> void:
	var size: Vector2 = get_parent().size / get_parent().zoom_level
	draw_line(Vector2(-position.x, 0), Vector2(-position.x, size.y), main_line_color)
	draw_line(Vector2(0, -position.y), Vector2(size.x, -position.y), main_line_color)
	
	var primary_points := PackedVector2Array()
	var pixel_points := PackedVector2Array()
	var x_offset := fmod(-position.x, 1.0)
	var y_offset := fmod(-position.y, 1.0)
	var tick_distance := float(ticks_interval)
	var viewport_scale: float = get_parent().zoom_level
	var draw_pixel_lines := viewport_scale >= 3.0
	var rate := nearest_po2(roundi(maxf(64.0 / (ticks_interval * viewport_scale), 1.0)))
	
	# The grid lines are always 1px wide, but the numbers need to be resized.
	RenderingServer.canvas_item_clear(surface)
	RenderingServer.canvas_item_set_transform(surface,
			Transform2D(0, Vector2(1, 1) / viewport_scale, 0, Vector2.ZERO))
	
	var i := x_offset
	while i <= size.x:
		if fposmod(-position.x, tick_distance) != fposmod(i, tick_distance):
			if draw_pixel_lines:
				pixel_points.append(Vector2(i, 0))
				pixel_points.append(Vector2(i, size.y))
		else:
			var coord := snappedi(i + position.x, ticks_interval)
			if (coord / ticks_interval) % rate == 0:
				primary_points.append(Vector2(i, 0))
				primary_points.append(Vector2(i, size.y))
				default_font.draw_string(surface, Vector2(i * viewport_scale + 4, 14),
						str(coord), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, main_line_color)
			elif coord % rate == 0:
				pixel_points.append(Vector2(i, 0))
				pixel_points.append(Vector2(i, size.y))
		i += 1.0
	i = y_offset
	while i < size.y:
		if fposmod(-position.y, tick_distance) != fposmod(i, tick_distance):
			if draw_pixel_lines:
				pixel_points.append(Vector2(0, i))
				pixel_points.append(Vector2(size.x, i))
		else:
			var coord := snappedi(i + position.y, ticks_interval)
			if int(coord / ticks_interval) % rate == 0:
				primary_points.append(Vector2(0, i))
				primary_points.append(Vector2(size.x, i))
				default_font.draw_string(surface, Vector2(4, i * viewport_scale + 14),
						str(coord), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, main_line_color)
			elif coord % rate == 0:
				pixel_points.append(Vector2(0, i))
				pixel_points.append(Vector2(size.x, i))
		i += 1.0
	draw_multiline(primary_points, primary_grid_color)
	draw_multiline(pixel_points, pixel_grid_color)
