# A handle that binds to one or two path parameters.
class_name PathHandle extends Handle

const pathdata_name = "d"
var command_index: int
var x_param: String
var y_param: String

func _init(new_element: Element, command_idx: int, x_name := "x", y_name := "y") -> void:
	element = new_element
	command_index = command_idx
	x_param = x_name
	y_param = y_name
	sync()

func set_pos(new_pos: Vector2) -> void:
	var path_attribute: AttributePathdata = element.get_attribute(pathdata_name)
	var command := path_attribute.get_command(command_index)
	var new_coords := new_pos - command.start if command.relative else new_pos
	if pos != new_pos:
		pos = new_pos
		path_attribute.set_command_property(command_index, x_param, new_coords.x)
		path_attribute.set_command_property(command_index, y_param, new_coords.y)


func sync() -> void:
	var command: PathCommand =\
			element.get_attribute(pathdata_name).get_command(command_index)
	if x_param in command:
		var command_x: float = command.get(x_param)
		pos.x = command.start.x + command_x if command.relative else command_x
	else:
		pos.x = command.start.x
	if y_param in command:
		var command_y: float = command.get(y_param)
		pos.y = command.start.y + command_y if command.relative else command_y
	else:
		pos.y = command.start.y
	super()
