extends Button

# Flags don't show up in any supported attributes, so it's not an AttributeEditor.

signal value_changed(new_value: int)
var value: int:
	set(new_value):
		if value != new_value:
			value = new_value
			value_changed.emit(new_value)


func _on_toggled(is_state_pressed: bool) -> void:
	value = 1 if is_state_pressed else 0

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	button_pressed = value == 1
	text = str(value)

func _on_value_changed(new_value: int) -> void:
	button_pressed = new_value == 1
	text = str(new_value)
