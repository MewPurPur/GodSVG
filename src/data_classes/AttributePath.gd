## The "d" attribute of [TagPath].
class_name AttributePath extends Attribute

signal command_changed(sync_mode: SyncMode)

var _commands: Array[PathCommand]

func _init() -> void:
	default = ""
	set_value(default, SyncMode.SILENT)
	command_changed.connect(sync_value)

func sync_value(sync_mode := SyncMode.LOUD) -> void:
	set_value(PathDataParser.path_commands_to_value(_commands), sync_mode)

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
		locate_start_points()
		command_changed.emit(sync_mode)

func insert_command(idx: int, command_char: String) -> void:
	_commands.insert(idx, PathCommand.translation_dict[command_char.to_upper()].new())
	if Utils.is_string_lower(command_char):
		_commands[idx].toggle_relative()
	locate_start_points()
	command_changed.emit(SyncMode.LOUD)

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
	locate_start_points()
	command_changed.emit(SyncMode.LOUD)

func delete_commands(indices: Array[int]) -> void:
	if indices.is_empty():
		return
	
	indices = indices.duplicate()
	indices.sort()
	indices.reverse()
	for idx in indices:
		_commands.remove_at(idx)
	locate_start_points()
	command_changed.emit(SyncMode.LOUD)

func toggle_relative_command(idx: int) -> void:
	_commands[idx].toggle_relative()
	command_changed.emit(SyncMode.LOUD)

func _sync() -> void:
	_commands = PathDataParser.parse_path_data(get_value())
	locate_start_points()
