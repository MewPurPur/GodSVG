class_name PathDataParser extends RefCounted

const translation_dict = PathCommandArray.translation_dict


static func parse_path_data(path_string: String) -> Array[PathCommandArray.PathCommand]:
	return path_commands_from_parsed_data(path_data_to_arrays(path_string))

static func path_data_to_arrays(path_string: String) -> Array[Array]:
	var new_commands: Array[Array] = []
	var curr_command := ""
	var prev_command := ""
	var curr_command_args: Array = []
	var args_left := 0
	var comma_exhausted := false
	
	var idx := -1
	while idx < path_string.length() - 1:
		idx += 1
		@warning_ignore("shadowed_global_identifier")
		var char := path_string[idx]
		# Stop parsing if we've hit a character that's not allowed.
		if not char in ["M", "m", "L", "l", "H", "h", "V", "v", "A", "a", "Q", "q", "T",
		"t", "C", "c", "S", "s", "Z", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
		"-", "+", ".", " ", ","]:
			return new_commands
		# Logic for finding out what the next command is going to be.
		if args_left == 0:
			match char:
				"M", "m", "L", "l", "H", "h", "V", "v", "A", "a", "Q", "q", "T", "t",\
				"C", "c", "S", "s", "Z", "z":
					curr_command = char
					args_left = translation_dict[curr_command.to_upper()].new().arg_count
				" ": continue
				"-", "+", ".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
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
			if comma_exhausted and char != " ":
				comma_exhausted = false
			# Arc flags are represented by a single character.
			if curr_command in ["a", "A"] and args_left in [4, 3]:
				match char:
					" ": continue
					"0": curr_command_args.append(0)
					"1": curr_command_args.append(1)
					",":
						if comma_exhausted:
							return new_commands
						else:
							comma_exhausted = true
							continue
					_: return new_commands
			else:
				# Parse the number.
				var num_string := ""
				var number_proceed := true
				var passed_decimal_point := false
				while number_proceed and idx < path_string.length():
					char = path_string[idx]
					match char:
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
							idx += 1
							num_string += char
						"-", "+":
							if num_string.is_empty():
								num_string += char
								idx += 1
							else:
								number_proceed = false
								idx -= 1
						".":
							if not passed_decimal_point:
								passed_decimal_point = true
								num_string += char
								idx += 1
							else:
								idx -= 1
								number_proceed = false
						" ":
							if num_string.is_empty():
								idx += 1
								continue
							number_proceed = false
						",":
							if comma_exhausted:
								return new_commands
							else:
								comma_exhausted = true
								number_proceed = false
						_:
							idx -= 1
							break
				curr_command_args.append(num_string.to_float())
			args_left -= 1
		
		# Wrap up the array.
		if args_left == 0:
			prev_command = curr_command
			var finalized_arr: Array = [curr_command]
			curr_command = ""
			finalized_arr.append_array(curr_command_args)
			curr_command_args.clear()
			new_commands.append(finalized_arr)
	return new_commands

static func path_commands_from_parsed_data(data: Array[Array]) -> Array[PathCommandArray.PathCommand]:
	var cmds: Array[PathCommandArray.PathCommand] = []
	for arr in data:
		var new_cmd: PathCommandArray.PathCommand
		var cmd_type = translation_dict[arr[0].to_upper()]
		match arr.size():
			1: new_cmd = cmd_type.new()
			2: new_cmd = cmd_type.new(arr[1])
			3: new_cmd = cmd_type.new(arr[1], arr[2])
			5: new_cmd = cmd_type.new(arr[1], arr[2], arr[3], arr[4])
			7: new_cmd = cmd_type.new(arr[1], arr[2], arr[3], arr[4], arr[5], arr[6])
			8: new_cmd = cmd_type.new(arr[1], arr[2], arr[3], arr[4], arr[5], arr[6], arr[7])
		if Utils.is_string_lower(arr[0]):
			new_cmd.relative = true
			new_cmd.command_char = arr[0]
		cmds.append(new_cmd)
	return cmds


static func path_commands_to_value(commands_arr: PathCommandArray) -> String:
	var generated_value := ""
	for command in commands_arr.data:
		var cmd_char := command.command_char.to_upper()
		generated_value += command.command_char + " "
		if cmd_char == "A":
			generated_value += String.num(command.rx, 4) + " " +\
					String.num(command.ry, 4) + " " + String.num(command.rot, 2) + " " +\
					str(command.large_arc_flag) + " " + str(command.sweep_flag) + " "
		if cmd_char == "Q" or cmd_char == "C":
			generated_value += String.num(command.x1, 4) + " " +\
					String.num(command.y1, 4) + " "
		if cmd_char == "C" or cmd_char == "S":
			generated_value += String.num(command.x2, 4) + " " +\
					String.num(command.y2, 4) + " "
		if cmd_char != "Z" and cmd_char != "V":
			generated_value += String.num(command.x, 4) + " "
		if cmd_char != "Z" and cmd_char != "H":
			generated_value += String.num(command.y, 4) + " "
	return generated_value.rstrip(" ")


# DEBUG

#func _init() -> void:
	#var tests := {
	#"Jerky": [],
	#"M 0 0": [["M", 0.0, 0.0]],
	#"M2 1 L3 4": [["M", 2.0, 1.0], ["L", 3.0, 4.0]],
	#"m2 0 3 4": [["m", 2.0, 0.0], ["l", 3.0, 4.0]],
	#"m-2.3.7-4,4": [["m", -2.3, 0.7], ["l", -4.0, 4.0]],
	#"m2 3a7 3 0 101.2.3": [["m", 2.0, 3.0], ["a", 7.0, 3.0, 0.0, 1, 0, 1.2, 0.3]],
	#"M 2 0  c3 2-.6.8 11.0 3Jh3": [["M", 2.0, 0.0], ["c", 3.0, 2.0, -0.6, 0.8, 11.0, 3.0]],
	#"z": [["z"]],
	#"M 0 0 z 2 3": [["M", 0.0, 0.0], ["z"]],
	#}
#
	#var tests_passed := true
	#for test in tests.keys():
		#var result := path_data_to_arrays(test)
		#var expected: Array = tests[test]
		#if result != expected:
			#tests_passed = false
			#print('"' + test + '" generated ' + str(result) + ', expected ' + str(expected))
		#else:
			#print('"' + test + '" generated ' + str(result) + ' (SUCCESS)')
	#assert(tests_passed)
