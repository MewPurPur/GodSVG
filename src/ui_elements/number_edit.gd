## A number editor, not tied to any attribute.
extends BetterLineEdit

@export var min_value := 0.0
@export var max_value := 1.0
@export var allow_lower := true
@export var allow_higher := true
@export var is_float := true
@export var auto_emit_changed := true

signal value_changed(new_value: float)
var current_value := NAN:
	set(new_value):
		if is_nan(new_value):
			return
		elif current_value != new_value:
			current_value = validate(new_value)
			text = String.num(current_value, 4)
			if auto_emit_changed:
				value_changed.emit(new_value)


func validate(new_value: float) -> float:
	if allow_lower:
		if allow_higher:
			return new_value
		else:
			return minf(new_value, max_value)
	else:
		if allow_higher:
			return maxf(new_value, min_value)
		else:
			return clampf(new_value, min_value, max_value)

func _on_value_changed(new_value: float) -> void:
	text = String.num(new_value, 4)


func _on_focus_exited() -> void:
	force_value(Utils.evaluate_numeric_expression(text))

func _on_text_submitted(submitted_text: String) -> void:
	force_value(Utils.evaluate_numeric_expression(submitted_text))

func force_value(new_value: float) -> void:
	current_value = new_value
	if not auto_emit_changed:
		value_changed.emit(new_value)
