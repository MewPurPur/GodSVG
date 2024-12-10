# A dropdown with multiple options, not tied to any attribute.
extends HBoxContainer

signal value_changed(new_value: int)

@onready var line_edit: BetterLineEdit = $LineEdit

@export var values := PackedStringArray()

var _value := -1

func set_value(new_value: int) -> void:
	if new_value != _value:
		_value = new_value
		value_changed.emit(_value)
		line_edit.text = values[_value]

func _on_button_pressed() -> void:
	var btn_arr: Array[Button] = []
	for idx in values.size():
		btn_arr.append(ContextPopup.create_button(values[idx], set_value.bind(idx),
				_value == idx))
	var value_picker := ContextPopup.new()
	value_picker.setup(btn_arr, false, size.x)
	HandlerGUI.popup_under_rect(value_picker, line_edit.get_global_rect(), get_viewport())
