extends Control

const main_lines = Color(0.5, 0.5, 0.5, 0.8)
const primary_grid_color = Color(0.5, 0.5, 0.5, 0.5)
const secondary_grid_color = Color(0.5, 0.5, 0.5, 0.2)

var snap_size := 2.0

@onready var display: TextureRect = %Checkerboard

func _ready() -> void:
	SVG.data.resized.connect(queue_redraw)

# TODO Expand on this feature with a different primary and secondary grid.
func _draw() -> void:
	var display_pos := display.position
	draw_line(Vector2(display_pos.x, 0), Vector2(display_pos.x, size.y), main_lines)
	draw_line(Vector2(0, display_pos.y), Vector2(size.x, display_pos.y), main_lines)
	
	if snap_size * get_parent().zoom_level < 3.0:
		return  # Too zoomed out to draw a grid.
	
	var primary_points := PackedVector2Array()
	var secondary_points := PackedVector2Array()
	var x_offset := fmod(display_pos.x, snap_size)
	var y_offset := fmod(display_pos.y, snap_size)
	var i := x_offset
	while i <= size.x:
		secondary_points.append(Vector2(i, 0))
		secondary_points.append(Vector2(i, size.y))
		i += snap_size
	i = y_offset
	while i < size.y:
		secondary_points.append(Vector2(0, i))
		secondary_points.append(Vector2(size.x, i))
		i += snap_size
	draw_multiline(secondary_points, secondary_grid_color)
	draw_multiline(primary_points, primary_grid_color)
