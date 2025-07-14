# This is similar to SettingFrame, but specifically for dropdowns without a default value.
extends MarginContainer

const Dropdown = preload("res://src/ui_widgets/dropdown.gd")

signal value_changed
signal defaults_applied

const DropdownScene = preload("res://src/ui_widgets/dropdown.tscn")

var getter: Callable
var setter: Callable
var disabled_check_callback: Callable
var text: String

var ci := get_canvas_item()
var dropdown: Dropdown

var is_hovered := false

@onready var button: Button = $HBoxContainer/Button
@onready var control: Control = $HBoxContainer/Control

func setup_dropdown(values: Array, value_text_map: Dictionary) -> void:
	dropdown = DropdownScene.instantiate()
	dropdown.values = values
	dropdown.value_text_map = value_text_map

func _ready() -> void:
	Configs.theme_changed.connect(update_theme)
	update_theme()
	button.text = Translator.translate("Apply")
	button.tooltip_text = Translator.translate("Apply all of this preset's defaults")
	control.add_child(dropdown)
	dropdown.value_changed.connect(_dropdown_modification)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(setup_size)
	dropdown.set_value(getter.call())
	button_update_disabled()
	button.pressed.connect(defaults_applied.emit)
	control.resized.connect(setup_size.call_deferred)
	setup_size.call_deferred()

func update_theme() -> void:
	const CONST_ARR: PackedStringArray = ["normal", "hover", "pressed", "disabled"]
	for theme_style in CONST_ARR:
		var theme_sb := get_theme_stylebox(theme_style, "TranslucentButton").duplicate()
		theme_sb.content_margin_top -= 1
		theme_sb.content_margin_bottom -= 1
		button.add_theme_stylebox_override(theme_style, theme_sb)

func button_update_disabled() -> void:
	var should_disable: bool = disabled_check_callback.call()
	button.disabled = should_disable
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW if should_disable else\
			Control.CURSOR_POINTING_HAND

func setup_size() -> void:
	dropdown.position = Vector2(control.size.x - 102, 1)
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
	ThemeUtils.regular_font.draw_string(ci, Vector2(4, 19), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ThemeUtils.text_color)
