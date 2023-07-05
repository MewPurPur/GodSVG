extends Button

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

func _on_value_changed(new_value: int) -> void:
	text = str(new_value)
