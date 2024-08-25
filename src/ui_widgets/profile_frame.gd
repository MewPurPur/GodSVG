# This is similar to SettingFrame, but specifically for dropdowns without a default value.
extends Control

signal value_changed

var getter: Callable
var setter: Callable
var text: String

var ci := get_canvas_item()
@onready var dropdown: HBoxContainer = $Dropdown

func _ready() -> void:
	dropdown.value_changed.connect(_dropdown_modification)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	resized.connect(setup_size)
	dropdown.value = getter.call()
	setup_size()

func setup_size() -> void:
	dropdown.position = Vector2(size.x - 102, 3)
	dropdown.size = Vector2(98, 22)
	queue_redraw()

func _dropdown_modification(value: String) -> void:
	setter.call(value)
	dropdown.value = getter.call()
	value_changed.emit()

func _draw() -> void:
	if Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()):
		get_theme_stylebox("hover", "FlatButton").draw(ci, Rect2(Vector2.ZERO, size))
	ThemeUtils.regular_font.draw_string(ci, Vector2(4, 18), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
