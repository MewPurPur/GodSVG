extends AttributeEditor

@onready var value_picker: Popup = $ContextPopup
@onready var indicator: LineEdit = $MainLine/LineEdit

signal value_changed(new_value: String)
var value: String:
	set(new_value):
		if value != new_value:
			value = new_value
			value_changed.emit(new_value)


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		value = attribute.value
		var enum_size: int = attribute.possible_values.size()
		for enum_idx in enum_size:
			var enum_constant = attribute.possible_values[enum_idx]
			var butt := Button.new()
			butt.text = str(enum_constant)
			butt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			value_picker.add_button(butt, enum_idx == 0, enum_idx == enum_size - 1)
			butt.pressed.connect(_on_option_pressed.bind(enum_constant))
	indicator.text = str(value)
	indicator.tooltip_text = attribute_name

func _on_button_pressed() -> void:
	value_picker.popup(Rect2(global_position + Vector2(0, size.y), size))


func _on_option_pressed(option: String) -> void:
	value_picker.hide()
	value = option

func _on_value_changed(new_value: String) -> void:
	indicator.text = new_value
	if attribute != null:
		attribute.value = new_value


func _input(event: InputEvent) -> void:
	Utils.defocus_control_on_outside_click(indicator, event)


func _on_line_edit_text_submitted(new_text: String) -> void:
	indicator.remove_theme_color_override(&"font_color")
	indicator.release_focus()
	if new_text in attribute.possible_values:
		value = new_text
	else:
		indicator.text = value

func _on_line_edit_text_changed(new_text: String) -> void:
	if new_text in attribute.possible_values:
		indicator.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.6))
	else:
		indicator.add_theme_color_override(&"font_color", Color(1.0, 0.6, 0.6))
