# An attribute representing a number.
class_name AttributeNumeric extends Attribute

var _percentage := false
var _number := NAN

func _sync() -> void:
	if not _value.is_empty():
		_number = NumberParser.text_to_num(_value)
		_percentage = NumberParser.is_percentage(_value)

func format(text: String) -> String:
	if GlobalSettings.number_enable_autoformatting:
		return NumberParser.format_text(text)
	else:
		return text

func set_num(new_number: float) -> void:
	_number = new_number
	super.set_value(NumberParser.num_to_text(new_number) if is_finite(_number) else "")

func get_num() -> float:
	return _number

func is_percentage() -> bool:
	return _percentage
