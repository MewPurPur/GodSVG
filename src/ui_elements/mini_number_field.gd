## A minimalistic numeric editor, not tied to an attribute.
extends BetterLineEdit

enum Mode {DEFAULT, ONLY_POSITIVE, ANGLE, HALF_ANGLE}
var mode := Mode.DEFAULT

signal value_changed(new_value: float)
var _value := NAN  # Must not be updated directly.

func set_value(new_value: float, no_signal := false):
	if not is_finite(new_value):
		text = NumberArrayParser.basic_num_to_text(_value)
		return
	text = NumberArrayParser.basic_num_to_text(new_value)
	if new_value != _value:
		_value = new_value
		if not no_signal:
			value_changed.emit(new_value)

func get_value() -> float:
	return _value


func _on_text_submitted(submitted_text: String) -> void:
	set_value(evaluate_after_input(submitted_text))

func evaluate_after_input(eval_text: String) -> float:
	var num := AttributeNumeric.evaluate_expr(eval_text)
	match mode:
		Mode.ONLY_POSITIVE: return maxf(num, 0.0001)
		Mode.HALF_ANGLE: return fmod(num, 180.0)
		Mode.ANGLE: return fmod(num, 360.0)
		_: return num
