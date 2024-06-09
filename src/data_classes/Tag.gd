# An SVG tag, standalone (<tag/>) or container (<tag></tag>).
class_name Tag extends XNode

signal attribute_changed(name: String)
signal ancestor_attribute_changed(name: String)

var parent: Tag = null
var svg: TagSVG = null
var root: TagRoot = null

var child_tags: Array[Tag]
var attributes: Dictionary  # Dictionary{String: Attribute}

func _init() -> void:
	attribute_changed.connect(_on_attribute_changed)
	ancestor_attribute_changed.connect(_on_ancestor_attribute_changed)

func _on_attribute_changed(attribute_name: String) -> void:
	for child_tag in child_tags:
		child_tag.ancestor_attribute_changed.emit(attribute_name)
	if root != null:
		root.attribute_somewhere_changed.emit(xid)

func _on_ancestor_attribute_changed(attribute_name: String) -> void:
	for child_tag in child_tags:
		child_tag.ancestor_attribute_changed.emit(attribute_name)

func _notification(what: int) -> void:
	if what == NOTIFICATION_POSTINITIALIZE:
		root.attribute_somewhere_changed.connect(update_cache.unbind(1))
		update_cache()

func is_standalone() -> bool:
	return child_tags.is_empty()

func get_child_count() -> int:
	return child_tags.size()

func user_setup(_what = null) -> void:
	return


func get_attribute(attribute_name: String) -> Attribute:
	if attributes.has(attribute_name):
		return attributes[attribute_name]
	elif DB.propagated_attributes.has(attribute_name):
		if is_parent_g():
			return parent.get_attribute(attribute_name)
		elif svg != null:
			return svg.get_attribute(attribute_name)
	return DB.attribute(attribute_name)


func get_attribute_value(attribute_name: String, only_self := true) -> String:
	if only_self and not attributes.has(attribute_name):
		return ""
	return get_attribute(attribute_name).get_value()

func get_attribute_num(attribute_name: String) -> float:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.NUMERIC:
		push_error("Attribute not the correct type.")
	return get_attribute(attribute_name).get_num()

func get_attribute_rect(attribute_name: String) -> float:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.LIST:
		push_error("Attribute not the correct type.")
	return get_attribute(attribute_name).get_rect()

func get_attribute_list(attribute_name: String) -> PackedFloat32Array:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.LIST:
		push_error("Attribute not the correct type.")
	return get_attribute(attribute_name).get_list()

func get_attribute_commands(attribute_name: String) -> Array[PathCommand]:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.PATHDATA:
		push_error("Attribute not the correct type.")
	return get_attribute(attribute_name).get_commands()

func get_attribute_transforms(attribute_name: String) -> Array[Transform]:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.TRANSFORM_LIST:
		push_error("Attribute not the correct type.")
	return get_attribute(attribute_name).get_transform_list()


func set_attribute(attribute_name: String, value: Variant, save := true) -> void:
	var has_attribute := attributes.has(attribute_name)
	
	var attrib: Attribute
	if has_attribute:
		attrib = get_attribute(attribute_name)
	else:
		attrib = DB.attribute(attribute_name)
		attrib.value_changed.connect(update_cache.unbind(2))
		attrib.value_changed.connect(attribute_changed.emit.bind(attribute_name).unbind(2))
	
	var value_type := typeof(value)
	
	if value_type == TYPE_STRING:
		attrib.set_value(value, save)
	else:
		match DB.get_attribute_type(attribute_name):
			DB.AttributeType.NUMERIC:
				if value_type in [TYPE_FLOAT, TYPE_INT]: attrib.set_num(value, save)
				else: push_error("Invalid value set to attribute.")
			DB.AttributeType.LIST:
				if value_type in [TYPE_RECT2, TYPE_RECT2I]: attrib.set_rect(value, save)
				elif value_type == TYPE_PACKED_FLOAT32_ARRAY: attrib.set_list(value, save)
				else: push_error("Invalid value set to attribute.")
			DB.AttributeType.PATHDATA:
				if value_type == TYPE_ARRAY: attrib.set_commands(value, save)
				else: push_error("Invalid value set to attribute.")
			DB.AttributeType.TRANSFORM_LIST:
				if value_type == TYPE_ARRAY: attrib.set_commands(value, save)
				else: push_error("Invalid value set to attribute.")
			_: push_error("Invalid value set to attribute.")
	
	if has_attribute and attrib.get_value().is_empty():
		attributes.erase(attribute_name)
	elif not has_attribute and not attrib.get_value().is_empty():
		attributes[attribute_name] = attrib


func get_default(attribute_name: String) -> String:
	if attribute_name in DB.propagated_attributes:
		if is_parent_g():
			return parent.get_default(attribute_name)
		elif svg != null:
			return svg.get_default(attribute_name)
	return get_own_default(attribute_name)


# Why is there no way to duplicate RefCounteds, again?
func duplicate(include_children := true) -> Tag:
	var type: GDScript = get_script()
	var new_tag: Tag
	if type == TagUnrecognized:
		new_tag = TagUnrecognized.new(self.name)
	else:
		new_tag = type.new()
	for attribute in attributes:
		new_tag.set_attribute(attribute, attributes[attribute].get_value())
	
	if include_children:
		# Iterate this over all children.
		var new_child_tags: Array[Tag] = []
		for tag in child_tags:
			new_child_tags.append(tag.duplicate())
		new_tag.child_tags = new_child_tags
	return new_tag


# To be overridden in extending classes.
func is_parent_g() -> bool:
	return parent != null and parent is TagG

func get_own_default(_attribute_name: String) -> String:
	return ""

func update_cache() -> void:
	pass

func can_replace(_new_tag: String) -> bool:
	return false

func get_replacement(_new_tag: String) -> Tag:
	return null

func get_config_warnings() -> PackedStringArray:
	return PackedStringArray()

# Helpers
func set_parent(tag: Tag) -> void:
	parent = tag
	svg = parent if parent is TagSVG else tag.svg
	root = tag.root

func get_transform() -> Transform2D:
	var result := Transform2D.IDENTITY
	if is_parent_g():
		result *= parent.get_transform()
	if attributes.has("transform"):
		result *= attributes.transform.get_final_transform()
	return result
