## Represents an attribute inside an element, i.e. <element attribute="value"/>.
## If the Attribute's data type is known, one of the inheriting classes should be used.
## By default uses the editor formatter.
class_name Attribute

signal value_changed

var name: String
var _value: String

func set_value(new_value: String) -> void:
	# Formatting can be expensive, so do this cheap check first.
	if new_value == _value:
		return
	var proposed_new_value := format(new_value, Configs.savedata.editor_formatter)
	if proposed_new_value != _value:
		_value = proposed_new_value
		_sync()
		value_changed.emit()

func get_value() -> String:
	return _value

func get_formatted_value(formatter: Formatter) -> String:
	return format(_value, formatter)

func _sync() -> void:
	pass

func format(text: String, _formatter: Formatter) -> String:
	return text

func _init(new_name: String, init_value := "") -> void:
	name = new_name
	set_value(init_value)
