## An attribute representing a number.
class_name AttributeNumeric extends Attribute

enum Mode {FLOAT, UFLOAT, NFLOAT}  # UFLOAT is positive-only, NFLOAT is in [0, 1].
var mode := Mode.FLOAT

func _init(new_mode: Mode, new_default: float = NAN, new_init: float = NAN) -> void:
	mode = new_mode
	default = new_default
	set_value(new_init if !is_nan(new_init) else new_default, SyncMode.SILENT)


# This function evaluates expressions even if "," or ";" is used as a decimal separator.
static func evaluate_numeric_expression(text: String) -> float:
	var expr := Expression.new()
	var err := expr.parse(text.replace(",", "."))
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed():
			return result
	err = expr.parse(text.replace(";", "."))
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed():
			return result
	err = expr.parse(text)
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed():
			return result
	return NAN
