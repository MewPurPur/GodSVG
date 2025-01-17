# The "d" attribute of ElementPath.
class_name AttributePathdata extends Attribute

var _commands: Array[PathCommand]

func _sync() -> void:
	_commands = parse_pathdata(get_value())
	locate_start_points()

func format(text: String) -> String:
	return path_commands_to_text(parse_pathdata(text))


func get_commands() -> Array[PathCommand]:
	return _commands

func set_commands(new_commands: Array[PathCommand]) -> void:
	_commands = new_commands
	sync_after_commands_change()

func sync_after_commands_change() -> void:
	set_value(path_commands_to_text(_commands))


func locate_start_points() -> void:
	# Start points are absolute. Individual floats, since 64-bit precision is needed here.
	var last_end_point_x := 0.0
	var last_end_point_y := 0.0
	var curr_subpath_start_x := 0.0
	var curr_subpath_start_y := 0.0
	for command: PathCommand in _commands:
		command.start_x = last_end_point_x
		command.start_y = last_end_point_y
		
		if command is PathCommand.MoveCommand:
			curr_subpath_start_x = command.start_x + command.x if\
					command.relative else command.x
			curr_subpath_start_y = command.start_y + command.y if\
					command.relative else command.y
		elif command is PathCommand.CloseCommand:
			last_end_point_x = curr_subpath_start_x
			last_end_point_y = curr_subpath_start_y
			continue
		
		# Prepare for the next iteration.
		if command.relative:
			if "x" in command:
				last_end_point_x += command.x
			if "y" in command:
				last_end_point_y += command.y
		else:
			if "x" in command:
				last_end_point_x = command.x
			if "y" in command:
				last_end_point_y = command.y


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
	var v := Vector2.ZERO if cmd.relative else cmd.get_start_coords()
	if prev_cmd.command_char in "CcSs":
		var prev_control_pt := Vector2(prev_cmd.x2, prev_cmd.y2)
		v = (cmd.get_start_coords() if\
				cmd.relative else cmd.get_start_coords() * 2) - prev_control_pt
		if prev_cmd.relative:
			v -= prev_cmd.get_start_coords()
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
	
	var prevQ_x: float = prevQ_cmd.x if "x" in prevQ_cmd else prevQ_cmd.start_x
	var prevQ_y: float = prevQ_cmd.y if "y" in prevQ_cmd else prevQ_cmd.start_y
	var prevQ_v := Vector2(prevQ_x, prevQ_y)
	var prevQ_v1 := Vector2(prevQ_cmd.x1, prevQ_cmd.y1) if\
			prevQ_cmd.command_char in "Qq" else prevQ_v
	var prevQ_end := prevQ_cmd.get_start_coords() + prevQ_v if\
			prevQ_cmd.relative else prevQ_v
	var prevQ_control_pt := prevQ_cmd.get_start_coords() + prevQ_v1 if\
			prevQ_cmd.relative else prevQ_v1
	
	var v := prevQ_end * 2 - prevQ_control_pt
	for T_idx in range(prevQ_idx + 1, idx):
		var T_cmd := get_command(T_idx)
		var T_v := Vector2(T_cmd.x, T_cmd.y)
		var T_end := T_cmd.get_start_coords() + T_v if T_cmd.relative else T_v
		v = T_end * 2 - v
	
	var cmd := get_command(idx)
	if cmd.relative:
		v -= cmd.get_start_coords()
	return v


func set_command_property(idx: int, property: String, new_value: float) -> void:
	var cmd := get_command(idx)
	if cmd.get(property) != new_value:
		cmd.set(property, new_value)
		sync_after_commands_change()

