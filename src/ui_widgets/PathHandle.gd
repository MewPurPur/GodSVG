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
	if Input.is_key_pressed(KEY_CTRL):
		var cmd := pathdata.get_command(command_index)
		
		var opposite: PackedFloat64Array
		var offset: PackedFloat64Array
		if command_index != 0 and pathdata.get_command(command_index - 1).command_char in "CcSsQqLlHhVv" and\
		cmd.command_char in "CcQqLl" and not (cmd.command_char.to_lower() in "CcQq" and (x_param != "x1" or y_param != "y1")):
			# Using previous command.
			var other := pathdata.get_command(command_index - 1)
			offset = [cmd.start_x, cmd.start_y]
			
			match other.command_char:
				"C", "c", "S", "s": opposite = [other.x2, other.y2]
				"Q", "q": opposite = [other.x1, other.y1]
				"L", "l", "H", "h", "V", "v": opposite = [other.start_x, other.start_y]
		elif command_index < pathdata.get_command_count() - 1 and pathdata.get_command(command_index + 1).command_char in "CcQqLlHhVv" and\
		cmd.command_char in "CcSsQq" and not (cmd.command_char in "CcSs" and\
		(x_param != "x2" or y_param != "y2") or cmd.command_char in "Qq" and (x_param != "x1" or y_param != "y1")):
			# Using next command.
			var other := pathdata.get_command(command_index + 1)
			offset = [other.start_x, other.start_y]
			
			match other.command_char:
				"C", "c", "Q", "q": opposite = [other.x1, other.y1]
				"L", "l": opposite = [other.x, other.y]
				"H", "h": opposite = [other.x, other.start_y]
				"V", "v": opposite = [other.start_x, other.y]
		
		opposite = [opposite[0] - offset[0], opposite[1] - offset[1]]
		new_position = Utils64Bit.vector_project([new_position[0] - offset[0], new_position[1] - offset[1]], opposite)
		new_position = [new_position[0] + offset[0], new_position[1] + offset[1]]
	
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
