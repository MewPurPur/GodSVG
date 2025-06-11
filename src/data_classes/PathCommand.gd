# A native class that represents a path command and its parameters.
abstract class_name PathCommand

const translation_dict: Dictionary[String, GDScript] = {
	"M": MoveCommand, "L": LineCommand, "H": HorizontalLineCommand,
	"V": VerticalLineCommand, "Z": CloseCommand, "A": EllipticalArcCommand,
	"Q": QuadraticBezierCommand, "T": ShorthandQuadraticBezierCommand,
	"C": CubicBezierCommand, "S": ShorthandCubicBezierCommand
}

const arg_count_dict: Dictionary[String, int] = {
	"M": 2, "L": 2, "H": 1, "V": 1, "Z": 0, "A": 7, "Q": 4, "T": 2, "C": 6, "S": 4
}

var command_char := ""
var relative := false

# This must be floats, because 64-bit precision is needed for intermediate operations.
var start_x := 0.0
var start_y := 0.0

func get_start_coords() -> Vector2:
	return Vector2(start_x, start_y)


func toggle_relative() -> void:
	if relative:
		relative = false
		command_char = command_char.to_upper()
		if "x" in self:
			self.x += start_x
		if "x1" in self:
			self.x1 += start_x
		if "x2" in self:
			self.x2 += start_x
		if "y" in self:
			self.y += start_y
		if "y1" in self:
			self.y1 += start_y
		if "y2" in self:
			self.y2 += start_y
	else:
		relative = true
		command_char = command_char.to_lower()
		if "x" in self:
			self.x -= start_x
		if "x1" in self:
			self.x1 -= start_x
		if "x2" in self:
			self.x2 -= start_x
		if "y" in self:
			self.y -= start_y
		if "y1" in self:
			self.y1 -= start_y
		if "y2" in self:
			self.y2 -= start_y


class MoveCommand extends PathCommand:
	var x: float
	var y: float
	func _init(new_x := 0.0, new_y := 0.0, p_rel := false) -> void:
		relative = p_rel
		command_char = "m" if p_rel else "M"
		x = new_x
		y = new_y

class LineCommand extends PathCommand:
	var x: float
	var y: float
	func _init(new_x := 0.0, new_y := 0.0, p_rel := false) -> void:
		relative = p_rel
		command_char = "l" if p_rel else "L"
		x = new_x
		y = new_y

class HorizontalLineCommand extends PathCommand:
	var x: float
	func _init(new_x := 0.0, p_rel := false) -> void:
		relative = p_rel
		command_char = "h" if p_rel else "H"
		x = new_x

class VerticalLineCommand extends PathCommand:
	var y: float
	func _init(new_y := 0.0, p_rel := false) -> void:
		relative = p_rel
		command_char = "v" if p_rel else "V"
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
	new_sweep_flag := 0, new_x := 0.0, new_y := 0.0, p_rel := false) -> void:
		relative = p_rel
		command_char = "a" if p_rel else "A"
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
	func _init(new_x1 := 0.0, new_y1 := 0.0, new_x := 0.0, new_y := 0.0,
	p_rel := false) -> void:
		relative = p_rel
		command_char = "q" if p_rel else "Q"
		x1 = new_x1
		y1 = new_y1
		x = new_x
		y = new_y

class ShorthandQuadraticBezierCommand extends PathCommand:
	var x: float
	var y: float
	func _init(new_x := 0.0, new_y := 0.0, p_rel := false) -> void:
		relative = p_rel
		command_char = "t" if p_rel else "T"
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
	new_x := 0.0, new_y := 0.0, p_rel := false) -> void:
		relative = p_rel
		command_char = "c" if p_rel else "C"
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
	func _init(new_x2 := 0.0, new_y2 := 0.0, new_x := 0.0, new_y := 0.0,
	p_rel := false) -> void:
		relative = p_rel
		command_char = "s" if p_rel else "S"
		x2 = new_x2
		y2 = new_y2
		x = new_x
		y = new_y

class CloseCommand extends PathCommand:
	func _init(p_rel := false) -> void:
		relative = p_rel
		command_char = "z" if p_rel else "Z"
