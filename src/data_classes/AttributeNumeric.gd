# An attribute representing a number.
class_name AttributeNumeric extends Attribute

var _percentage := false
var _number := NAN

func set_value(new_value: String) -> void:
	var proposed_num := text_to_num(new_value)
	var proposed_percentage_state := text_check_percentage(new_value)
	var proposed_value := ""
	if proposed_percentage_state:
		proposed_value = num_to_text(proposed_num * 100.0) + "%"
	else:
		proposed_value = num_to_text(proposed_num)
	if proposed_value != _value:
		_value = proposed_value
		if not _value.is_empty():
			_number = proposed_num
			_percentage = proposed_percentage_state
		value_changed.emit()

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

func text_check_percentage(text: String) -> bool:
	return text.strip_edges().ends_with("%")
