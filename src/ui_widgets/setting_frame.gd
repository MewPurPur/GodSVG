extends Control

enum Type {NONE, CHECKBOX, COLOR, DROPDOWN, NUMBER_DROPDOWN}
var type := Type.NONE

signal value_changed

const ColorEdit = preload("res://src/ui_widgets/color_edit.tscn")
const Dropdown = preload("res://src/ui_widgets/enum_dropdown.tscn")
const NumberDropdown = preload("res://src/ui_widgets/number_dropdown.tscn")

const font = preload("res://visual/fonts/Font.ttf")

var section: String
var setting: String
var text: String
var disabled := false

var widget: Control
var panel_size := 0

@onready var reset_button: Button = $ResetButton
var ci := get_canvas_item()

func setup_checkbox() -> void:
	widget = CheckBox.new()
	widget.focus_mode = Control.FOCUS_NONE
	widget.mouse_filter = Control.MOUSE_FILTER_PASS
	widget.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(widget)
	widget.button_pressed = GlobalSettings.get(setting)
	widget.toggled.connect(_checkbox_modification.unbind(1))
	type = Type.CHECKBOX
	panel_size = 76

func setup_color(enable_alpha: bool) -> void:
	widget = ColorEdit.instantiate()
	widget.enable_alpha = enable_alpha
	widget.enable_palettes = false
	widget.value = GlobalSettings.get(setting).to_html(enable_alpha)
	add_child(widget)
	widget.value_changed.connect(_color_modification)
	type = Type.COLOR
	panel_size = 114 if enable_alpha else 100

func setup_dropdown(values: Array[String]) -> void:
	widget = Dropdown.instantiate()
	widget.values = values
	add_child(widget)
	widget.value_changed.connect(_dropdown_modification)
	type = Type.DROPDOWN
	panel_size = 100

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
	panel_size = 100

func _ready() -> void:
	widget.size = Vector2(panel_size - 32, 22)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	resized.connect(_on_resized)
	reset_button.reset_size()
	if type != Type.NONE:
		widget.reset_size()
	reset_button.tooltip_text = TranslationServer.translate("Reset to default")
	reset_button.position = Vector2(size.x - 24, 4)
	reset_button.pressed.connect(_on_reset_button_pressed)
	update_widgets()

func _on_resized() -> void:
	widget.position = Vector2(size.x - panel_size, 3)
	reset_button.position = Vector2(size.x - 24, 4)
	queue_redraw()

func _on_reset_button_pressed() -> void:
	GlobalSettings.reset_setting(section, setting)
	value_changed.emit()
	update_widgets()

func _checkbox_modification() -> void:
	GlobalSettings.modify_setting(section, setting, !GlobalSettings.get(setting))
	post_modification()

func _color_modification(value: String) -> void:
	GlobalSettings.modify_setting(section, setting, Color(value))
	post_modification()

func _dropdown_modification(value: int) -> void:
	GlobalSettings.modify_setting(section, setting, value)
	post_modification()

func _number_dropdown_modification(value: String) -> void:
	if not type in [TYPE_INT, TYPE_FLOAT]:
		return
	var actual_number := NumberParser.evaluate(value)
	actual_number = clampf(actual_number, widget.min_value, widget.max_value)
	value = var_to_str(actual_number)
	if value == "nan":
		GlobalSettings.reset_setting(section, setting)
	else:
		GlobalSettings.modify_setting(section, setting, actual_number)
	post_modification()

func post_modification() -> void:
	update_widgets()
	value_changed.emit()

func update_widgets() -> void:
	match type:
		Type.CHECKBOX:
			widget.text = "On" if GlobalSettings.get(setting) else "Off"
			reset_button.visible = (not disabled and GlobalSettings.get(setting) !=\
					GlobalSettings.get_default(section, setting))
		Type.COLOR:
			var setting_value: Color = GlobalSettings.get(setting)
			var show_alpha: bool = widget.enable_alpha and setting_value.a != 1.0
			var setting_str: String = setting_value.to_html(show_alpha)
			widget.value = setting_str
			reset_button.visible = (not disabled and not GlobalSettings.get(setting).\
					is_equal_approx(GlobalSettings.get_default(section, setting)))
		Type.DROPDOWN:
			widget.value = str(GlobalSettings.get(setting))
			reset_button.visible = (not disabled and GlobalSettings.get(setting) !=\
					GlobalSettings.get_default(section, setting))
		Type.NUMBER_DROPDOWN:
			widget.value = NumberParser.num_to_text(GlobalSettings.get(setting))
			reset_button.visible = (not disabled and not is_equal_approx(
					GlobalSettings.get(setting), GlobalSettings.get_default(section, setting)))
	queue_redraw()

func _draw() -> void:
	if not disabled and Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()):
		get_theme_stylebox("hover", "FlatButton").draw(ci, Rect2(Vector2.ZERO, size))
	
	var color := Color.WHITE
	if disabled:
		color = ThemeGenerator.common_subtle_text_color
	font.draw_string(ci, Vector2(4, 18), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
	get_theme_stylebox("panel", "DarkPanel").draw(ci, Rect2(size.x - panel_size - 2, 2,
			panel_size, size.y - 4))
