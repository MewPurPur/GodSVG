# Represents an attribute inside a tag, i.e. <tag attribute="value"/>.
# If the Attribute's data type is known, one of the inheriting classes should be used.
class_name Attribute extends RefCounted

signal value_changed(changed: bool, save_changed: bool)

var name: String
var _value: String
var _saved_value: String  # Value that is stored in UndoRedo.

func set_value(new_value: String, save := true) -> void:
	var proposed_new_value := format(new_value)
	var changed := false
	var saved_changed := false
	if proposed_new_value != _value:
		_value = proposed_new_value
		changed = true
		_sync()
	if save and proposed_new_value != _saved_value:
		_saved_value = proposed_new_value
		saved_changed = true
	value_changed.emit(changed, saved_changed)

func get_value() -> String:
	return _value

func _sync() -> void:
	pass

func format(text: String) -> String:
	return text

func _init(new_name: String, init_value := "") -> void:
	name = new_name
	set_value(init_value)
