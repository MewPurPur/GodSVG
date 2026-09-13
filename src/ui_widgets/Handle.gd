## Base class for handles.
@abstract class_name Handle

enum Display {BIG, SMALL, SQUARE}
var display_mode := Display.BIG

var cached_position_on_canvas: Vector2

var element: Element
var precise_transform := PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
var precise_position := PackedFloat64Array([0.0, 0.0])

func _init() -> void:
	pass

func sync() -> void:
	precise_transform = element.get_precise_transform()
	cached_position_on_canvas = element.get_transform() * Vector2(precise_position[0], precise_position[1])

func set_position(_new_position: Vector2, _snap_size: float) -> void:
	pass

# Alignment axes are batches of 4 coordinates representing lines: [x1, y1, x2, y2].
func apply_restrictions(unrestricted_position: Vector2, snap_size: float, constraining_axes: Array[PackedFloat64Array] = []) -> PackedFloat64Array:
	var final_position := PackedFloat64Array([snappedf(unrestricted_position.x, snap_size), snappedf(unrestricted_position.y, snap_size)])
	var closest_distance_squared := INF
	
	var element_transform := element.get_precise_transform()
	
	for line in constraining_axes:
		var pos1 := Utils64Bit.transform_vector_mult(element_transform, [line[0], line[1]])
		var pos2 := Utils64Bit.transform_vector_mult(element_transform, [line[2], line[3]])
		line[0] = pos1[0]
		line[1] = pos1[1]
		line[2] = pos2[0]
		line[3] = pos2[1]
		
		var direction := PackedFloat64Array([line[0] - line[2], line[1] - line[3]])
		var projected := Utils64Bit.vector_project([unrestricted_position.x - line[2], unrestricted_position.y - line[3]], direction)
		
		if direction[0] != 0:
			var grid_x := floorf((projected[0] + line[2]) / snap_size) * snap_size
			for x: float in [grid_x, grid_x + snap_size]:
				var projected_position := [x, line[3] + direction[1] * (x - line[2]) / direction[0]]
				var distance_squared := Utils64Bit.distance_squared_to(projected_position, [unrestricted_position.x, unrestricted_position.y])
				if distance_squared < closest_distance_squared:
					closest_distance_squared = distance_squared
					final_position = projected_position
		if direction[1] != 0:
			var grid_y := floorf((projected[1] + line[3]) / snap_size) * snap_size
			for y: float in [grid_y, grid_y + snap_size]:
				var projected_position := [line[2] + direction[0] * (y - line[3]) / direction[1], y]
				var distance_squared := Utils64Bit.distance_squared_to(projected_position, [unrestricted_position.x, unrestricted_position.y])
				if distance_squared < closest_distance_squared:
					closest_distance_squared = distance_squared
					final_position = projected_position
	
	return Utils64Bit.transform_vector_mult(Utils64Bit.get_transform_affine_inverse(element_transform), final_position)
