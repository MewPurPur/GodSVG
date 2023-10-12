extends Control

const main_line_color = Color(0.5, 0.5, 0.5, 0.8)
const primary_grid_color = Color(0.5, 0.5, 0.5, 0.4)
const pixel_grid_color = Color(0.5, 0.5, 0.5, 0.16)

var ticks_interval := 4

@onready var display: TextureRect = %Checkerboard

func _ready() -> void:
	SVG.data.resized.connect(queue_redraw)

# Don't ask me to explain this.
func _draw() -> void:
	for child in get_children():
		child.free()
	
	var display_pos := display.position
	draw_line(Vector2(display_pos.x, 0), Vector2(display_pos.x, size.y), main_line_color)
	draw_line(Vector2(0, display_pos.y), Vector2(size.x, display_pos.y), main_line_color)
	
	var primary_points := PackedVector2Array()
	var pixel_points := PackedVector2Array()
	var x_offset := fmod(display_pos.x, 1.0)
	var y_offset := fmod(display_pos.y, 1.0)
	var tick_distance := float(ticks_interval)
	var viewport_scale: float = get_parent().zoom_level
	var draw_pixel_lines := viewport_scale >= 3.0
	var rate := nearest_po2(int(maxf(48.0 / (ticks_interval * viewport_scale), 1.0)))
	
	var i := x_offset
	while i <= size.x:
		if fposmod(display_pos.x, tick_distance) != fposmod(i, tick_distance):
			if draw_pixel_lines:
				pixel_points.append(Vector2(i, 0))
				pixel_points.append(Vector2(i, size.y))
		else:
			var coord := snappedi(i - display_pos.x, ticks_interval)
			@warning_ignore("integer_division")
			if (coord / ticks_interval) % rate == 0:
				primary_points.append(Vector2(i, 0))
				primary_points.append(Vector2(i, size.y))
				var label := Label.new()
				label.text = str(coord)
				label.add_theme_color_override(&"font_color", main_line_color)
				label.add_theme_font_size_override(&"font_size", 14)
				label.scale = Vector2(1, 1) / viewport_scale
				label.position = Vector2(i + 4 / viewport_scale, 0)
				add_child(label)
			elif coord % rate == 0:
				pixel_points.append(Vector2(i, 0))
				pixel_points.append(Vector2(i, size.y))
		i += 1.0
	i = y_offset
	while i < size.y:
		if fposmod(display_pos.y, tick_distance) != fposmod(i, tick_distance):
			if draw_pixel_lines:
				pixel_points.append(Vector2(0, i))
				pixel_points.append(Vector2(size.x, i))
		else:
			var coord := snappedi(i - display_pos.y, ticks_interval)
			@warning_ignore("integer_division")
			if int(coord / ticks_interval) % rate == 0:
				primary_points.append(Vector2(0, i))
				primary_points.append(Vector2(size.x, i))
				var label := Label.new()
				label.text = str(coord)
				label.add_theme_color_override(&"font_color", main_line_color)
				label.add_theme_font_size_override(&"font_size", 14)
				label.scale = Vector2(1, 1) / viewport_scale
				label.position = Vector2(4 / viewport_scale, i)
				add_child(label)
			elif coord % rate == 0:
				pixel_points.append(Vector2(0, i))
				pixel_points.append(Vector2(size.x, i))
		i += 1.0
	draw_multiline(primary_points, primary_grid_color)
	draw_multiline(pixel_points, pixel_grid_color)
