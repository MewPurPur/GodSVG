# Represents an attribute inside an element, i.e. <element attribute="value"/>.
# If the Attribute's data type is known, one of the inheriting classes should be used.
class_name Attribute extends RefCounted

signal value_changed

var name: String
var formatter: Formatter
var _value: String

func set_value(new_value: String) -> void:
	var proposed_new_value := format(new_value)
	if proposed_new_value != _value:
		_value = proposed_new_value
		_sync()
		value_changed.emit()

func get_value() -> String:
	return _value

func _sync() -> void:
	pass

func format(text: String) -> String:
	return text

func _init(new_name: String, new_formatter: Formatter, init_value := "") -> void:
	name = new_name
	formatter = new_formatter
	set_value(init_value)
