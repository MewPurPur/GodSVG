# Represents an attribute inside an element, i.e. <element attribute="value"/>.
# If the Attribute's data type is known, one of the inheriting classes should be used.
class_name Attribute extends RefCounted

signal value_changed

var name: String
var formatter: Formatter
var _value: String

# Expected to be overridden.
func set_value(new_value: String) -> void:
	var proposed_new_value = new_value.strip_edges()
	if proposed_new_value != _value:
		_value = proposed_new_value
		value_changed.emit()

func get_value() -> String:
	return _value

func _init(new_name: String, new_formatter: Formatter, init_value := "") -> void:
	name = new_name
	formatter = new_formatter
	set_value(init_value)
