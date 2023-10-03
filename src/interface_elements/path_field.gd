extends AttributeEditor

const NumberField = preload("number_field.tscn")
const FlagField = preload("flag_field.tscn")

@onready var command_picker: Popup = $PathPopup
@onready var line_edit: LineEdit = $MainLine/LineEdit
@onready var commands_container: VBoxContainer = $Commands

var commands: Array[PathCommand]

var translation_dict := {
	"M": MoveCommand, "L": LineCommand, "H": HorizontalLineCommand,
	"V": VerticalLineCommand, "Z": CloseCommand, "A": EllipticalArcCommand,
	"Q": QuadraticBezierCommand, "T": ShorthandQuadraticBezierCommand,
	"C": CubicBezierCommand, "S": ShorthandCubicBezierCommand
}

signal value_changed(new_value: String)
var value := "":
	set(new_value):
		if value != new_value:
			value = new_value
			value_changed.emit(new_value)

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		value = attribute.value

func _on_button_pressed() -> void:
	command_picker.popup(Rect2(global_position + Vector2(0, line_edit.size.y),
			command_picker.size))

func _on_path_command_picked(new_command: String) -> void:
	commands.append(translation_dict[new_command.to_upper()].new())
	if Utils.is_string_lower(new_command):
		commands.back().toggle_relative()
	value = path_commands_to_value()
	full_rebuild()
	value_changed.emit(value)

func path_commands_to_value() -> String:
	var generated_value := ""
	for command in commands:
		generated_value += command.command_char + " "
		if command is EllipticalArcCommand:
			generated_value += String.num(command.rx, 4) + " " +\
					String.num(command.ry, 4) + " " + String.num(command.rot, 2) + " " +\
					str(command.large_arc_flag) + " " + str(command.sweep_flag) + " "
		if command is QuadraticBezierCommand or command is CubicBezierCommand:
			generated_value += String.num(command.x1, 4) + " " +\
					String.num(command.y1, 4) + " "
		if command is CubicBezierCommand or command is ShorthandCubicBezierCommand:
			generated_value += String.num(command.x2, 4) + " " +\
					String.num(command.y2, 4) + " "
		if not (command is CloseCommand or command is VerticalLineCommand):
			generated_value += String.num(command.x, 4) + " "
		if not (command is CloseCommand or command is HorizontalLineCommand):
			generated_value += String.num(command.y, 4) + " "
	locate_start_points()
	return generated_value.rstrip(" ")

