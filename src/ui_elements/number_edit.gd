## A number editor, not tied to any attribute.
extends BetterLineEdit

@export var min_value := 0.0
@export var max_value := 1.0
@export var initial_value := 0.5
@export var allow_lower := true
@export var allow_higher := true
@export var is_float := true

signal value_changed(new_value: float)
var _value := NAN

func set_value(new_value: float, emit_changed := true) -> void:
	if not is_finite(new_value):
		text = String.num(_value, 4)
		return
	elif _value != new_value:
		if allow_lower:
			if allow_higher:
				_value = new_value
			else:
				_value = minf(new_value, max_value)
		else:
			if allow_higher:
				_value = maxf(new_value, min_value)
			else:
				_value = clampf(new_value, min_value, max_value)
		text = String.num(_value, 4)
		if emit_changed:
			value_changed.emit(_value)

func get_value() -> float:
	return _value


func _ready() -> void:
	super()
	# Done like this so a signal isn't emitted.
	_value = initial_value
	text = String.num(_value, 4)

func _on_value_changed(new_value: float) -> void:
	text = String.num(new_value, 4)


func _on_focus_exited() -> void:
	set_value(AttributeNumeric.evaluate_numeric_expression(text))
	super()

func _on_text_submitted(submitted_text: String) -> void:
	set_value(AttributeNumeric.evaluate_numeric_expression(submitted_text))
