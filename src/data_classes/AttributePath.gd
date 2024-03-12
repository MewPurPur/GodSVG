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
	return PathDataParser.path_commands_to_text(PathDataParser.parse_path_data(text))


func set_commands(new_commands: Array[PathCommand], sync_mode := SyncMode.LOUD) -> void:
	_commands = new_commands
	sync_after_commands_change(sync_mode)

func sync_after_commands_change(sync_mode := SyncMode.LOUD) -> void:
	set_value(PathDataParser.path_commands_to_text(_commands), sync_mode)


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
			if "x" in command:
				last_end_point.x += command.x
			if "y" in command:
				last_end_point.y += command.y
		else:
			if "x" in command:
				last_end_point.x = command.x
			if "y" in command:
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

func get_implied_S_control(cmd_idx: int) -> Vector2:
	var cmd := get_command(cmd_idx)
	var prev_cmd := get_command(cmd_idx - 1)
	var v := Vector2.ZERO if cmd.relative else cmd.start
	if prev_cmd.command_char in "CcSs":
		var prev_control_pt := Vector2(prev_cmd.x2, prev_cmd.y2)
		v = (cmd.start if cmd.relative else cmd.start * 2) - prev_control_pt
		if prev_cmd.relative:
			v -= prev_cmd.start
	return v

func get_implied_T_control(idx: int) -> Vector2:
	var prevQ_idx := idx - 1
	var prevQ_cmd := get_command(prevQ_idx)
	while prevQ_idx >= 0:
		if not prevQ_cmd.command_char in "Tt":
			break
		else:
			prevQ_idx -= 1
			prevQ_cmd = get_command(prevQ_idx)
	if prevQ_idx == -1:
		return Vector2(NAN, NAN)
	
	var prevQ_x: float = prevQ_cmd.x if "x" in prevQ_cmd else prevQ_cmd.start.x
	var prevQ_y: float = prevQ_cmd.y if "y" in prevQ_cmd else prevQ_cmd.start.y
	var prevQ_v := Vector2(prevQ_x, prevQ_y)
	var prevQ_v1 := Vector2(prevQ_cmd.x1, prevQ_cmd.y1) if\
			prevQ_cmd.command_char in "Qq" else prevQ_v
	var prevQ_end := prevQ_cmd.start + prevQ_v if prevQ_cmd.relative else prevQ_v
	var prevQ_control_pt := prevQ_cmd.start + prevQ_v1 if prevQ_cmd.relative else prevQ_v1
	
	var v := prevQ_end * 2 - prevQ_control_pt
	for T_idx in range(prevQ_idx + 1, idx):
		var T_cmd := get_command(T_idx)
		var T_v := Vector2(T_cmd.x, T_cmd.y)
		var T_end := T_cmd.start + T_v if T_cmd.relative else T_v
		v = T_end * 2 - v
	
	var cmd := get_command(idx)
	if cmd.relative:
		v -= cmd.start
	return v


func set_command_property(idx: int, property: String, new_value: float,
sync_mode := SyncMode.LOUD) -> void:
	var cmd := get_command(idx)
	if cmd.get(property) != new_value or sync_mode == SyncMode.FINAL:
		cmd.set(property, new_value)
		sync_after_commands_change(sync_mode)

