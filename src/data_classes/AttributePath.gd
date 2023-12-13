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
	var old_command: PathCommand = _commands[idx]
	if old_command.command_char == command_char:
		return
	
	var new_command: PathCommand =\
			PathCommand.translation_dict[command_char.to_upper()].new()
	_commands.remove_at(idx)
	_commands.insert(idx, new_command)
	for property in [&"x", &"y", &"x1", &"y1", &"x2", &"y2"]:
		if property in old_command and property in new_command:
			new_command[property] = old_command[property]
	
	var is_relative := Utils.is_string_lower(command_char)
	
	if &"x" in new_command and not &"x" in old_command:
		new_command.x = 0.0 if is_relative else old_command.start.x
	if &"y" in new_command and not &"y" in old_command:
		new_command.y = 0.0 if is_relative else old_command.start.y
	
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
