class_name PathdataParser extends RefCounted

const translation_dict = PathCommand.translation_dict

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
					args_left = translation_dict[curr_command.to_upper()].new().arg_count
				" ", "\t", "\n", "\r": continue
				"-", "+", ".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
					if prev_command.is_empty():
						continue
					
					match prev_command:
						"Z", "z":
							return new_commands
						"M", "m":
							curr_command = "L" if prev_command == "M" else "l"
							args_left = translation_dict[curr_command.to_upper()].new().arg_count
						"L", "l", "H", "h", "V", "v", "A", "a", "Q", "q", "T", "t", "C", "c",\
						"S", "s":
							curr_command = prev_command
							args_left = translation_dict[curr_command.to_upper()].new().arg_count
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
						"e":
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
		var cmd_type: Script = translation_dict[a[0].to_upper()]
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


static func path_commands_to_text(commands_arr: Array[PathCommand]) -> String:
	var output := ""
	var num_parser := NumberArrayParser.new()
	num_parser.compress_numbers = GlobalSettings.pathdata_compress_numbers
	num_parser.minimize_spacing = GlobalSettings.pathdata_minimize_spacing
	
	var last_command := ""
	for i in commands_arr.size():
		var cmd := commands_arr[i]
		var cmd_char_capitalized := cmd.command_char.to_upper()
		if not (GlobalSettings.pathdata_remove_consecutive_commands and\
		((cmd_char_capitalized != "M" and last_command == cmd.command_char) or\
		(last_command == "m" and cmd.command_char == "l") or\
		(last_command == "M" and cmd.command_char == "L"))):
			output += cmd.command_char
			if not GlobalSettings.pathdata_minimize_spacing:
				output += " "
		elif i > 0 and GlobalSettings.pathdata_minimize_spacing:
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
			if not GlobalSettings.pathdata_minimize_spacing or not\
			(("." in prev_numstr and current_char == ".") or current_char in "-+"):
				output += " "
		
		last_command = cmd.command_char
		match cmd_char_capitalized:
			"A":
				output += num_parser.numstr_arr_to_text([num_parser.num_to_text(cmd.rx),
						num_parser.num_to_text(cmd.ry), num_parser.num_to_text(cmd.rot, true)])
				if GlobalSettings.pathdata_remove_spacing_after_flags:
					output += (" 0" if cmd.large_arc_flag == 0 else " 1") +\
							("0" if cmd.sweep_flag == 0 else "1")
				else:
					output += (" 0 " if cmd.large_arc_flag == 0 else " 1 ") +\
							("0 " if cmd.sweep_flag == 0 else "1 ")
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
		if not GlobalSettings.pathdata_minimize_spacing:
			output += " "
	
	output = output.rstrip(" ")
	return output
