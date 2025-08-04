# A minimalistic numeric editor, not tied to an attribute.
extends BetterLineEdit

enum Mode {DEFAULT, ONLY_POSITIVE, ANGLE, HALF_ANGLE}
var mode := Mode.DEFAULT

signal value_changed(new_value: float)
var _value := NAN  # Must not be updated directly.

var default := NAN  # Setting to an empty value would bring you back to the default.

func _ready() -> void:
	text_submitted.connect(_on_text_submitted)

func set_value(new_value: float, no_signal := false) -> void:
	if not is_finite(new_value):
		text = NumstringParser.basic_num_to_text(_value, mode == Mode.ANGLE or mode == Mode.HALF_ANGLE)
		return
	text = NumstringParser.basic_num_to_text(new_value, mode == Mode.ANGLE or mode == Mode.HALF_ANGLE)
	if new_value != _value:
		_value = new_value
		if not no_signal:
			value_changed.emit(new_value)

func get_value() -> float:
	return _value


func _on_text_submitted(submitted_text: String) -> void:
	if not is_nan(default) and submitted_text.strip_edges().is_empty():
		set_value(default)
	else:
		set_value(evaluate_after_input(submitted_text))

func evaluate_after_input(eval_text: String) -> float:
	var num := NumstringParser.evaluate(eval_text)
	match mode:
		Mode.ONLY_POSITIVE: return maxf(absf(num), 0.1 ** Utils.MAX_NUMERIC_PRECISION)
		Mode.HALF_ANGLE: return fmod(num, 180.0)
		Mode.ANGLE: return fmod(num, 360.0)
		_: return num
