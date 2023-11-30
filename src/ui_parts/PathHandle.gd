## A handle that binds to one or two path parameters.
class_name PathHandle extends Handle

var path_attribute: AttributePath
var command_index: int
var x_param: StringName
var y_param: StringName

func _init(id: PackedInt32Array, path_ref: Attribute, command_idx: int,
x_name := &"x", y_name := &"y") -> void:
	path_attribute = path_ref
	tid = id
	command_index = command_idx
	x_param = x_name
	y_param = y_name
	sync()

func set_pos(new_pos: Vector2, undo_redo := false) -> void:
	var command := path_attribute.get_command(command_index)
	var new_coords := new_pos - command.start if command.relative else new_pos
	
	if undo_redo:
		if initial_pos != new_pos:
			path_attribute.set_command_property(command_index, x_param, new_coords.x,
					Attribute.SyncMode.NO_PROPAGATION)
			path_attribute.set_command_property(command_index, y_param, new_coords.y,
					Attribute.SyncMode.FINAL)
	else:
		if x_param in command:
			# Don't emit command_changed for the X change if there'll be a Y change too.
			path_attribute.set_command_property(command_index, x_param, new_coords.x,
					Attribute.SyncMode.NO_PROPAGATION if (y_param in command and\
					command.get(y_param) != new_pos.y) else Attribute.SyncMode.INTERMEDIATE)
			pos.x = new_pos.x
		else:
			pos.x = command.start.x
		if y_param in command:
			if command.get(y_param) != new_pos.y:
				path_attribute.set_command_property(command_index, y_param, new_coords.y,
						Attribute.SyncMode.INTERMEDIATE)
				pos.y = new_pos.y
		else:
			pos.y = command.start.y
		path_attribute.set_value(
				PathDataParser.path_commands_to_value(path_attribute.commands))


func sync() -> void:
	var command := path_attribute.get_command(command_index)
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
