# An attribute representing a number.
class_name AttributeNumeric extends Attribute

var _percentage := false
var _number := NAN

func _sync() -> void:
	if not _value.is_empty():
		_number = text_to_num(_value)
		_percentage = _value.strip_edges().ends_with("%")

func set_num(new_number: float) -> void:
	_number = new_number
	super.set_value(num_to_text(new_number))

func get_num() -> float:
	return _number

func is_percentage() -> bool:
	return _percentage


func num_to_text(number: float) -> String:
	return NumberParser.num_to_text(number, formatter)

static func text_to_num(text: String) -> float:
	text = text.strip_edges()
	if text.is_empty():
		return NAN
	if text.ends_with("%"):
		return text.to_float() / 100
	return text.to_float()