func insert_command(idx: int, command_char: String, vec := Vector2.ZERO,
sync_mode := SyncMode.LOUD) -> void:
	var new_cmd: PathCommand = PathCommand.translation_dict[command_char.to_upper()].new()
	var relative := Utils.is_string_lower(command_char)
	if relative:
		new_cmd.toggle_relative()
	_commands.insert(idx, new_cmd)
	locate_start_points()
	if not command_char in "Zz":
		if not command_char in "Vv":
			new_cmd.x = vec.x
		if not command_char in "Hh":
			new_cmd.y = vec.y
		if command_char in "Qq":
			new_cmd.x1 = lerpf(0.0 if relative else new_cmd.start.x, vec.x, 0.5)
			new_cmd.y1 = lerpf(0.0 if relative else new_cmd.start.y, vec.y, 0.5)
		elif command_char in "Ss":
			new_cmd.x2 = lerpf(0.0 if relative else new_cmd.start.x, vec.x, 2/3.0)
			new_cmd.y2 = lerpf(0.0 if relative else new_cmd.start.y, vec.y, 2/3.0)
		elif command_char in "Cc":
			new_cmd.x1 = lerpf(0.0 if relative else new_cmd.start.x, vec.x, 1/3.0)
			new_cmd.y1 = lerpf(0.0 if relative else new_cmd.start.y, vec.y, 1/3.0)
			new_cmd.x2 = lerpf(0.0 if relative else new_cmd.start.x, vec.x, 2/3.0)
			new_cmd.y2 = lerpf(0.0 if relative else new_cmd.start.y, vec.y, 2/3.0)
	sync_after_commands_change(sync_mode)


func convert_command(idx: int, command_char: String, sync_mode := SyncMode.LOUD) -> void:
	var old_cmd := get_command(idx)
	if old_cmd.command_char == command_char:
		return
	
	var cmd_absolute_char := command_char.to_upper()
	var new_cmd: PathCommand = PathCommand.translation_dict[cmd_absolute_char].new()
	for property in ["x", "y", "x1", "y1", "x2", "y2"]:
		if property in old_cmd and property in new_cmd:
			new_cmd[property] = old_cmd[property]
	
	var relative := Utils.is_string_lower(command_char)
	
	if "x" in new_cmd and not "x" in old_cmd:
		new_cmd.x = 0.0 if relative else old_cmd.start.x
	if "y" in new_cmd and not "y" in old_cmd:
		new_cmd.y = 0.0 if relative else old_cmd.start.y
	
	match cmd_absolute_char:
		"C":
			if old_cmd.command_char in "Ss":
				var v := get_implied_S_control(idx)
				new_cmd.x1 = v.x
				new_cmd.y1 = v.y
			else:
				new_cmd.x1 = lerpf(0.0 if relative else old_cmd.start.x, new_cmd.x, 1/3.0)
				new_cmd.y1 = lerpf(0.0 if relative else old_cmd.start.y, new_cmd.y, 1/3.0)
				new_cmd.x2 = lerpf(0.0 if relative else old_cmd.start.x, new_cmd.x, 2/3.0)
				new_cmd.y2 = lerpf(0.0 if relative else old_cmd.start.y, new_cmd.y, 2/3.0)
		"S":
			if not old_cmd.command_char in "Cc":
				new_cmd.x2 = lerpf(0.0 if relative else old_cmd.start.x, new_cmd.x, 2/3.0)
				new_cmd.y2 = lerpf(0.0 if relative else old_cmd.start.y, new_cmd.y, 2/3.0)
		"Q":
			if old_cmd.command_char in "Tt":
				var v := get_implied_T_control(idx)
				new_cmd.x1 = v.x
				new_cmd.y1 = v.y
			else:
				new_cmd.x1 = lerpf(0.0 if relative else old_cmd.start.x, new_cmd.x, 0.5)
				new_cmd.y1 = lerpf(0.0 if relative else old_cmd.start.y, new_cmd.y, 0.5)
	
	_commands.remove_at(idx)
	_commands.insert(idx, new_cmd)
	if relative:
		_commands[idx].toggle_relative()
	sync_after_commands_change(sync_mode)


func delete_commands(indices: Array[int], sync_mode := SyncMode.LOUD) -> void:
	if indices.is_empty():
		return
	
	indices = indices.duplicate()
	indices.sort()
	indices.reverse()
	for idx in indices:
		_commands.remove_at(idx)
	sync_after_commands_change(sync_mode)

func toggle_relative_command(idx: int, sync_mode := SyncMode.LOUD) -> void:
	_commands[idx].toggle_relative()
	sync_after_commands_change(sync_mode)