func insert_command(idx: int, cmd_char: String, vec := Vector2.ZERO) -> void:
	var new_cmd: PathCommand = PathCommand.translation_dict[cmd_char.to_upper()].new()
	var relative := Utils.is_string_lower(cmd_char)
	if relative:
		new_cmd.toggle_relative()
	_commands.insert(idx, new_cmd)
	locate_start_points()
	if not cmd_char in "Zz":
		if not cmd_char in "Vv":
			new_cmd.x = vec.x
		if not cmd_char in "Hh":
			new_cmd.y = vec.y
		if cmd_char in "Qq":
			new_cmd.x1 = lerpf(0.0 if relative else new_cmd.start_x, vec.x, 0.5)
			new_cmd.y1 = lerpf(0.0 if relative else new_cmd.start_y, vec.y, 0.5)
		elif cmd_char in "Ss":
			new_cmd.x2 = lerpf(0.0 if relative else new_cmd.start_x, vec.x, 2/3.0)
			new_cmd.y2 = lerpf(0.0 if relative else new_cmd.start_y, vec.y, 2/3.0)
		elif cmd_char in "Cc":
			new_cmd.x1 = lerpf(0.0 if relative else new_cmd.start_x, vec.x, 1/3.0)
			new_cmd.y1 = lerpf(0.0 if relative else new_cmd.start_y, vec.y, 1/3.0)
			new_cmd.x2 = lerpf(0.0 if relative else new_cmd.start_x, vec.x, 2/3.0)
			new_cmd.y2 = lerpf(0.0 if relative else new_cmd.start_y, vec.y, 2/3.0)
	sync_after_commands_change()


func _convert_command(idx: int, cmd_char: String) -> bool:
	var old_cmd := get_command(idx)
	if old_cmd.command_char == cmd_char:
		return false
	
	var cmd_absolute_char := cmd_char.to_upper()
	var new_cmd: PathCommand = PathCommand.translation_dict[cmd_absolute_char].new()
	for property in ["x", "y", "x1", "y1", "x2", "y2"]:
		if property in old_cmd and property in new_cmd:
			new_cmd[property] = old_cmd[property]
	
	var relative := Utils.is_string_lower(cmd_char)
	
	if "x" in new_cmd and not "x" in old_cmd:
		new_cmd.x = 0.0 if relative else old_cmd.start_x
	if "y" in new_cmd and not "y" in old_cmd:
		new_cmd.y = 0.0 if relative else old_cmd.start_y
	
	match cmd_absolute_char:
		"C":
			if old_cmd.command_char in "Ss":
				var v := get_implied_S_control(idx)
				new_cmd.x1 = v.x
				new_cmd.y1 = v.y
			else:
				new_cmd.x1 = lerpf(0.0 if relative else old_cmd.start_x, new_cmd.x, 1/3.0)
				new_cmd.y1 = lerpf(0.0 if relative else old_cmd.start_y, new_cmd.y, 1/3.0)
				new_cmd.x2 = lerpf(0.0 if relative else old_cmd.start_x, new_cmd.x, 2/3.0)
				new_cmd.y2 = lerpf(0.0 if relative else old_cmd.start_y, new_cmd.y, 2/3.0)
		"S":
			if not old_cmd.command_char in "Cc":
				new_cmd.x2 = lerpf(0.0 if relative else old_cmd.start_x, new_cmd.x, 2/3.0)
				new_cmd.y2 = lerpf(0.0 if relative else old_cmd.start_y, new_cmd.y, 2/3.0)
		"Q":
			if old_cmd.command_char in "Tt":
				var v := get_implied_T_control(idx)
				new_cmd.x1 = v.x
				new_cmd.y1 = v.y
			else:
				new_cmd.x1 = lerpf(0.0 if relative else old_cmd.start_x, new_cmd.x, 0.5)
				new_cmd.y1 = lerpf(0.0 if relative else old_cmd.start_y, new_cmd.y, 0.5)
	
	_commands.remove_at(idx)
	_commands.insert(idx, new_cmd)
	if relative:
		_commands[idx].toggle_relative()
	return true

func convert_command(idx: int, cmd_char: String) -> void:
	var conversion_made := _convert_command(idx, cmd_char)
	if conversion_made:
		sync_after_commands_change()

func convert_commands_optimized(indices: PackedInt32Array,
cmd_chars: PackedStringArray) -> void:
	var conversions_made := false
	for i in indices.size():
		var conversion_made := _convert_command(indices[i], cmd_chars[i])
		if conversion_made:
			conversions_made = true
	if conversions_made:
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


static func parse_pathdata(text: String) -> Array[PathCommand]:
	return path_commands_from_parsed_data(pathdata_to_arrays(text))

