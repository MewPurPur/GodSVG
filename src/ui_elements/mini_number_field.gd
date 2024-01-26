## A minimalistic editor for numbers, not tied to any attribute.
## Used for path command parameters.
extends BetterLineEdit

enum Mode {DEFAULT, ONLY_POSITIVE, ANGLE, HALF_ANGLE}
var mode := Mode.DEFAULT

signal value_changed(new_value: float)
var _value := NAN  # Must not be updated directly.

func set_value(new_value: float):
	if not is_finite(new_value):
		text = PathDataParser.num_to_text(_value)
		return
	if new_value != _value:
		_value = new_value
		text = PathDataParser.num_to_text(new_value)
		value_changed.emit(new_value)
	elif new_value == 0 and text == "-0":
		text = "0"

func get_value() -> float:
	return _value


func _on_focus_exited() -> void:
	set_value(evaluate_after_input(text))
	super()

func _on_text_submitted(submitted_text: String) -> void:
	set_value(evaluate_after_input(submitted_text))

func evaluate_after_input(eval_text: String) -> float:
	var num := AttributeNumeric.evaluate_expr(eval_text)
	match mode:
		Mode.ONLY_POSITIVE: return maxf(num, 0.0001)
		Mode.HALF_ANGLE: return fmod(num, 180.0)
		Mode.ANGLE: return fmod(num, 360.0)
		_: return num
