## An attribute representing a number.
class_name AttributeNumeric extends Attribute

var _percentage := false
var _number := NAN

func _sync() -> void:
	if not _value.is_empty():
		_number = text_to_num(_value)
		_percentage = text_check_percentage(_value)

func set_num(new_number: float) -> void:
	_number = new_number
	super.set_value(NumberParser.num_to_text(new_number, Configs.savedata.editor_formatter))

func get_num() -> float:
	return _number

func is_percentage() -> bool:
	return _percentage


func format(text: String, formatter: Formatter) -> String:
	var num := text_to_num(text)
	if text_check_percentage(text):
		return NumberParser.num_to_text(num * 100.0, formatter) + "%"
	else:
		return NumberParser.num_to_text(num, formatter)

static func text_to_num(text: String) -> float:
	text = text.strip_edges(false, true)
	if text.is_empty():
		return NAN
	if text.ends_with("%"):
		return text.to_float() / 100
	return text.to_float()

static func text_check_percentage(text: String) -> bool:
	return text.strip_edges(false, true).ends_with("%")
