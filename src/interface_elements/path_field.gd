extends VBoxContainer

const NumberField = preload("number_field.tscn")
const FlagField = preload("flag_field.tscn")

var attribute: SVGAttribute
var attribute_name: String

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
var value: String


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		value = attribute.value

func _on_button_pressed() -> void:
	command_picker.popup(Rect2(global_position + Vector2(0, size.y), size))

func _on_path_command_picked(new_command: String) -> void:
	commands.append(translation_dict[new_command].new())
	var old_value := value
	value = path_commands_to_value()
	if old_value != value:
		update_input_fields()
		line_edit.text = value
		value_changed.emit(value)

func path_commands_to_value() -> String:
	var generated_value := ""
	for command in commands:
		generated_value += command.command_char
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
	return generated_value.substr(0, generated_value.length() - 1)

func update_input_fields() -> void:
	# Clear the container of the tags.
	for node in commands_container.get_children():
		node.queue_free()
	# Rebuild it based on the commands array.
	for command_idx in commands.size():
		var command := commands[command_idx]
		var input_field := HBoxContainer.new()
		# TODO split off this button into its own scene?
		var command_char_button := Button.new()
		command_char_button.text = command.command_char
		command_char_button.add_theme_font_override(&"font",
				load("res://visual/CodeFont.ttf"))
		command_char_button.add_theme_font_size_override(&"font_size", 9)
		command_char_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		input_field.add_child(command_char_button)
		if command is EllipticalArcCommand:
			var field_rx: Control = NumberField.instantiate()
			var field_ry: Control = NumberField.instantiate()
			var field_rot: Control = NumberField.instantiate()
			# TODO Add a flag_field
			var field_large_arc_flag: Control = FlagField.instantiate()
			var field_sweep_flag: Control = FlagField.instantiate()
			field_rx.value = command.rx
			field_ry.value = command.ry
			field_rot.value = command.rot
			field_large_arc_flag.value = command.large_arc_flag
			field_sweep_flag.value = command.sweep_flag
			field_rx.min_value = -1024
			field_ry.min_value = -1024
			field_rot.min_value = -360
			field_rot.max_value = 360
			field_rx.is_float = true
			field_ry.is_float = true
			field_rot.is_float = true
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
			field_x1.value = command.x1
			field_y1.value = command.y1
			field_x1.min_value = -1024
			field_y1.min_value = -1024
			field_x1.is_float = true
			field_y1.is_float = true
			input_field.add_child(field_x1)
			input_field.add_child(field_y1)
			field_x1.value_changed.connect(_update_command_value.bind(command_idx, &"x1"))
			field_y1.value_changed.connect(_update_command_value.bind(command_idx, &"y1"))
		if command is CubicBezierCommand or command is ShorthandCubicBezierCommand:
			var field_x2: Control = NumberField.instantiate()
			var field_y2: Control = NumberField.instantiate()
			field_x2.value = command.x2
			field_y2.value = command.y2
			field_x2.min_value = -1024
			field_y2.min_value = -1024
			field_x2.is_float = true
			field_y2.is_float = true
			input_field.add_child(field_x2)
			input_field.add_child(field_y2)
			field_x2.value_changed.connect(_update_command_value.bind(command_idx, &"x2"))
			field_y2.value_changed.connect(_update_command_value.bind(command_idx, &"y2"))
		if not (command is CloseCommand or command is VerticalLineCommand):
			var field_x: Control = NumberField.instantiate()
			field_x.value = command.x
			field_x.min_value = -1024
			field_x.is_float = true
			input_field.add_child(field_x)
			field_x.value_changed.connect(_update_command_value.bind(command_idx, &"x"))
		if not (command is CloseCommand or command is HorizontalLineCommand):
			var field_y: Control = NumberField.instantiate()
			field_y.value = command.y
			field_y.min_value = -1024
			field_y.is_float = true
			input_field.add_child(field_y)
			field_y.value_changed.connect(_update_command_value.bind(command_idx, &"y"))
		
		commands_container.add_child(input_field)


func _update_command_value(new_value, index: int, property: StringName) -> void:
	commands[index].set(property, new_value)
	print(commands[index].get(property))
	value = path_commands_to_value()
	line_edit.text = value
	value_changed.emit(value)

func _on_value_changed(new_value: String) -> void:
	line_edit.text = new_value
	if attribute != null:
		attribute.value = new_value
		SVG.update()


class PathCommand extends RefCounted:
	var command_char := ""
	var is_relative := false
	func toggle_relative() -> void:
		if is_relative:
			is_relative = false
			command_char = command_char.to_upper()
		else:
			is_relative = true
			command_char = command_char.to_lower()

class MoveCommand extends PathCommand:
	var x := 0.0
	var y := 0.0
	func _init() -> void:
		command_char = "M"

class LineCommand extends PathCommand:
	var x := 0.0
	var y := 0.0
	func _init() -> void:
		command_char = "L"

class HorizontalLineCommand extends PathCommand:
	var x := 0.0
	func _init() -> void:
		command_char = "H"

class VerticalLineCommand extends PathCommand:
	var y := 0.0
	func _init() -> void:
		command_char = "V"

class EllipticalArcCommand extends PathCommand:
	var rx := 0.0
	var ry := 0.0
	var rot := 0.0
	var large_arc_flag := 0
	var sweep_flag := 0
	var x := 0.0
	var y := 0.0
	func _init() -> void:
		command_char = "A"

class QuadraticBezierCommand extends PathCommand:
	var x1 := 0.0
	var y1 := 0.0
	var x := 0.0
	var y := 0.0
	func _init() -> void:
		command_char = "Q"

class ShorthandQuadraticBezierCommand extends PathCommand:
	var x := 0.0
	var y := 0.0
	func _init() -> void:
		command_char = "T"

class CubicBezierCommand extends PathCommand:
	var x1 := 0.0
	var y1 := 0.0
	var x2 := 0.0
	var y2 := 0.0
	var x := 0.0
	var y := 0.0
	func _init() -> void:
		command_char = "C"

class ShorthandCubicBezierCommand extends PathCommand:
	var x2 := 0.0
	var y2 := 0.0
	var x := 0.0
	var y := 0.0
	func _init() -> void:
		command_char = "S"

class CloseCommand extends PathCommand:
	func _init() -> void:
		command_char = "Z"
