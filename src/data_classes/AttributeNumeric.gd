# An attribute representing a number.
class_name AttributeNumeric extends Attribute

enum Unit {NONE, PERCENT, PX}  # , PT, PC, MM, CM, IN, EM, EX

var _magnitude := NAN
var _unit := Unit.NONE
var _number := NAN

func _sync() -> void:
	if not _value.is_empty():
		_number = text_to_num(_value)
		_unit = text_get_unit(_value)

func set_num(new_number: float) -> void:
	_number = new_number
	super.set_value(num_to_text(new_number))

func get_num() -> float:
	return _number

func get_magnitude() -> float:
	return _number

func get_unit() -> Unit:
	return _unit


func format(text: String) -> String:
	match text_get_unit(text):
		Unit.PERCENT: return text_get_magnitude(text) + "%"
		Unit.PX: return text_get_magnitude(text) + "px"
		_: return text.strip_edges()

func num_to_text(number: float) -> String:
	return NumberParser.num_to_text(number, formatter)

static func text_to_num(text: String) -> float:
	text = text.strip_edges()
	match text_get_unit(text):
		Unit.NONE, Unit.PX: return text_get_magnitude(text).to_float()
		Unit.PERCENT: return text_get_magnitude(text).to_float() * 0.01
		_: return NAN

static func text_get_magnitude(text: String) -> String:
	text = text.strip_edges()
	match text_get_unit(text):
		Unit.NONE: return text
		Unit.PERCENT: return text.left(-1).strip_edges(false, true)
		_: return text.left(-2).strip_edges(false, true)

static func text_get_unit(text: String) -> Unit:
	text = text.strip_edges(false, true)
	if text.ends_with("%"):
		return Unit.PERCENT
	elif text.ends_with("px"):
		return Unit.PX
	return Unit.NONE
