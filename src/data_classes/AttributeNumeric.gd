## An attribute representing a number.
class_name AttributeNumeric extends Attribute

var _number: float
enum Mode {FLOAT, UFLOAT, NFLOAT}  # UFLOAT is positive-only, NFLOAT is in [0, 1].
var mode := Mode.FLOAT

func _init(new_mode: Mode, new_default: String, new_init := "") -> void:
	mode = new_mode
	default = new_default
	set_value(new_init if !new_init.is_empty() else new_default, SyncMode.SILENT)

func _sync() -> void:
	if get_value().is_empty():
		_number = NAN
	else:
		_number = get_value().to_float()

func set_num(new_number: float, sync_mode := SyncMode.LOUD) -> void:
	_number = new_number
	super.set_value(String.num(new_number, 4) if is_finite(_number) else "", sync_mode)

func get_num() -> float:
	return _number


static func num_to_text(number: float) -> String:
	return String.num(number, 4)

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
