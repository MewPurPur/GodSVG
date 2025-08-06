## The "d" attribute of ElementPath.
class_name AttributePathdata extends Attribute

var _commands: Array[PathCommand]
var subpath_start_indices: PackedInt32Array

func _sync() -> void:
	_commands = parse_pathdata(get_value())
	parse_properties()

func format(text: String, formatter: Formatter) -> String:
	return path_commands_to_text(parse_pathdata(text), formatter)


func get_commands() -> Array[PathCommand]:
	return _commands

func set_commands(new_commands: Array[PathCommand]) -> void:
	_commands = new_commands
	sync_after_commands_change()

func sync_after_commands_change() -> void:
	set_value(path_commands_to_text(_commands))


func parse_properties() -> void:
	# Start points are absolute. Individual floats, since 64-bit precision is needed here.
	var last_end_point_x := 0.0
	var last_end_point_y := 0.0
	var curr_subpath_start_x := 0.0
	var curr_subpath_start_y := 0.0
	for idx in _commands.size():
		var command := _commands[idx]
		command.start_x = last_end_point_x
		command.start_y = last_end_point_y
		
		if command is PathCommand.MoveCommand:
			subpath_start_indices.append(idx)
			curr_subpath_start_x = command.start_x + command.x if command.relative else command.x
			curr_subpath_start_y = command.start_y + command.y if command.relative else command.y
		elif idx > 0 and _commands[idx - 1] is PathCommand.CloseCommand:
			subpath_start_indices.append(idx)
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
	for i in range(subpath_start_indices.size() - 1, -1, -1):
		if subpath_start_indices[i] <= idx:
			output.x = subpath_start_indices[i]
			if i < subpath_start_indices.size() - 1:
				output.y = subpath_start_indices[i + 1] - 1
			else:
				output.y = get_command_count() - 1
			break
	return output


func get_implied_S_control(cmd_idx: int) -> Vector2:
	var cmd := get_command(cmd_idx)
	var prev_cmd := get_command(cmd_idx - 1)
	var v := Vector2.ZERO if cmd.relative else cmd.get_start_coords()
	if prev_cmd.command_char in "CcSs":
		var prev_control_pt := Vector2(prev_cmd.x2, prev_cmd.y2)
		v = (cmd.get_start_coords() if cmd.relative else cmd.get_start_coords() * 2) - prev_control_pt
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
	var prevQ_v1 := Vector2(prevQ_cmd.x1, prevQ_cmd.y1) if prevQ_cmd.command_char in "Qq" else prevQ_v
	var prevQ_end := prevQ_cmd.get_start_coords() + prevQ_v if prevQ_cmd.relative else prevQ_v
	var prevQ_control_pt := prevQ_cmd.get_start_coords() + prevQ_v1 if prevQ_cmd.relative else prevQ_v1
	
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
	parse_properties()
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
	
	const CONST_ARR: PackedStringArray = ["x", "y", "x1", "y1", "x2", "y2"]
	for property in CONST_ARR:
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
	text = text.strip_edges()
	var text_length := text.length()
	
	var commands: Array[PathCommand] = []
	var idx := 0
	var prev_command := ""
	while idx < text_length:
		while idx < text_length and text[idx] in " \t\n\r":
			idx += 1
		if idx >= text_length:
			break
		
		var current_char := text[idx]
		var current_command := ""
		if current_char in "MmLlHhVvAaQqTtCcSs":
			current_command = current_char
			idx += 1
		elif current_char in "Zz":
			idx += 1
			if prev_command in "Zz":
				continue
			current_command = current_char
		elif not prev_command.is_empty():
			match prev_command:
				"Z", "z": break
				"M": current_command = "L"
				"m": current_command = "l"
				_: current_command = prev_command
		else:
			break
		
		var key := current_command.to_upper()
		var arg_count := PathCommand.arg_count_dict[key]
		var nums := []
		
		if key == "A":
			var result := NumstringParser.text_to_number_arr(text, idx, 3)
			if result.is_empty():
				return commands
			var arr: PackedFloat64Array = result[0]
			idx = result[1]
			nums.append_array(arr)
			
			# Handle flags.
			for _i in 2:
				@warning_ignore("confusable_local_declaration")
				var comma_passed := false
				while idx < text_length:
					if text[idx] in " \t\n\r":
						idx += 1
					elif text[idx] == ",":
						if comma_passed:
							return commands
						comma_passed = true
						idx += 1
					else:
						break
				if idx >= text_length or not text[idx] in "01":
					return commands
				else:
					nums.append(text[idx].to_int())
					idx += 1
			
			result = NumstringParser.text_to_number_arr(text, idx, 2, true)
			if result.is_empty():
				return commands
			arr = result[0]
			idx = result[1]
			nums.append_array(arr)
		elif arg_count > 0:
			var result := NumstringParser.text_to_number_arr(text, idx, arg_count)
			if result.is_empty():
				return commands
			
			var arr: PackedFloat64Array = result[0]
			idx = result[1]
			nums.append_array(arr)
		
		var cmd_type := PathCommand.translation_dict[key]
		var relative := Utils.is_string_lower(current_command)
		var new_cmd: PathCommand
		match arg_count:
			0: new_cmd = cmd_type.new(relative)
			1: new_cmd = cmd_type.new(nums[0], relative)
			2: new_cmd = cmd_type.new(nums[0], nums[1], relative)
			4: new_cmd = cmd_type.new(nums[0], nums[1], nums[2], nums[3], relative)
			6: new_cmd = cmd_type.new(nums[0], nums[1], nums[2], nums[3], nums[4], nums[5], relative)
			7: new_cmd = cmd_type.new(nums[0], nums[1], nums[2], nums[3], nums[4], nums[5], nums[6], relative)
			8: new_cmd = cmd_type.new(nums[0], nums[1], nums[2], nums[3], nums[4], nums[5], nums[6], nums[7], relative)
			_: continue
		
		commands.append(new_cmd)
		prev_command = current_command
		
		var comma_passed := false
		while idx < text_length:
			var c := text[idx]
			if c in " \t\n\r":
				idx += 1
			elif c == ",":
				if comma_passed:
					return commands
				comma_passed = true
				idx += 1
			else:
				break
	return commands


