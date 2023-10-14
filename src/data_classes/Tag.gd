class_name Tag extends RefCounted

signal attribute_changed

var title: String
var attributes: Dictionary  # Dictionary{String: Attribute}

func _init():
	for attribute in attributes.values():
		attribute.value_changed.connect(emit_attribute_changed)

func emit_attribute_changed(_new_value: Variant):
	attribute_changed.emit()
