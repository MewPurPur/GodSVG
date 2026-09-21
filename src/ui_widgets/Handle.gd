## Base class for handles.
class_name Handle

enum Display {BIG, SMALL, SQUARE}
var display_mode := Display.BIG

var cached_position_on_canvas: Vector2

var element: Element
var inner_index := -1
var set_position_callback: Callable
var sync_callback: Callable
var precise_transform := PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
var precise_position := PackedFloat64Array([0.0, 0.0])

func _init(new_element: Element, new_inner_index := -1) -> void:
	element = new_element
	inner_index = new_inner_index


func set_position(new_position: Vector2, snap_size: float) -> void:
	set_position_callback.call(new_position, snap_size)

func sync() -> void:
	sync_callback.call()
	precise_transform = element.get_precise_transform()
	cached_position_on_canvas = element.get_transform() * Vector2(precise_position[0], precise_position[1])

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


static func create_as_xy(new_element: Element, x_name: String, y_name: String) -> Handle:
	var handle := Handle.new(new_element)
	
	handle.set_position_callback =\
		func(new_position: Vector2, snap_size: float) -> void:
			var final_position := handle.apply_restrictions(new_position, snap_size)
			if handle.precise_position != final_position:
				handle.element.set_attribute(x_name, final_position[0])
				handle.element.set_attribute(y_name, final_position[1])
				handle.sync()
	
	handle.sync_callback =\
		func() -> void:
			handle.precise_position[0] = handle.element.get_attribute_num(x_name)
			handle.precise_position[1] = handle.element.get_attribute_num(y_name)
	
	handle.sync()
	return handle


static func create_as_delta(new_element: Element, x_name: String, y_name: String, d_name: String, horizontal: bool) -> Handle:
	var handle := Handle.new(new_element)
	handle.display_mode = Display.SMALL
	
	handle.set_position_callback =\
		func(new_position: Vector2, snap_size: float) -> void:
			var x_pos := handle.element.get_attribute_num(x_name)
			var y_pos := handle.element.get_attribute_num(y_name)
			if horizontal:
				var final_position := handle.apply_restrictions(new_position, snap_size, [PackedFloat64Array([x_pos, y_pos, x_pos + 1, y_pos])])
				if handle.precise_position != final_position:
					handle.element.set_attribute(d_name, absf(final_position[0] - handle.element.get_attribute_num(x_name)))
			else:
				var final_position := handle.apply_restrictions(new_position, snap_size, [PackedFloat64Array([x_pos, y_pos, x_pos, y_pos + 1])])
				if handle.precise_position != final_position:
					handle.element.set_attribute(d_name, absf(final_position[1] - handle.element.get_attribute_num(y_name)))
			handle.sync()
	
	handle.sync_callback =\
		func() -> void:
			handle.precise_position = [handle.element.get_attribute_num(x_name), handle.element.get_attribute_num(y_name)]
			handle.precise_position[0 if horizontal else 1] += handle.element.get_attribute_num(d_name)
	
	handle.sync()
	return handle

