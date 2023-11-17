## The "d" attribute of [TagPath].
class_name AttributePath extends Attribute

signal command_changed

var commands: Array[PathCommand]

func _init() -> void:
	type = Type.PATHDATA
	default = ""
	set_value(default, UpdateType.SILENT)


func locate_start_points() -> void:
	# Start points are absolute.
	var last_end_point := Vector2.ZERO
	var current_subpath_start := Vector2.ZERO
	for command in commands:
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
	return commands.size()

func get_command(idx: int) -> PathCommand:
	return commands[idx]


func set_command_property(idx: int, property: StringName, new_value: float,
emit_command_changed := true) -> void:
	if commands[idx].get(property) != new_value:
		commands[idx].set(property, new_value)
		locate_start_points()
		if emit_command_changed:
			command_changed.emit()

func add_command(command_char: String) -> void:
	commands.append(PathCommand.translation_dict[command_char.to_upper()].new())
	if Utils.is_string_lower(command_char):
		commands.back().toggle_relative()
	locate_start_points()
	command_changed.emit()

func insert_command(idx: int, command_char: String) -> void:
	commands.insert(idx, PathCommand.translation_dict[command_char.to_upper()].new())
	if Utils.is_string_lower(command_char):
		commands[idx].toggle_relative()
	locate_start_points()
	command_changed.emit()

func delete_commands(indices: Array[int]) -> void:
	indices = indices.duplicate()
	indices.sort()
	indices.reverse()
	for idx in indices:
		commands.remove_at(idx)
	locate_start_points()
	command_changed.emit()

func toggle_relative_command(idx: int) -> void:
	commands[idx].toggle_relative()
	command_changed.emit()

func set_value(path_string: Variant, _emit_attribute_changed := UpdateType.LOUD) -> void:
	# Don't emit changed, as this rebuilds the data.
	commands = PathDataParser.parse_path_data(path_string)
	locate_start_points()
	super(path_string)
