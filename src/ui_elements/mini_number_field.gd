## A minimalistic editor for numbers, not tied to any attribute.
## Used for path command parameters.
extends BetterLineEdit

enum Mode {DEFAULT, ONLY_POSITIVE, ANGLE}
var mode := Mode.DEFAULT

signal value_changed(new_value: float)
var _value: float  # Must not be updated directly.

func set_value(new_value: float):
	if not is_finite(new_value):
		text = String.num(_value, 4)
		return
	var old_value := _value
	_value = validate(new_value)
	text = String.num(_value, 4)
	if _value != old_value:
		value_changed.emit(_value)

func get_value() -> float:
	return _value


func _ready() -> void:
	super()
	value_changed.connect(_on_value_changed)

func validate(new_value: float) -> float:
	match mode:
		Mode.ONLY_POSITIVE: return maxf(new_value, 0.0001)
		Mode.ANGLE: return fmod(new_value, 180.0)
		_: return new_value

func _on_value_changed(new_value: float) -> void:
	text = String.num(new_value, 4)


func _on_focus_exited() -> void:
	set_value(AttributeNumeric.evaluate_numeric_expression(text))
	super()

func _on_text_submitted(submitted_text: String) -> void:
	set_value(AttributeNumeric.evaluate_numeric_expression(submitted_text))
