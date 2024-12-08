extends Control

enum Type {NONE, CHECKBOX, COLOR, DROPDOWN, NUMBER_DROPDOWN}
var type := Type.NONE

signal value_changed

const ColorEdit = preload("res://src/ui_widgets/color_edit.tscn")
const Dropdown = preload("res://src/ui_widgets/enum_dropdown.tscn")
const NumberDropdown = preload("res://src/ui_widgets/number_dropdown.tscn")

var getter: Callable
var setter: Callable
var default: Variant

var text: String
var disabled := false:
	set(new_value):
		if disabled != new_value:
			disabled = new_value
			update_widgets()

var dim_text := false  # For settings that wouldn't have an effect.

var widget: Control
var panel_width := 0

var is_hovered := false

@onready var reset_button: Button = $ResetButton
var ci := get_canvas_item()

func permanent_disable_checkbox(checkbox_state: bool) -> void:
	disabled = true
	widget.set_pressed_no_signal(checkbox_state)

func setup_checkbox() -> void:
	widget = CheckBox.new()
	widget.focus_mode = Control.FOCUS_NONE
	widget.mouse_filter = Control.MOUSE_FILTER_PASS
	widget.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(widget)
	widget.button_pressed = getter.call()
	widget.toggled.connect(_checkbox_modification.unbind(1))
	type = Type.CHECKBOX
	panel_width = 76

func setup_color(enable_alpha: bool) -> void:
	widget = ColorEdit.instantiate()
	widget.enable_alpha = enable_alpha
	widget.enable_palettes = false
	widget.value = getter.call().to_html(enable_alpha)
	add_child(widget)
	widget.value_changed.connect(_color_modification.bind(enable_alpha))
	type = Type.COLOR
	panel_width = 114 if enable_alpha else 100

func setup_dropdown(values: PackedStringArray) -> void:
	widget = Dropdown.instantiate()
	widget.values = values
	add_child(widget)
	widget.value_changed.connect(_dropdown_modification)
	type = Type.DROPDOWN
	panel_width = 100

func setup_number_dropdown(values: Array[float], is_integer: bool, restricted: bool,
min_value: float, max_value: float) -> void:
	widget = NumberDropdown.instantiate()
	widget.values = values
	widget.is_integer = is_integer
	widget.restricted = restricted
	widget.min_value = min_value
	widget.max_value = max_value
	add_child(widget)
	widget.value_changed.connect(_number_dropdown_modification)
	type = Type.NUMBER_DROPDOWN
	panel_width = 100

func _ready() -> void:
	widget.size = Vector2(panel_width - 32, 22)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(_on_resized)
	reset_button.reset_size()
	if type != Type.NONE:
		widget.reset_size()
	reset_button.tooltip_text = Translator.translate("Reset to default")
	reset_button.position = Vector2(size.x - 24, 4)
	reset_button.pressed.connect(_on_reset_button_pressed)
	update_widgets()

func _on_resized() -> void:
	widget.position = Vector2(size.x - panel_width, 3)
	reset_button.position = Vector2(size.x - 24, 4)
	queue_redraw()

func _on_reset_button_pressed() -> void:
	setter.call(default)
	value_changed.emit()
	update_widgets()

func _checkbox_modification() -> void:
	setter.call(!getter.call())
	post_modification()

func _color_modification(value: String, enable_alpha: bool) -> void:
	setter.call(ColorParser.text_to_color(value, Color(), enable_alpha))
	post_modification()

func _dropdown_modification(value: int) -> void:
	setter.call(value)
	post_modification()

func _number_dropdown_modification(value: String) -> void:
	var actual_number := NumstringParser.evaluate(value)
	actual_number = clampf(actual_number, widget.min_value, widget.max_value)
	value = var_to_str(actual_number)
	if value == "nan":
		setter.call(default)
	else:
		setter.call(actual_number)
	post_modification()

func post_modification() -> void:
	update_widgets()
	value_changed.emit()

func update_widgets() -> void:
	match type:
		Type.CHECKBOX:
			widget.text = "On" if getter.call() else "Off"
			reset_button.visible = (not disabled and getter.call() != default)
			if disabled:
				widget.mouse_default_cursor_shape = Control.CURSOR_ARROW
				widget.disabled = true
		Type.COLOR:
			var setting_value: Color = getter.call()
			var show_alpha: bool = widget.enable_alpha and setting_value.a != 1.0
			var setting_str: String = setting_value.to_html(show_alpha)
			widget.value = setting_str
			reset_button.visible = (not disabled and\
					getter.call().to_html() != default.to_html())
		Type.DROPDOWN:
			widget.set_value(getter.call())
			reset_button.visible = (not disabled and getter.call() != default)
		Type.NUMBER_DROPDOWN:
			widget.set_value(widget.to_str(getter.call()))
			reset_button.visible = not (disabled or is_equal_approx(getter.call(), default))
	queue_redraw()

func _on_mouse_entered() -> void:
	is_hovered = true
	queue_redraw()

func _on_mouse_exited() -> void:
	is_hovered = false
	queue_redraw()

func _draw() -> void:
	if is_hovered:
		get_theme_stylebox("hover", "FlatButton").draw(ci, Rect2(Vector2.ZERO, size))
	
	var color := Color(1, 1, 1, 0.9)
	if disabled:
		color = ThemeUtils.common_subtle_text_color
	elif dim_text:
		color = Color(1, 1, 1, 0.5)
	
	var non_panel_width := size.x - panel_width
	var text_obj := TextLine.new()
	text_obj.add_string(text, ThemeUtils.regular_font, 13)
	text_obj.width = non_panel_width - 16
	text_obj.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_obj.draw(ci, Vector2(4, 5), color)
	get_theme_stylebox("panel", "DarkPanel").draw(ci, Rect2(non_panel_width - 2, 2,
			panel_width, size.y - 4))
