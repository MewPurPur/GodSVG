class_name PathCommandArray extends RefCounted

const translation_dict := {
	"M": MoveCommand, "L": LineCommand, "H": HorizontalLineCommand,
	"V": VerticalLineCommand, "Z": CloseCommand, "A": EllipticalArcCommand,
	"Q": QuadraticBezierCommand, "T": ShorthandQuadraticBezierCommand,
	"C": CubicBezierCommand, "S": ShorthandCubicBezierCommand
}

signal changed

var data: Array[PathCommand] = []


func _init() -> void:
	changed.connect(_on_changed)

func _on_changed() -> void:
	locate_start_points()


func locate_start_points() -> void:
	# Start points are absolute.
	var last_end_point := Vector2.ZERO
	var current_subpath_start := Vector2.ZERO
	for path_command in data:
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


func get_count() -> int:
	return data.size()

func get_command(idx: int) -> PathCommand:
	return data[idx]


func set_command_property(idx: int, property: StringName, value: float) -> void:
	data[idx].set(property, value)
	changed.emit()

func add_command(command_char: String) -> void:
	data.append(translation_dict[command_char.to_upper()].new())
	if Utils.is_string_lower(command_char):
		data.back().toggle_relative()
	changed.emit()

func delete_command(idx: int) -> void:
	data.remove_at(idx)
	changed.emit()

func toggle_relative_command(idx: int) -> void:
	data[idx].toggle_relative()
	changed.emit()

func set_value(path_string: String) -> void:
	# Don't emit changed, as this rebuilds the data.
	data = PathDataParser.parse_path_data(path_string)
	locate_start_points()


class PathCommand extends RefCounted:
	var command_char := ""
	var arg_count := 0
	var relative := false
	var start: Vector2
	func toggle_relative() -> void:
		if relative:
			relative = false
			command_char = command_char.to_upper()
			for property in [&"x", &"x1", &"x2"]:
				if property in self:
					set(property, start.x + get(property))
			for property in [&"y", &"y1", &"y2"]:
				if property in self:
					set(property, start.y + get(property))
		else:
			relative = true
			command_char = command_char.to_lower()
			for property in [&"x", &"x1", &"x2"]:
				if property in self:
					set(property, get(property) - start.x)
			for property in [&"y", &"y1", &"y2"]:
				if property in self:
					set(property, get(property) - start.y)

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
