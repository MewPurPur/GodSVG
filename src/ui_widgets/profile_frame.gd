# This is similar to SettingFrame, but specifically for dropdowns without a default value.
extends Control

signal value_changed

const Dropdown = preload("res://src/ui_widgets/dropdown.tscn")

var getter: Callable
var setter: Callable
var text: String

var ci := get_canvas_item()
var dropdown: Control

var is_hovered := false

func setup_dropdown(values: Array, value_text_map: Dictionary) -> void:
	dropdown = Dropdown.instantiate()
	dropdown.values = values
	dropdown.set("value_text_map", value_text_map)  # TODO Typed dictionary wonkiness

func _ready() -> void:
	add_child(dropdown)
	dropdown.value_changed.connect(_dropdown_modification)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
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


func _on_mouse_entered() -> void:
	is_hovered = true
	queue_redraw()

func _on_mouse_exited() -> void:
	is_hovered = false
	queue_redraw()

func _draw() -> void:
	if is_hovered:
		get_theme_stylebox("hover", "FlatButton").draw(ci, Rect2(Vector2.ZERO, size))
	ThemeUtils.regular_font.draw_string(ci, Vector2(4, 18), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.9))