# godot_only/tests.gd has a test for this.
static func pathdata_to_arrays(text: String) -> Array[Array]:
	var new_commands: Array[Array] = []
	var curr_command := ""
	var prev_command := ""
	var nums: Array[float] = []
	var args_left := 0
	var comma_exhausted := false  # Can ignore many whitespaces, but only one comma.
	
	var idx := -1
	while idx < text.length() - 1:
		idx += 1
		@warning_ignore("shadowed_global_identifier")
		var char := text[idx]
		# Stop parsing if we've hit a character that's not allowed.
		if not char in "MmLlHhVvAaQqTtCcSsZz0123456789-+e., \n\t\r":
			return new_commands
		# Logic for finding out what the next command is going to be.
		if args_left == 0:
			match char:
				"M", "m", "L", "l", "H", "h", "V", "v", "A", "a", "Q", "q", "T", "t",\
				"C", "c", "S", "s", "Z", "z":
					curr_command = char
					args_left = PathCommand.arg_count_dict[curr_command.to_upper()]
				" ", "\t", "\n", "\r": continue
				"-", "+", ".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
					if prev_command.is_empty():
						continue
					
					match prev_command:
						"Z", "z":
							return new_commands
						"M", "m":
							curr_command = "L" if prev_command == "M" else "l"
							args_left = PathCommand.arg_count_dict[curr_command.to_upper()]
						"L", "l", "H", "h", "V", "v", "A", "a", "Q", "q", "T", "t", "C", "c",\
						"S", "s":
							curr_command = prev_command
							args_left = PathCommand.arg_count_dict[curr_command.to_upper()]
					idx -= 1
				_: return new_commands
		# Logic for parsing new numbers until args_left == 0.
		else:
			if comma_exhausted and not char in " \n\t\r":
				comma_exhausted = false
			# Arc flags are represented by a single character.
			if curr_command in "Aa" and (args_left == 4 or args_left == 3):
				match char:
					"0": nums.append(0)
					"1": nums.append(1)
					" ", "\n", "\t", "\r": continue
					",":
						if comma_exhausted:
							return new_commands
						else:
							comma_exhausted = true
							continue
					_: return new_commands
				if args_left == 3 and nums.size() == 5:
					# The number parsing part doesn't account for whitespace at the start,
					# so jump over the whitespace here.
					while idx < text.length() - 1:
						idx += 1
						match text[idx]:
							" ", "\n", "\t", "\r": continue
							",":
								if comma_exhausted:
									return new_commands
								else:
									comma_exhausted = true
									continue
							_:
								idx -= 1
								break
			else:
				# Parse the number.
				var start_idx := idx
				var end_idx := idx
				var number_proceed := true
				var passed_decimal_point := false
				var exponent_just_passed := true
				while number_proceed and idx < text.length():
					char = text[idx]
					match char:
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
							idx += 1
							end_idx += 1
							if exponent_just_passed:
								exponent_just_passed = false
						"-", "+":
							if end_idx == start_idx or exponent_just_passed:
								end_idx += 1
								idx += 1
								if exponent_just_passed:
									exponent_just_passed = false
							else:
								number_proceed = false
								idx -= 1
						".":
							if not passed_decimal_point:
								passed_decimal_point = true
								end_idx += 1
								idx += 1
							else:
								idx -= 1
								number_proceed = false
						" ", "\n", "\t", "\r":
							if end_idx == start_idx:
								idx += 1
								start_idx += 1
								end_idx += 1
								continue
							if not text.substr(start_idx, idx - start_idx).is_valid_float():
								return new_commands
							number_proceed = false
						",":
							if comma_exhausted:
								return new_commands
							else:
								comma_exhausted = true
								number_proceed = false
						"e", "E":
							if passed_decimal_point:
								return new_commands
							else:
								end_idx += 1
								idx += 1
								exponent_just_passed = true
						_:
							if args_left >= 1 and\
							not text.substr(start_idx, end_idx - start_idx).is_valid_float():
								return new_commands
							else:
								idx -= 1
								break
				nums.append(text.substr(start_idx, end_idx - start_idx).to_float())
			args_left -= 1
		
		# Wrap up the array.
		if args_left == 0:
			prev_command = curr_command
			var finalized_arr: Array = [curr_command]
			curr_command = ""
			finalized_arr.append_array(nums)
			nums.clear()
			new_commands.append(finalized_arr)
	return new_commands

