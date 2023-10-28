class_name Tag extends RefCounted

signal attribute_changed

var title: String
var attributes: Dictionary  # Dictionary{String: Attribute}

# Attributes that aren't recognized (usually because GodSVG doesn't support them).
var unknown_attributes: Array[AttributeUnknown]

func _init():
	for attribute in attributes.values():
		attribute.propagate_value_changed.connect(emit_attribute_changed)

func set_unknown_attributes(attribs: Array[AttributeUnknown]) -> void:
	unknown_attributes = attribs.duplicate()
	for attribute in unknown_attributes:
		attribute.propagate_value_changed.connect(emit_attribute_changed)

func emit_attribute_changed():
	attribute_changed.emit()
