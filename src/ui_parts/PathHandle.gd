class_name PathHandle extends Handle

var path_attribute: Attribute
var command_index: int

func _init(path_ref: Attribute, idx: int) -> void:
	path_attribute = path_ref
	command_index = idx
	sync()

func set_pos(new_pos: Vector2) -> void:
	var commands := PathCommandArray.new()
	commands.data = PathDataParser.parse_path_data(path_attribute.value)
	commands.locate_start_points()
	var command := commands.get_command(command_index)
	if &"x" in command:
		commands.set_command_property(command_index, &"x",
				new_pos.x - command.start.x if command.relative else new_pos.x)
		pos.x = new_pos.x
	else:
		pos.x = command.start.x
	if &"y" in command:
		commands.set_command_property(command_index, &"y",
				new_pos.y - command.start.y if command.relative else new_pos.y)
		pos.y = new_pos.y
	else:
		pos.y = command.start.y
	path_attribute.value = PathDataParser.path_commands_to_value(commands)
	super(new_pos)


func sync() -> void:
	var commands := PathCommandArray.new()
	commands.data = PathDataParser.parse_path_data(path_attribute.value)
	commands.locate_start_points()
	var command := commands.get_command(command_index)
	if &"x" in command:
		pos.x = command.start.x + command.x if command.relative else command.x
	else:
		pos.x = command.start.x
	if &"y" in command:
		pos.y = command.start.y + command.y if command.relative else command.y
	else:
		pos.y = command.start.y
