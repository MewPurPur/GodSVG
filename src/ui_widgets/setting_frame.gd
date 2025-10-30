extends Control

const reload_icon = preload("res://assets/icons/Reload.svg")
const clear_icon = preload("res://assets/icons/Clear.svg")

enum Type {NONE, CHECKBOX, COLOR, DROPDOWN, NUMERIC_DROPDOWN, FILE_PATH}
var type := Type.NONE

signal value_changed

const info_icon = preload("res://assets/icons/Info.svg")

const OptimizerSettingInfoScene = preload("res://src/ui_widgets/optimizer_setting_info.tscn")
const ColorEditScene = preload("res://src/ui_widgets/color_edit.tscn")
const BasicDropdownScene = preload("res://src/ui_widgets/dropdown_basic.tscn")
const NumericDropdownScene = preload("res://src/ui_widgets/dropdown_numeric.tscn")
const FilePathFieldScene = preload("res://src/ui_widgets/file_path_field.tscn")

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
var info_button: Button

var is_hovered := false
var tooltip_rect := Rect2(NAN, NAN, NAN, NAN)

@onready var reset_button: Button = $ResetButton
var ci := get_canvas_item()

func set_optimizer_info(example_root: ElementRoot, optimizer: Optimizer, main_text := "") -> void:
	info_button = Button.new()
	info_button.icon = info_icon
	info_button.theme_type_variation = "FlatButton"
	info_button.mouse_filter = Control.MOUSE_FILTER_PASS
	info_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	info_button.focus_mode = Control.FOCUS_NONE
	add_child(info_button)
	info_button.pressed.connect(func() -> void:
		var info := OptimizerSettingInfoScene.instantiate()
		info.setup(example_root.duplicate(), optimizer, main_text)
		HandlerGUI.popup_under_rect_center(info, info_button.get_global_rect(), get_viewport())
	)
	var margin_size := (size.y - info_button.size.y) / 2.0
	info_button.position = Vector2(margin_size, margin_size)

func permanent_disable_checkbox(checkbox_state: bool) -> void:
	disabled = true
	widget.set_pressed_no_signal(checkbox_state)
	widget.text = "On" if checkbox_state else "Off"

func setup_checkbox() -> void:
	widget = CheckBox.new()
	widget.focus_mode = Control.FOCUS_NONE
	widget.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	widget.mouse_filter = Control.MOUSE_FILTER_PASS
	widget.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(widget)
	widget.button_pressed = getter.call()
	widget.toggled.connect(_checkbox_modification.unbind(1))
	type = Type.CHECKBOX
	panel_width = 74

func setup_color(enable_alpha: bool) -> void:
	widget = ColorEditScene.instantiate()
	widget.enable_alpha = enable_alpha
	widget.value = getter.call().to_html(enable_alpha)
	add_child(widget)
	widget.value_changed.connect(_color_modification.bind(enable_alpha))
	type = Type.COLOR
	panel_width = 110 if enable_alpha else 96

func setup_file_path(extensions: PackedStringArray) -> void:
	widget = FilePathFieldScene.instantiate()
	widget.extensions = extensions
	widget.value = getter.call()
	add_child(widget)
	widget.value_changed.connect(_generic_modification)
	type = Type.FILE_PATH
	panel_width = 160

# TODO Typed Dictionary wonkiness
func setup_dropdown(values: Array[Variant], value_text_map: Dictionary) -> void:  # Dictionary[Variant, String]
	widget = BasicDropdownScene.instantiate()
	widget.values = values
	widget.value_text_map = value_text_map
	add_child(widget)
	widget.value_changed.connect(_generic_modification)
	type = Type.DROPDOWN
	panel_width = 140

func setup_numeric_dropdown(values_for_dropdown: PackedFloat64Array, use_integers: bool,
min_value: float, max_value: float, special_value_exception: float, value_text_map: Dictionary[float, String]) -> void:
	widget = NumericDropdownScene.instantiate()
	widget.values_for_dropdown = values_for_dropdown
	widget.use_integers = use_integers
	widget.min_value = min_value
	widget.max_value = max_value
	widget.special_value_exception = special_value_exception
	widget.value_text_map = value_text_map
	add_child(widget)
	widget.value_changed.connect(_float_modification_with_nan_reset)
	type = Type.NUMERIC_DROPDOWN
	panel_width = 101

