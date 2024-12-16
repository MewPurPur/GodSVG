# This is similar to SettingFrame, but specifically for dropdowns without a default value.
extends Control

signal value_changed

const Dropdown = preload("res://src/ui_widgets/dropdown.tscn")
const EnumDropdown = preload("res://src/ui_widgets/enum_dropdown.tscn")

var getter: Callable
var setter: Callable
var text: String

var ci := get_canvas_item()
var dropdown: Control

func setup_dropdown(enum_mode := false) -> void:
	dropdown = EnumDropdown.instantiate() if enum_mode else Dropdown.instantiate()

func _ready() -> void:
	add_child(dropdown)
	dropdown.value_changed.connect(_dropdown_modification)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	resized.connect(setup_size)
	dropdown.set_value(getter.call())
	setup_size()

func setup_size() -> void:
	dropdown.position = Vector2(size.x - 102, 3)
	dropdown.size = Vector2(98, 22)
	queue_redraw()

# value can be String for dropdown or int for enum dropdown.
func _dropdown_modification(value: Variant) -> void:
	setter.call(value)
	dropdown.set_value(getter.call())
	value_changed.emit()

func _draw() -> void:
	if Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()):
		get_theme_stylebox("hover", "FlatButton").draw(ci, Rect2(Vector2.ZERO, size))
	ThemeConfig.main_font.draw_string(ci, Vector2(4, 18), text, HORIZONTAL_ALIGNMENT_LEFT,
			-1, 13, Color(1, 1, 1, 0.9))
