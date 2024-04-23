class_name Tag extends RefCounted
## A SVG tag, standalone ([code]<tag/>[/code]) or container ([code]<tag></tag>[/code]).

var child_tags: Array[Tag]

signal attribute_changed(undo_redo: bool)

var attributes: Dictionary  # Dictionary{String: Attribute}

# Attributes that aren't recognized (usually because GodSVG doesn't support them).
var unknown_attributes: Array[AttributeUnknown]

func is_standalone() -> bool:
	return child_tags.is_empty()

func _init() -> void:
	for attribute: Attribute in attributes.values():
		attribute.propagate_value_changed.connect(emit_attribute_changed)

func set_unknown_attributes(attribs: Array[AttributeUnknown]) -> void:
	unknown_attributes = attribs.duplicate()
	for attribute in unknown_attributes:
		attribute.propagate_value_changed.connect(emit_attribute_changed)

func emit_attribute_changed(undo_redo: bool) -> void:
	attribute_changed.emit(undo_redo)

func get_child_count() -> int:
	return child_tags.size()


# Why is there no way to duplicate RefCounteds, again?
func create_duplicate() -> Tag:
	var new_tag := create_duplicate_without_children()
	
	# Iterate this over all children.
	var new_child_tags: Array[Tag] = []
	for tag in child_tags:
		new_child_tags.append(tag.create_duplicate())
	new_tag.child_tags = new_child_tags
	return new_tag

func create_duplicate_without_children() -> Tag:
	var type: GDScript = get_script()
	var new_tag: Tag
	if type == TagUnknown:
		new_tag = TagUnknown.new(self.name)
	else:
		new_tag = type.new()
	for attribute in new_tag.attributes:
		new_tag.attributes[attribute].set_value(attributes[attribute].get_value())
	var unknown_attributes_array: Array[AttributeUnknown] = []
	for attribute in unknown_attributes:
		var new_attrib := AttributeUnknown.new(attribute.name)
		new_attrib.set_value(attribute.get_value())
		unknown_attributes_array.append(new_attrib)
	new_tag.set_unknown_attributes(unknown_attributes_array)
	return new_tag

# To be overridden in extending classes.
func can_replace(_new_tag: String) -> bool:
	return false

func get_replacement(_new_tag: String) -> Tag:
	return null
