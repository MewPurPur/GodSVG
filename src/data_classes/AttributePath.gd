## The "d" attribute of [TagPath].
class_name AttributePath extends Attribute

var _commands: Array[PathCommand]

func _init() -> void:
	default = ""
	set_value(default, SyncMode.SILENT)

func _sync() -> void:
	_commands = PathDataParser.parse_path_data(get_value())
	locate_start_points()

func autoformat(text: String) -> String:
	if GlobalSettings.path_enable_autoformatting:
		return PathDataParser.path_commands_to_text(PathDataParser.parse_path_data(text))
	else:
		return text


func set_commands(new_commands: Array[PathCommand], sync_mode := SyncMode.LOUD) -> void:
	_commands = new_commands
	sync_after_commands_change(sync_mode)

func sync_after_commands_change(sync_mode := SyncMode.LOUD) -> void:
	super.set_value(PathDataParser.path_commands_to_text(_commands), sync_mode)


func locate_start_points() -> void:
	# Start points are absolute.
	var last_end_point := Vector2.ZERO
	var current_subpath_start := Vector2.ZERO
	for command in _commands:
		command.start = last_end_point
		
		if command is PathCommand.MoveCommand:
			current_subpath_start = command.start if command.relative else Vector2.ZERO
			current_subpath_start += Vector2(command.x, command.y)
		elif command is PathCommand.CloseCommand:
			last_end_point = current_subpath_start
			continue
		
		# Prepare for the next iteration.
		if command.relative:
			if &"x" in command:
				last_end_point.x += command.x
			if &"y" in command:
				last_end_point.y += command.y
		else:
			if &"x" in command:
				last_end_point.x = command.x
			if &"y" in command:
				last_end_point.y = command.y


func get_command_count() -> int:
	return _commands.size()

func get_command(idx: int) -> PathCommand:
	return _commands[idx]

# Return the start and end indices of the subpath.
func get_subpath(idx: int) -> Vector2i:
	var output := Vector2i(idx, idx)
	# Subpaths start from the last M command, or the commmand after the last Z command.
	while output.x > 0:
		if get_command(output.x) is PathCommand.MoveCommand or\
		get_command(output.x - 1) is PathCommand.CloseCommand:
			break
		output.x -= 1
	while output.y < get_command_count() - 1:
		if get_command(output.y + 1) is PathCommand.MoveCommand or\
		get_command(output.y) is PathCommand.CloseCommand:
			break
		output.y += 1
	return output


func set_command_property(idx: int, property: StringName, new_value: float,
sync_mode := SyncMode.LOUD) -> void:
	if _commands[idx].get(property) != new_value or sync_mode == SyncMode.FINAL:
		_commands[idx].set(property, new_value)
		sync_after_commands_change(sync_mode)

func insert_command(idx: int, command_char: String) -> void:
	_commands.insert(idx, PathCommand.translation_dict[command_char.to_upper()].new())
	if Utils.is_string_lower(command_char):
		_commands[idx].toggle_relative()
	sync_after_commands_change()


func convert_command(idx: int, command_char: String) -> void:
	var old_cmd: PathCommand = _commands[idx]
	if old_cmd.command_char == command_char:
		return
	
	var cmd_absolute_char := command_char.to_upper()
	var new_cmd: PathCommand = PathCommand.translation_dict[cmd_absolute_char].new()
	_commands.remove_at(idx)
	_commands.insert(idx, new_cmd)
	for property in [&"x", &"y", &"x1", &"y1", &"x2", &"y2"]:
		if property in old_cmd and property in new_cmd:
			new_cmd[property] = old_cmd[property]
	
	var is_relative := Utils.is_string_lower(command_char)
	
	if &"x" in new_cmd and not &"x" in old_cmd:
		new_cmd.x = 0.0 if is_relative else old_cmd.start.x
	if &"y" in new_cmd and not &"y" in old_cmd:
		new_cmd.y = 0.0 if is_relative else old_cmd.start.y
	
	match cmd_absolute_char:
		"C":
			new_cmd.x1 = lerpf(0.0 if is_relative else old_cmd.start.x, new_cmd.x, 1/3.0)
			new_cmd.y1 = lerpf(0.0 if is_relative else old_cmd.start.y, new_cmd.y, 1/3.0)
			new_cmd.x2 = lerpf(0.0 if is_relative else old_cmd.start.x, new_cmd.x, 2/3.0)
			new_cmd.y2 = lerpf(0.0 if is_relative else old_cmd.start.y, new_cmd.y, 2/3.0)
		"S":
			new_cmd.x2 = lerpf(0.0 if is_relative else old_cmd.start.x, new_cmd.x, 2/3.0)
			new_cmd.y2 = lerpf(0.0 if is_relative else old_cmd.start.y, new_cmd.y, 2/3.0)
		"Q":
			new_cmd.x1 = lerpf(0.0 if is_relative else old_cmd.start.x, new_cmd.x, 0.5)
			new_cmd.y1 = lerpf(0.0 if is_relative else old_cmd.start.y, new_cmd.y, 0.5)
	
	if is_relative:
		_commands[idx].toggle_relative()
	sync_after_commands_change()


func delete_commands(indices: Array[int]) -> void:
	if indices.is_empty():
		return
	
	indices = indices.duplicate()
	indices.sort()
	indices.reverse()
	for idx in indices:
		_commands.remove_at(idx)
	sync_after_commands_change()

func toggle_relative_command(idx: int) -> void:
	_commands[idx].toggle_relative()
	sync_after_commands_change()
