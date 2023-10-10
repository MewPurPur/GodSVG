extends Control

@onready var display: TextureRect = %Checkerboard

const main_lines = Color(0.5, 0.5, 0.5, 0.75)
const primary_grid_color = Color(0.5, 0.5, 0.5, 0.5)
const secondary_grid_color = Color(0.5, 0.5, 0.5, 0.25)

# TODO Expand on this feature.
func _draw() -> void:
	var primary_points := PackedVector2Array()
	var secondary_points := PackedVector2Array()
	var x_offset := fmod(display.position.x, 2.0)
	var y_offset := fmod(display.position.y, 2.0)
	var i := x_offset
	while i <= size.x:
		secondary_points.append(Vector2(i, 0))
		secondary_points.append(Vector2(i, size.y))
		i += 2.0
	i = y_offset
	while i < size.y:
		secondary_points.append(Vector2(0, i))
		secondary_points.append(Vector2(size.x, i))
		i += 2.0
	draw_multiline(secondary_points, secondary_grid_color)
	draw_multiline(primary_points, primary_grid_color)
	var display_pos := display.position
	draw_line(Vector2(display_pos.x, 0), Vector2(display_pos.x, size.y), main_lines)
	draw_line(Vector2(0, display_pos.y), Vector2(size.x, display_pos.y), main_lines)
