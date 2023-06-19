extends HBoxContainer

var attribute: SVGAttribute
var attribute_name: String

@onready var command_picker: Popup = $PathPopup

signal value_changed(new_value: String)
var value: String:
	set(new_value):
		var old_value := value
		if value != old_value:
			value_changed.emit(new_value)


func _on_button_pressed() -> void:
	command_picker.popup(Rect2(global_position + Vector2(0, size.y), size))

func _on_path_command_picked(new_command: String) -> void:
	value = new_command
