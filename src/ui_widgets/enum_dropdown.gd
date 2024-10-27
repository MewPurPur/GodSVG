# A dropdown with multiple options, not tied to any attribute.
extends HBoxContainer

signal value_changed(new_value: int)

@onready var line_edit: BetterLineEdit = $LineEdit

@export var values := PackedStringArray()

var value := -1:
	set(new_value):
		if new_value != value:
			value = new_value
			value_changed.emit(value)
			line_edit.text = values[value]

func _on_button_pressed() -> void:
	var btn_arr: Array[Button] = []
	for idx in values.size():
		btn_arr.append(ContextPopup.create_button(values[idx], set.bind("value", idx),
				value == idx))
	var value_picker := ContextPopup.new()
	value_picker.setup(btn_arr, false, size.x)
	HandlerGUI.popup_under_rect(value_picker, line_edit.get_global_rect(), get_viewport())
