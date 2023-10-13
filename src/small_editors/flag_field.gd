extends Button

# Flags don't show up in any supported attributes, so it's not an AttributeEditor.

signal value_changed(new_value: int)
var _value: int

func set_value(new_value: int, emit_value_changed := true):
	if _value != new_value:
		_value = new_value
		if emit_value_changed:
			value_changed.emit(new_value)

func get_value() -> int:
	return _value


func _on_toggled(is_state_pressed: bool) -> void:
	set_value(1 if is_state_pressed else 0)

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	button_pressed = (get_value() == 1)
	text = str(get_value())

func _on_value_changed(new_value: int) -> void:
	button_pressed = new_value == 1
	text = str(new_value)
