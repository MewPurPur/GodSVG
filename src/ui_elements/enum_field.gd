## An editor to be tied to an AttributeEnum.
extends AttributeEditor

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const bold_font = preload("res://visual/fonts/FontBold.ttf")

@onready var indicator: LineEdit = $LineEdit

signal value_changed(new_value: String)
var _value: String  # Must not be updated directly.

func set_value(new_value: String, emit_value_changed := true):
	if _value != new_value:
		_value = new_value
		if emit_value_changed:
			value_changed.emit(new_value)

func get_value() -> String:
	return _value


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		set_value(attribute.get_value())
	indicator.text = str(get_value())
	indicator.tooltip_text = attribute_name

func _on_button_pressed() -> void:
	var value_picker := ContextPopup.instantiate()
	var buttons_arr: Array[Button] = []
	for enum_constant in attribute.possible_values:
		var btn := Button.new()
		btn.text = str(enum_constant)
		btn.pressed.connect(_on_option_pressed.bind(enum_constant))
		btn.pressed.connect(value_picker.hide)
		if enum_constant == get_value():
			btn.disabled = true
		else:
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if attribute != null and enum_constant == attribute.default:
			btn.add_theme_font_override(&"font", bold_font)
		buttons_arr.append(btn)
	add_child(value_picker)
	value_picker.popup_hide.connect(value_picker.queue_free)
	value_picker.set_btn_array(buttons_arr)
	Utils.popup_under_control(value_picker, indicator)

func _on_option_pressed(option: String) -> void:
	set_value(option)

func _on_value_changed(new_value: String) -> void:
	indicator.text = new_value
	if attribute != null:
		attribute.set_value(new_value)
		set_text_tint()


func _on_text_submitted(new_text: String) -> void:
	indicator.release_focus()
	if new_text in attribute.possible_values:
		set_value(new_text)
	elif new_text.is_empty():
		indicator.text = attribute.default
	else:
		indicator.text = get_value()

func _on_text_changed(new_text: String) -> void:
	if new_text in attribute.possible_values:
		indicator.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.6))
	else:
		indicator.add_theme_color_override(&"font_color", Color(1.0, 0.6, 0.6))

func set_text_tint() -> void:
	if indicator != null:
		if attribute != null and get_value() == attribute.default:
			indicator.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
		else:
			indicator.remove_theme_color_override(&"font_color")