static func path_commands_from_parsed_data(data: Array[Array]) -> Array[PathCommand]:
	var cmds: Array[PathCommand] = []
	for a in data:
		var new_cmd: PathCommand
		# The idx 0 element is the command char, the rest are the arguments.
		var cmd_type: Script = PathCommand.translation_dict[a[0].to_upper()]
		var relative := Utils.is_string_lower(a[0])
		match a.size():
			1: new_cmd = cmd_type.new(relative)
			2: new_cmd = cmd_type.new(a[1], relative)
			3: new_cmd = cmd_type.new(a[1], a[2], relative)
			5: new_cmd = cmd_type.new(a[1], a[2], a[3], a[4], relative)
			7: new_cmd = cmd_type.new(a[1], a[2], a[3], a[4], a[5], a[6], relative)
			8: new_cmd = cmd_type.new(a[1], a[2], a[3], a[4], a[5], a[6], a[7], relative)
		cmds.append(new_cmd)
	return cmds


func path_commands_to_text(commands_arr: Array[PathCommand]) -> String:
	var output := ""
	var num_parser := NumstringParser.new()
	num_parser.compress_numbers = formatter.pathdata_compress_numbers
	num_parser.minimize_spacing = formatter.pathdata_minimize_spacing
	
	var last_command := ""
	for i in commands_arr.size():
		var cmd := commands_arr[i]
		var cmd_char_capitalized := cmd.command_char.to_upper()
		if not (formatter.pathdata_remove_consecutive_commands and\
		((cmd_char_capitalized != "M" and last_command == cmd.command_char) or\
		(last_command == "m" and cmd.command_char == "l") or\
		(last_command == "M" and cmd.command_char == "L"))):
			output += cmd.command_char
			if not formatter.pathdata_minimize_spacing:
				output += " "
		elif i > 0 and formatter.pathdata_minimize_spacing:
			var current_char := ""
			var prev_numstr := ""
			match cmd_char_capitalized:
				"A":
					current_char = num_parser.num_to_text(cmd.rx)[0]
					prev_numstr = num_parser.num_to_text(commands_arr[i - 1].y)
				"C", "Q":
					current_char = num_parser.num_to_text(cmd.x1)[0]
					prev_numstr = num_parser.num_to_text(commands_arr[i - 1].y)
				"S":
					current_char = num_parser.num_to_text(cmd.x2)[0]
					prev_numstr = num_parser.num_to_text(commands_arr[i - 1].y)
				"L", "M", "T":
					current_char = num_parser.num_to_text(cmd.x)[0]
					prev_numstr = num_parser.num_to_text(commands_arr[i - 1].y)
				"H":
					current_char = num_parser.num_to_text(cmd.x)[0]
					prev_numstr = num_parser.num_to_text(commands_arr[i - 1].x)
				"V":
					current_char = num_parser.num_to_text(cmd.y)[0]
					prev_numstr = num_parser.num_to_text(+commands_arr[i - 1].y)
			if not formatter.pathdata_minimize_spacing or not\
			(("." in prev_numstr and current_char == ".") or current_char in "-+"):
				output += " "
		
		last_command = cmd.command_char
		match cmd_char_capitalized:
			"A":
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.rx),
						num_parser.num_to_text(cmd.ry), num_parser.num_to_text(cmd.rot, true)])
				if formatter.pathdata_remove_spacing_after_flags:
					output += (" 0" if cmd.large_arc_flag == 0 else " 1") +\
							("0" if cmd.sweep_flag == 0 else "1")
				else:
					output += " 0 " if cmd.large_arc_flag == 0 else " 1 "
					if num_parser.num_to_text(cmd.x)[0] == "-":
						output += "0" if cmd.sweep_flag == 0 else "1"
					else:
						output += "0 " if cmd.sweep_flag == 0 else "1 "
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.x),
						num_parser.num_to_text(cmd.y)])
			"C":
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.x1),
						num_parser.num_to_text(cmd.y1), num_parser.num_to_text(cmd.x2),
						num_parser.num_to_text(cmd.y2), num_parser.num_to_text(cmd.x),
						num_parser.num_to_text(cmd.y)])
			"Q":
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.x1),
						num_parser.num_to_text(cmd.y1), num_parser.num_to_text(cmd.x),
						num_parser.num_to_text(cmd.y)])
			"S":
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.x2),
						num_parser.num_to_text(cmd.y2), num_parser.num_to_text(cmd.x),
						num_parser.num_to_text(cmd.y)])
			"L", "M", "T":
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.x),
						num_parser.num_to_text(cmd.y)])
			"H":
				output += num_parser.num_to_text(cmd.x)
			"V":
				output += num_parser.num_to_text(cmd.y)
			_: continue
		if not formatter.pathdata_minimize_spacing:
			output += " "
	
	output = output.rstrip(" ")
	return output