static func create_as_path(path_element: Element, command_index: int, x_param: String, y_param: String) -> Handle:
	var handle := Handle.new(path_element, command_index)
	if handle.element.get_attribute("d").get_command(command_index) is PathCommand.MoveCommand:
		handle.display_mode = Display.SQUARE
	elif (x_param == "x1" and y_param == "y1") or (x_param == "x2" and y_param == "y2"):
		handle.display_mode = Display.SMALL
	
	handle.set_position_callback =\
		func(new_position: Vector2, snap_size: float) -> void:
			var pathdata: AttributePathdata = handle.element.get_attribute("d")
			var cmd := pathdata.get_command(command_index)
			
			# Batches of 4 coordinates representing lines: [x1, y1, x2, y2].
			var constraining_axes: Array[PackedFloat64Array] = []
			if x_param.is_empty():
				constraining_axes.append(PackedFloat64Array([cmd.start_x, cmd.start_y, cmd.start_x, cmd.start_y + 1.0]))
			elif y_param.is_empty():
				constraining_axes.append(PackedFloat64Array([cmd.start_x, cmd.start_y, cmd.start_x + 1.0, cmd.start_y]))
			
			# Generate constraining axes Constrain to match the angle of the neighboring segment if Ctrl is pressed.
			# Quadratic beziers can have two neighboring segments.
			if Input.is_key_pressed(KEY_CTRL):
				var cmd_char := cmd.command_char.to_lower()
				var subpath := pathdata.get_subpath(command_index)
				
				if cmd_char in "l" or (cmd_char in "cq" and x_param == "x1" and y_param == "y1"):
					var prev_cmd_index := command_index
					while true:
						prev_cmd_index -= 1
						if prev_cmd_index < subpath.x and pathdata.get_command(subpath.y) is PathCommand.CloseCommand:
							prev_cmd_index = subpath.y
						if not pathdata.is_command_zero_length(prev_cmd_index) or prev_cmd_index == command_index:
							break
					if prev_cmd_index != command_index:
						var prev_cmd := pathdata.get_command(prev_cmd_index)
						var new_line := PackedFloat64Array([cmd.start_x, cmd.start_y])
						match prev_cmd.command_char.to_lower():
							"c", "s": constraining_axes.append(new_line + PackedFloat64Array([prev_cmd.x2, prev_cmd.y2]))
							"q": constraining_axes.append(new_line + PackedFloat64Array([prev_cmd.x1, prev_cmd.y1]))
							"l", "h", "v", "z": constraining_axes.append(new_line + PackedFloat64Array([prev_cmd.start_x, prev_cmd.start_y]))
				
				if (cmd_char in "cs" and x_param == "x2" and y_param == "y2") or (cmd_char in "q" and x_param == "x1" and y_param == "y1"):
					var next_cmd_index := command_index
					while true:
						next_cmd_index += 1
						if next_cmd_index > subpath.y:
							if pathdata.get_command(subpath.y) is PathCommand.CloseCommand:
								next_cmd_index = subpath.x
							else:
								next_cmd_index = command_index
						if not pathdata.is_command_zero_length(next_cmd_index) or next_cmd_index == command_index:
							break
					if next_cmd_index != command_index:
						var next_cmd := pathdata.get_command(next_cmd_index)
						var new_line := PackedFloat64Array([cmd.x, cmd.y])
						match next_cmd.command_char.to_lower():
							"c", "q": constraining_axes.append(new_line + PackedFloat64Array([next_cmd.x1, next_cmd.y1]))
							"l": constraining_axes.append(new_line + PackedFloat64Array([next_cmd.x, next_cmd.y]))
							"h": constraining_axes.append(new_line + PackedFloat64Array([next_cmd.x, next_cmd.start_y]))
							"v": constraining_axes.append(new_line + PackedFloat64Array([next_cmd.start_x, next_cmd.y]))
							"z":
								var start_command := pathdata.get_command(subpath.x)
								constraining_axes.append(new_line + PackedFloat64Array([start_command.x, start_command.y]))
			
			var final_position := handle.apply_restrictions(new_position, snap_size, constraining_axes)
			if handle.precise_position == final_position:
				return
			
			pathdata.set_command_property(command_index, x_param, final_position[0])
			pathdata.set_command_property(command_index, y_param, final_position[1])
			handle.sync()
	
	handle.sync_callback =\
		func() -> void:
			var pathdata := handle.element.get_attribute("d")
			if command_index >= pathdata.get_command_count():
				return  # Handle might have been removed.
			var command: PathCommand = pathdata.get_command(command_index)
			handle.precise_position[0] = command.get(x_param) if x_param in command else command.start_x
			handle.precise_position[1] = command.get(y_param) if y_param in command else command.start_y
	
	handle.sync()
	return handle

static func create_as_poly(poly_element: Element, point_index: int) -> Handle:
	var handle := Handle.new(poly_element, point_index)
	if point_index == 0:
		handle.display_mode = Display.SQUARE
	
	handle.set_position_callback =\
		func(new_position: Vector2, snap_size: float) -> void:
			var final_position := handle.apply_restrictions(new_position, snap_size)
			if handle.precise_position != final_position:
				var attrib := handle.element.get_attribute("points")
				attrib.set_list_element(point_index * 2, final_position[0])
				attrib.set_list_element(point_index * 2 + 1, final_position[1])
				handle.sync()
	
	handle.sync_callback =\
		func() -> void:
			var list := handle.element.get_attribute_list("points")
			if point_index * 2 >= list.size():
				return  # Handle might have been removed.
			handle.precise_position[0] = list[point_index * 2]
			handle.precise_position[1] = list[point_index * 2 + 1]
	
	handle.sync()
	return handle
