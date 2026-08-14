# A handle that binds to one or two path parameters.
class_name PathHandle extends Handle

const pathdata_name = "d"
var command_index: int
var x_param: String
var y_param: String


func _init(new_element: Element, new_command_index: int, x_name: String, y_name: String) -> void:
	element = new_element
	command_index = new_command_index
	x_param = x_name
	y_param = y_name
	element.attribute_changed.connect(_on_attribute_changed)
	element.ancestor_attribute_changed.connect(sync.unbind(1))
	sync()

func set_position(new_position: PackedFloat64Array) -> void:
	if precise_position == new_position:
		return
	var pathdata: AttributePathdata = element.get_attribute(pathdata_name)
	
	# Constrain to match the angle of the neighboring segment if Ctrl is pressed.
	# Quadratic beziers can have two neighboring segments, align to the closest.
	if Input.is_key_pressed(KEY_CTRL):
		var cmd := pathdata.get_command(command_index)
		var cmd_char := cmd.command_char.to_lower()
		var subpath := pathdata.get_subpath(command_index)
		
		# Batches of 4 coordinates representing lines: [x1, y1, x2, y2].
		var alignment_lines: Array[PackedFloat64Array] = []
		
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
					"c", "s": alignment_lines.append(new_line + PackedFloat64Array([prev_cmd.x2, prev_cmd.y2]))
					"q": alignment_lines.append(new_line + PackedFloat64Array([prev_cmd.x1, prev_cmd.y1]))
					"l", "h", "v": alignment_lines.append(new_line + PackedFloat64Array([prev_cmd.start_x, prev_cmd.start_y]))
		
		if (cmd_char in "cs" and x_param == "x2" and y_param == "y2") or (cmd_char in "q" and x_param == "x1" and y_param == "y1"):
			var next_cmd_index := command_index
			while true:
				next_cmd_index += 1
				if next_cmd_index > subpath.y and pathdata.get_command(subpath.y) is PathCommand.CloseCommand:
					next_cmd_index = subpath.x
				if not pathdata.is_command_zero_length(next_cmd_index) or next_cmd_index == command_index:
					break
			if next_cmd_index != command_index:
				var next_cmd := pathdata.get_command(next_cmd_index)
				var new_line := PackedFloat64Array([cmd.x, cmd.y])
				match next_cmd.command_char.to_lower():
					"c", "q": alignment_lines.append(new_line + PackedFloat64Array([next_cmd.x1, next_cmd.y1]))
					"l": alignment_lines.append(new_line + PackedFloat64Array([next_cmd.x, next_cmd.y]))
					"h": alignment_lines.append(new_line + PackedFloat64Array([next_cmd.x, next_cmd.start_y]))
					"v": alignment_lines.append(new_line + PackedFloat64Array([next_cmd.start_x, next_cmd.y]))
					"z":
						var start_command := pathdata.get_command(subpath.x)
						alignment_lines.append(new_line + PackedFloat64Array([start_command.x, start_command.y]))
		
		var closest_distance := INF
		for line in alignment_lines:
			var direction := [line[0] - line[2], line[1] - line[3]]
			var relative_position := [new_position[0] - line[2], new_position[1] - line[3]]
			var projected := Utils64Bit.vector_project(relative_position, direction)
			var projected_position := [projected[0] + line[2], projected[1] + line[3]]
			var distance := Utils64Bit.distance_squared_to(projected_position, new_position)
			if distance < closest_distance:
				closest_distance = distance
				new_position = projected_position
	
	pathdata.set_command_property(command_index, x_param, new_position[0])
	pathdata.set_command_property(command_index, y_param, new_position[1])
	sync()

func sync() -> void:
	if command_index >= element.get_attribute(pathdata_name).get_command_count():
		# Handle might have been removed.
		return
	var command: PathCommand = element.get_attribute(pathdata_name).get_command(command_index)
	precise_position[0] = command.get(x_param) if x_param in command else command.start_x
	precise_position[1] = command.get(y_param) if y_param in command else command.start_y
	super()


func _on_attribute_changed(name: String) -> void:
	if name in [pathdata_name, "transform"]:
		sync()