func full_rebuild() -> void:
	commands = path_commands_from_parsed_data(parse_path_data(value))
	if commands.is_empty() and not value.is_empty():
		return  # This means the path definition is invalid, so we don't rebuild.
	
	# Clear the container of the tags.
	for node in commands_container.get_children():
		node.queue_free()
	# Rebuild it based on the commands array.
	for command_idx in commands.size():
		var command := commands[command_idx]
		var input_field := HBoxContainer.new()
		# Add button for switching between relative and absolute.
		var command_char_button := Button.new()
		command_char_button.text = command.command_char
		command_char_button.add_theme_font_override(&"font",
				load("res://visual/CodeFont.ttf"))
		command_char_button.add_theme_font_size_override(&"font_size", 9)
		command_char_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		command_char_button.pressed.connect(toggle_relative.bind(command_idx))
		input_field.add_child(command_char_button)
		# Instantiate the input fields.
		if command is EllipticalArcCommand:
			var field_rx: Control = NumberField.instantiate()
			var field_ry: Control = NumberField.instantiate()
			var field_rot: Control = NumberField.instantiate()
			var field_large_arc_flag: Control = FlagField.instantiate()
			var field_sweep_flag: Control = FlagField.instantiate()
			field_large_arc_flag.value = command.large_arc_flag
			field_sweep_flag.value = command.sweep_flag
			field_rx.is_float = true
			field_rx.min_value = 0.001
			field_rx.allow_higher = true
			field_ry.is_float = true
			field_ry.min_value = 0.001
			field_ry.allow_higher = true
			field_rot.is_float = true
			field_rot.min_value = -360
			field_rot.max_value = 360
			field_rx.value = command.rx
			field_ry.value = command.ry
			field_rot.value = command.rot
			input_field.add_child(field_rx)
			input_field.add_child(field_ry)
			input_field.add_child(field_rot)
			input_field.add_child(field_large_arc_flag)
			input_field.add_child(field_sweep_flag)
			field_rx.value_changed.connect(_update_command_value.bind(command_idx, &"rx"))
			field_ry.value_changed.connect(_update_command_value.bind(command_idx, &"ry"))
			field_rot.value_changed.connect(_update_command_value.bind(command_idx, &"rot"))
			field_large_arc_flag.value_changed.connect(
						_update_command_value.bind(command_idx, &"large_arc_flag"))
			field_sweep_flag.value_changed.connect(
						_update_command_value.bind(command_idx, &"sweep_flag"))
		if command is QuadraticBezierCommand or command is CubicBezierCommand:
			var field_x1: Control = NumberField.instantiate()
			var field_y1: Control = NumberField.instantiate()
			field_x1.is_float = true
			field_x1.min_value = -1024
			field_x1.remove_limits()
			field_y1.is_float = true
			field_y1.min_value = -1024
			field_y1.remove_limits()
			field_x1.value = command.x1
			field_y1.value = command.y1
			input_field.add_child(field_x1)
			input_field.add_child(field_y1)
			field_x1.value_changed.connect(_update_command_value.bind(command_idx, &"x1"))
			field_y1.value_changed.connect(_update_command_value.bind(command_idx, &"y1"))
		if command is CubicBezierCommand or command is ShorthandCubicBezierCommand:
			var field_x2: Control = NumberField.instantiate()
			var field_y2: Control = NumberField.instantiate()
			field_x2.is_float = true
			field_x2.min_value = -1024
			field_x2.remove_limits()
			field_y2.is_float = true
			field_y2.min_value = -1024
			field_y2.remove_limits()
			field_x2.value = command.x2
			field_y2.value = command.y2
			input_field.add_child(field_x2)
			input_field.add_child(field_y2)
			field_x2.value_changed.connect(_update_command_value.bind(command_idx, &"x2"))
			field_y2.value_changed.connect(_update_command_value.bind(command_idx, &"y2"))
		if not (command is CloseCommand or command is VerticalLineCommand):
			var field_x: Control = NumberField.instantiate()
			field_x.is_float = true
			field_x.min_value = -1024
			field_x.remove_limits()
			field_x.value = command.x
			input_field.add_child(field_x)
			field_x.value_changed.connect(_update_command_value.bind(command_idx, &"x"))
		if not (command is CloseCommand or command is HorizontalLineCommand):
			var field_y: Control = NumberField.instantiate()
			field_y.is_float = true
			field_y.min_value = -1024
			field_y.remove_limits()
			field_y.value = command.y
			input_field.add_child(field_y)
			field_y.value_changed.connect(_update_command_value.bind(command_idx, &"y"))
		commands_container.add_child(input_field)
		line_edit.text = value
		# Add close button
		var close_button := Button.new()
		close_button.icon = load("res://visual/icons/SmallCross.svg")
		close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
		close_button.pressed.connect(_on_close_button_pressed.bind(command_idx))
		input_field.add_child(close_button)


func _update_command_value(new_value: float, index: int, property: StringName) -> void:
	commands[index].set(property, new_value)
	value = path_commands_to_value()
	line_edit.text = value
	value_changed.emit(value)

func _on_value_changed(new_value: String) -> void:
	line_edit.text = new_value
	full_rebuild()
	if attribute != null:
		attribute.value = new_value

func _on_close_button_pressed(idx: int) -> void:
	commands.remove_at(idx)
	value = path_commands_to_value()
	full_rebuild()
	value_changed.emit(value)

func toggle_relative(idx: int) -> void:
	commands[idx].toggle_relative()
	value = path_commands_to_value()
	full_rebuild()
	value_changed.emit(value)


func locate_start_points() -> void:
	# Start points are absolute.
	var last_end_point := Vector2.ZERO
	var current_subpath_start := Vector2.ZERO
	for path_command in commands:
		path_command.start = last_end_point
		
		if path_command is MoveCommand:
			current_subpath_start = Vector2(path_command.x, path_command.y)
		elif path_command is CloseCommand:
			last_end_point = current_subpath_start
			continue
		
		# Prepare for the next iteration.
		if path_command.relative:
			if &"x" in path_command:
				last_end_point.x += path_command.x
			if &"y" in path_command:
				last_end_point.y += path_command.y
		else:
			if &"x" in path_command:
				last_end_point.x = path_command.x
			if &"y" in path_command:
				last_end_point.y = path_command.y

class PathCommand extends RefCounted:
	var command_char := ""
	var arg_count := 0
	var relative := false
	var start: Vector2
	func toggle_relative() -> void:
		if relative:
			relative = false
			command_char = command_char.to_upper()
			for property in [&"x", &"y", &"x1", &"y1", &"x2", &"y2"]:
				if property in self:
					set(property, start.x + get(property))
		else:
			relative = true
			command_char = command_char.to_lower()
			for property in [&"x", &"y", &"x1", &"y1", &"x2", &"y2"]:
				if property in self:
					set(property, get(property) - start.x)

class MoveCommand extends PathCommand:
	var x: float
	var y: float
	func _init(new_x := 0.0, new_y := 0.0) -> void:
		command_char = "M"
		arg_count = 2
		x = new_x
		y = new_y