func _ready() -> void:
	widget.custom_minimum_size = Vector2(panel_width - 28, 22)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(_on_resized)
	reset_button.reset_size()
	if type != Type.NONE:
		widget.reset_size()
	reset_button.position = Vector2(size.x - 24, 4)
	reset_button.pressed.connect(_on_reset_button_pressed)
	update_widgets()
	if typeof(default) == TYPE_STRING and default.is_empty():
		reset_button.tooltip_text = Translator.translate("Clear")
		reset_button.icon = clear_icon
	else:
		reset_button.tooltip_text = Translator.translate("Reset to default")
		reset_button.icon = reload_icon

func _on_resized() -> void:
	widget.position = Vector2(size.x - panel_width, 3)
	reset_button.position = Vector2(size.x - 24, 4)
	queue_redraw()

func _on_reset_button_pressed() -> void:
	setter.call(default)
	value_changed.emit()
	update_widgets()

func _checkbox_modification() -> void:
	setter.call(not getter.call())
	post_modification()

func _color_modification(value: String, enable_alpha: bool) -> void:
	setter.call(ColorParser.text_to_color(value, Color(), enable_alpha))
	post_modification()

func _generic_modification(value: Variant) -> void:
	setter.call(value)
	post_modification()

func _float_modification_with_nan_reset(value: float) -> void:
	if is_nan(value):
		setter.call(default)
	else:
		setter.call(value)
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
			widget.set_pressed_no_signal(getter.call())
		Type.COLOR:
			var setting_value: Color = getter.call()
			var show_alpha: bool = widget.enable_alpha and setting_value.a != 1.0
			var setting_str := setting_value.to_html(show_alpha)
			widget.value = setting_str
			reset_button.visible = (not disabled and getter.call().to_html() != default.to_html())
		Type.DROPDOWN:
			widget.set_value(getter.call())
			reset_button.visible = (not disabled and getter.call() != default)
		Type.NUMERIC_DROPDOWN:
			widget.set_value(getter.call())
			reset_button.visible = not (disabled or is_equal_approx(getter.call(), default))
		Type.FILE_PATH:
			if OS.has_feature("web"):
				widget.permanently_disable()
				reset_button.hide()
			else:
				widget.set_value(getter.call())
				reset_button.visible = (not disabled and getter.call() != default)
	queue_redraw()

func _on_mouse_entered() -> void:
	is_hovered = true
	queue_redraw()

func _on_mouse_exited() -> void:
	is_hovered = false
	queue_redraw()

func _draw() -> void:
	if is_hovered:
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(3)
		sb.set_content_margin_all(2)
		sb.bg_color = ThemeUtils.soft_hover_overlay_color
		sb.draw(ci, Rect2(Vector2.ZERO, size))
	
	var color := ThemeUtils.text_color
	if disabled:
		color = ThemeUtils.subtle_text_color
	elif dim_text:
		color = ThemeUtils.dimmer_text_color
	
	var text_pos_x := 4.0
	var non_panel_width := size.x - panel_width
	var text_space := non_panel_width - 16
	if is_instance_valid(info_button):
		text_pos_x += info_button.size.x + (size.y - info_button.size.x) / 2.0
		text_space -= size.y
	var text_obj := TextLine.new()
	text_obj.add_string(text, ThemeUtils.main_font, 13)
	text_obj.width = text_space
	text_obj.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_obj.draw(ci, Vector2(text_pos_x, 5), color)
	get_theme_stylebox("panel", "SubtleFlatPanel").draw(ci, Rect2(non_panel_width - 2, 2, panel_width, size.y - 4))

	if text_space < ThemeUtils.main_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x:
		tooltip_rect = Rect2(text_pos_x, 5, text_space, size.y - 10)
	else:
		tooltip_rect = Rect2(NAN, NAN, NAN, NAN)

func _get_tooltip(at_position: Vector2) -> String:
	if tooltip_rect.is_finite() and tooltip_rect.has_point(at_position):
		return text
	return ""
