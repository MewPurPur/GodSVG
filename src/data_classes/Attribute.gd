# Represents an attribute inside an element, i.e. <element attribute="value"/>.
# If the Attribute's data type is known, one of the inheriting classes should be used.
class_name Attribute extends RefCounted

signal value_changed

var name: String
var _value: String

func set_value(new_value: String) -> void:
	# Formatting can be expensive, so do this cheap check first.
	if new_value == _value:
		return
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
	return _format(text, Configs.savedata.editor_formatter)

func get_export_value() -> String:
	return _format(_value, Configs.savedata.export_formatter)

func _format(text: String, _formatter: Formatter) -> String:
	return text

func _init(new_name: String, init_value := "") -> void:
	name = new_name
	set_value(init_value)