class LineCommand extends PathCommand:
	var x: float
	var y: float
	func _init(new_x := 0.0, new_y := 0.0) -> void:
		command_char = "L"
		arg_count = 2
		x = new_x
		y = new_y

class HorizontalLineCommand extends PathCommand:
	var x: float
	func _init(new_x := 0.0) -> void:
		command_char = "H"
		arg_count = 1
		x = new_x

class VerticalLineCommand extends PathCommand:
	var y: float
	func _init(new_y := 0.0) -> void:
		command_char = "V"
		arg_count = 1
		y = new_y

class EllipticalArcCommand extends PathCommand:
	var rx: float
	var ry: float
	var rot: float
	var large_arc_flag: int
	var sweep_flag: int
	var x: float
	var y: float
	func _init(new_rx := 1.0, new_ry := 1.0, new_rot := 0.0, new_large_arc_flag := 0,
	new_sweep_flag := 0, new_x := 0.0, new_y := 0.0) -> void:
		command_char = "A"
		arg_count = 7
		rx = new_rx
		ry = new_ry
		rot = new_rot
		large_arc_flag = new_large_arc_flag
		sweep_flag = new_sweep_flag
		x = new_x
		y = new_y

class QuadraticBezierCommand extends PathCommand:
	var x1: float
	var y1: float
	var x: float
	var y: float
	func _init(new_x1 := 0.0, new_y1 := 0.0, new_x := 0.0, new_y := 0.0) -> void:
		command_char = "Q"
		arg_count = 4
		x1 = new_x1
		y1 = new_y1
		x = new_x
		y = new_y

class ShorthandQuadraticBezierCommand extends PathCommand:
	var x: float
	var y: float
	func _init(new_x := 0.0, new_y := 0.0) -> void:
		command_char = "T"
		arg_count = 2
		x = new_x
		y = new_y

class CubicBezierCommand extends PathCommand:
	var x1: float
	var y1: float
	var x2: float
	var y2: float
	var x: float
	var y: float
	func _init(new_x1 := 0.0, new_y1 := 0.0, new_x2 := 0.0, new_y2 := 0.0,
	new_x := 0.0, new_y := 0.0) -> void:
		command_char = "C"
		arg_count = 6
		x1 = new_x1
		y1 = new_y1
		x2 = new_x2
		y2 = new_y2
		x = new_x
		y = new_y

class ShorthandCubicBezierCommand extends PathCommand:
	var x2: float
	var y2: float
	var x: float
	var y: float
	func _init(new_x2 := 0.0, new_y2 := 0.0, new_x := 0.0, new_y := 0.0) -> void:
		command_char = "S"
		arg_count = 4
		x2 = new_x2
		y2 = new_y2
		x = new_x
		y = new_y

class CloseCommand extends PathCommand:
	func _init() -> void:
		command_char = "Z"


# Path parsing and helpers.

func parse_path_data(path_string: String) -> Array[Array]:
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
			if args_left == 0:
				prev_command = curr_command
				var finalized_arr: Array = [curr_command]
				curr_command = ""
				finalized_arr.append_array(curr_command_args)
				curr_command_args.clear()
				new_commands.append(finalized_arr)
	return new_commands

func path_commands_from_parsed_data(data: Array[Array]) -> Array[PathCommand]:
	var cmds: Array[PathCommand] = []
	for arr in data:
		var new_cmd: PathCommand
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
		cmds.append(new_cmd)
	return cmds


func _input(event: InputEvent) -> void:
	Utils.defocus_control_on_outside_click(line_edit, event)


# DEBUG
#func _enter_tree() -> void:
	#var tests := {
		#"Jerky": [],
		#"M 0 0": [["M", 0.0, 0.0]],
		#"M2 1 L3 4": [["M", 2.0, 1.0], ["L", 3.0, 4.0]],
		#"m2 0 3 4": [["m", 2.0, 0.0], ["l", 3.0, 4.0]],
		#"m-2.3.7-4,4": [["m", -2.3, 0.7], ["l", -4.0, 4.0]],
		#"m2 3a7 3 0 101.2.3": [["m", 2.0, 3.0], ["a", 7.0, 3.0, 0.0, 1, 0, 1.2, 0.3]],
		#"M 2 0  c3 2-.6.8 11.0 3Jh3": [["M", 2.0, 0.0], ["c", 3.0, 2.0, -0.6, 0.8, 11.0, 3.0]],
	#}
#
	#var tests_passed := true
	#for test in tests.keys():
		#var result := parse_path_data(test)
		#var expected: Array = tests[test]
		#if result != expected:
			#tests_passed = false
			#print('"' + test + '" generated ' + str(result) + ', expected ' + str(expected))
		#else:
			#print('"' + test + '" generated ' + str(result) + ' (SUCCESS)')
	#assert(tests_passed)
