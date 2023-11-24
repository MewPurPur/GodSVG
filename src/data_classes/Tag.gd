## A SVG tag, standalone ([code]<tag/>[/code]) or container ([code]<tag></tag>[/code]).
class_name Tag extends RefCounted

var child_tags: Array[Tag]

signal attribute_changed

var name: String
var attributes: Dictionary  # Dictionary{String: Attribute}

# Attributes that aren't recognized (usually because GodSVG doesn't support them).
var unknown_attributes: Array[AttributeUnknown]

func is_standalone() -> bool:
	return child_tags.is_empty()

func _init():
	for attribute in attributes.values():
		attribute.propagate_value_changed.connect(emit_attribute_changed)

func set_unknown_attributes(attribs: Array[AttributeUnknown]) -> void:
	unknown_attributes = attribs.duplicate()
	for attribute in unknown_attributes:
		attribute.propagate_value_changed.connect(emit_attribute_changed)

func emit_attribute_changed(complete: bool):
	attribute_changed.emit(complete)

func get_child_count() -> int:
	return child_tags.size()


# Why is there no way to duplicate RefCounteds, again?
func create_duplicate() -> Tag:
	var type: GDScript = get_script()
	var new_tag: Variant
	if type == TagUnknown:
		new_tag = type.new(name)
	else:
		new_tag = type.new()
	for attribute in new_tag.attributes:
		new_tag.attributes[attribute].set_value(attributes[attribute].get_value())
	new_tag.unknown_attributes = unknown_attributes.duplicate()
	# Iterate this over all children.
	var new_child_tags: Array[Tag] = []
	for tag in child_tags:
		new_child_tags.append(tag.create_duplicate())
	new_tag.child_tags = new_child_tags
	return new_tag