func path_commands_to_text(commands_arr: Array[PathCommand],
formatter := Configs.savedata.editor_formatter) -> String:
	var output := ""
	var num_parser := NumstringParser.new()
	num_parser.compress_numbers = formatter.pathdata_compress_numbers
	num_parser.minimize_spacing = formatter.pathdata_minimize_spacing
	
	var last_command := ""
	for i in commands_arr.size():
		var cmd := commands_arr[i]
		var cmd_char_capitalized := cmd.command_char.to_upper()
		if not (formatter.pathdata_remove_consecutive_commands and ((cmd_char_capitalized != "M" and last_command == cmd.command_char) or\
		(last_command == "m" and cmd.command_char == "l") or (last_command == "M" and cmd.command_char == "L"))):
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
			if not formatter.pathdata_minimize_spacing or not (("." in prev_numstr and current_char == ".") or current_char in "-+"):
				output += " "
		
		last_command = cmd.command_char
		match cmd_char_capitalized:
			"A":
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.rx), num_parser.num_to_text(cmd.ry), num_parser.num_to_text(cmd.rot, true)])
				if formatter.pathdata_remove_spacing_after_flags:
					output += (" 0" if cmd.large_arc_flag == 0 else " 1") + ("0" if cmd.sweep_flag == 0 else "1")
				else:
					output += " 0 " if cmd.large_arc_flag == 0 else " 1 "
					if num_parser.num_to_text(cmd.x)[0] == "-":
						output += "0" if cmd.sweep_flag == 0 else "1"
					else:
						output += "0 " if cmd.sweep_flag == 0 else "1 "
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.x), num_parser.num_to_text(cmd.y)])
			"C":
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.x1), num_parser.num_to_text(cmd.y1),
						num_parser.num_to_text(cmd.x2), num_parser.num_to_text(cmd.y2), num_parser.num_to_text(cmd.x), num_parser.num_to_text(cmd.y)])
			"Q":
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.x1), num_parser.num_to_text(cmd.y1),
						num_parser.num_to_text(cmd.x), num_parser.num_to_text(cmd.y)])
			"S":
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.x2), num_parser.num_to_text(cmd.y2),
						num_parser.num_to_text(cmd.x), num_parser.num_to_text(cmd.y)])
			"L", "M", "T":
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.x), num_parser.num_to_text(cmd.y)])
			"H":
				output += num_parser.num_to_text(cmd.x)
			"V":
				output += num_parser.num_to_text(cmd.y)
			_: continue
		if not formatter.pathdata_minimize_spacing:
			output += " "
	
	output = output.rstrip(" ")
	return output
