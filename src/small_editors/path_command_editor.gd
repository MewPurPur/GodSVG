extends HBoxContainer

const MiniNumberField = preload("mini_number_field.tscn")
const FlagField = preload("flag_field.tscn")

var cmd_type := ""

@onready var relative_button: Button = $RelativeButton
@onready var more_button: Button = $MoreButton
@onready var fields_container: HBoxContainer = $Fields

var fields_added_before_ready: Array[Control] = []

func _ready() -> void:
	setup(cmd_type)
	while not fields_added_before_ready.is_empty():
		fields_container.add_child(fields_added_before_ready.pop_front())

func create_stylebox(inside_color: Color, border_color: Color) -> StyleBoxFlat:
	var new_stylebox := StyleBoxFlat.new()
	new_stylebox.bg_color = inside_color
	new_stylebox.border_color = border_color
	new_stylebox.set_border_width_all(2)
	new_stylebox.set_corner_radius_all(4)
	new_stylebox.content_margin_bottom = 1
	new_stylebox.content_margin_top = 1
	new_stylebox.content_margin_left = 6
	new_stylebox.content_margin_right = 6
	return new_stylebox

func setup(command_char: String) -> void:
	cmd_type = command_char
	relative_button.text = cmd_type
	if Utils.is_string_upper(cmd_type):
		relative_button.add_theme_stylebox_override(&"normal", create_stylebox(
				Color.from_hsv(0.08, 0.8, 0.8), Color.from_hsv(0.1, 0.6, 0.9)))
		relative_button.add_theme_stylebox_override(&"hover", create_stylebox(
				Color.from_hsv(0.09, 0.75, 0.9), Color.from_hsv(0.11, 0.55, 0.95)))
		relative_button.add_theme_stylebox_override(&"pressed", create_stylebox(
				Color.from_hsv(0.11, 0.6, 1.0), Color.from_hsv(0.13, 0.4, 1.0)))
	else:
		relative_button.add_theme_stylebox_override(&"normal", create_stylebox(
				Color.from_hsv(0.8, 0.8, 0.8), Color.from_hsv(0.76, 0.6, 0.9)))
		relative_button.add_theme_stylebox_override(&"hover", create_stylebox(
				Color.from_hsv(0.78, 0.75, 0.9), Color.from_hsv(0.74, 0.55, 0.95)))
		relative_button.add_theme_stylebox_override(&"pressed", create_stylebox(
				Color.from_hsv(0.74, 0.6, 1.0), Color.from_hsv(0.7, 0.4, 1.0)))

func add_number_field() -> BetterLineEdit:
	var new_number_field := MiniNumberField.instantiate()
	safely_add_field(new_number_field)
	return new_number_field

func add_flag_field() -> Button:
	var new_flag_field := FlagField.instantiate()
	safely_add_field(new_flag_field)
	return new_flag_field

func safely_add_field(field: Control) -> void:
	if fields_container == null:
		fields_added_before_ready.append(field)
	else:
		fields_container.add_child(field)

func _on_relative_button_pressed() -> void:
	setup(cmd_type.to_upper() if Utils.is_string_lower(cmd_type) else cmd_type.to_lower())
