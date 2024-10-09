# An SVG element, standalone (<element/>) or container (<element>...</element>).
class_name Element extends XNode

signal attribute_changed(name: String)
signal ancestor_attribute_changed(name: String)
signal descendant_attribute_changed(name: String)

var _child_elements: Array[XNode]
var _attributes: Dictionary  # Dictionary{String: Attribute}

func _init() -> void:
	attribute_changed.connect(_on_attribute_changed)
	ancestor_attribute_changed.connect(_on_ancestor_attribute_changed)
	descendant_attribute_changed.connect(_on_descendant_attribute_changed)

func _on_attribute_changed(attribute_name: String) -> void:
	for child in get_children():
		if child is Element:
			child.ancestor_attribute_changed.emit(attribute_name)
	if parent != null:
		parent.descendant_attribute_changed.emit(attribute_name)
	if root != null:
		root.any_attribute_changed.emit(xid)

func _on_ancestor_attribute_changed(attribute_name: String) -> void:
	for child in get_children():
		child.ancestor_attribute_changed.emit(attribute_name)

func _on_descendant_attribute_changed(attribute_name: String) -> void:
	if parent != null:
		parent.descendant_attribute_changed.emit(attribute_name)

func _on_attribute_value_changed(attribute: Attribute) -> void:
	var has_attrib := has_attribute(attribute.name)
	if has_attrib and _attributes[attribute.name].get_value().is_empty():
		_attributes.erase(attribute.name)
	elif not has_attrib:
		_attributes[attribute.name] = attribute
	attribute_changed.emit(attribute.name)


func get_children() -> Array[XNode]:
	return _child_elements.duplicate()

func get_child(idx: int) -> XNode:
	return _child_elements[idx]

func has_children() -> bool:
	return not _child_elements.is_empty()

func get_child_count() -> int:
	return _child_elements.size()

func get_all_element_descendants() -> Array[Element]:
	var elements: Array[Element] = []
	for child in get_children():
		if child is Element:
			elements.append(child)
			elements += child.get_all_element_descendants()
	return elements

func get_all_xnode_descendants() -> Array[XNode]:
	var xnodes: Array[XNode] = []
	for child in get_children():
		xnodes.append(child)
		if child is Element:
			xnodes += child.get_all_xnode_descendants()
	return xnodes


func replace_child(idx: int, new_element: XNode) -> void:
	var old_element := get_child(idx)
	_child_elements[idx] = new_element
	if new_element is Element:
		for grandchild_element in new_element.get_children():
			grandchild_element.parent = new_element
			if new_element is ElementSVG:
				grandchild_element.svg = new_element
	new_element.xid = old_element.xid
	new_element.parent = old_element.parent
	new_element.svg = old_element.svg
	new_element.root = old_element.root

func insert_child(idx: int, new_element: XNode) -> void:
	if idx < 0:
		idx += get_child_count() + 1
	new_element.parent = self
	new_element.root = root
	new_element.svg = self if self is ElementSVG else svg
	var new_xid := xid.duplicate()
	new_xid.append(idx)
	new_element.xid = new_xid
	new_element.propagate_xid_correction()
	for i in range(idx, get_child_count()):
		var child := get_child(i)
		child.xid[-1] += 1
		child.propagate_xid_correction()
	_child_elements.insert(idx, new_element)

func remove_child(idx: int) -> void:
	for i in range(idx + 1, get_child_count()):
		var child := get_child(i)
		child.xid[-1] -= 1
		child.propagate_xid_correction()
	_child_elements.remove_at(idx)

func pop_child(idx: int) -> XNode:
	for i in range(idx + 1, get_child_count()):
		var child := get_child(i)
		child.xid[-1] -= 1
		child.propagate_xid_correction()
	return _child_elements.pop_at(idx)


func propagate_xid_correction() -> void:
	for i in get_child_count():
		var new_xid := xid.duplicate()
		new_xid.append(i)
		var child := get_child(i)
		child.xid = new_xid
		child.propagate_xid_correction()


func has_attribute(attribute_name: String) -> bool:
	return _attributes.has(attribute_name)

# If the attribute exists, gets that attribute. If it doesn't, generates it.
func get_attribute(attribute_name: String) -> Attribute:
	if has_attribute(attribute_name):
		return _attributes[attribute_name]
	return new_attribute(attribute_name)


# "real" determines if we want the true value or fallback on defaults.
func get_attribute_value(attribute_name: String, real := false) -> String:
	if has_attribute(attribute_name):
		return _attributes[attribute_name].get_value()
	if real:
		return ""
	return get_default(attribute_name)

func get_attribute_num(attribute_name: String) -> float:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.NUMERIC:
		push_error("Attribute not the correct type.")
	var attrib: AttributeNumeric = _attributes[attribute_name] if\
			has_attribute(attribute_name) else new_default_attribute(attribute_name)
	# Possibly adjust for percentage.
	var num := attrib.get_num()
	if attrib.is_percentage():
		match get_percentage_handling(attribute_name):
			DB.PercentageHandling.FRACTION: return num
			DB.PercentageHandling.HORIZONTAL: return svg.width * num
			DB.PercentageHandling.VERTICAL: return svg.height * num
			DB.PercentageHandling.NORMALIZED: return svg.normalized_diagonal * num
	return num

func is_attribute_percentage(attribute_name: String) -> bool:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.NUMERIC:
		push_error("Attribute not the correct type.")
	var attrib: AttributeNumeric = _attributes[attribute_name] if\
			has_attribute(attribute_name) else new_default_attribute(attribute_name)
	return attrib.is_percentage()

func get_attribute_rect(attribute_name: String) -> float:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.LIST:
		push_error("Attribute not the correct type.")
	var attrib: AttributeList = _attributes[attribute_name] if\
			has_attribute(attribute_name) else new_default_attribute(attribute_name)
	return attrib.get_rect()

func get_attribute_list(attribute_name: String) -> PackedFloat32Array:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.LIST:
		push_error("Attribute not the correct type.")
	var attrib: AttributeList = _attributes[attribute_name] if\
			has_attribute(attribute_name) else new_default_attribute(attribute_name)
	return attrib.get_list()

func get_attribute_commands(attribute_name: String) -> Array[PathCommand]:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.PATHDATA:
		push_error("Attribute not the correct type.")
	var attrib: AttributePathdata = _attributes[attribute_name] if\
			has_attribute(attribute_name) else new_default_attribute(attribute_name)
	return attrib.get_commands()

func get_attribute_transforms(attribute_name: String) -> Array[Transform]:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.TRANSFORM_LIST:
		push_error("Attribute not the correct type.")
	var attrib: AttributeTransformList = _attributes[attribute_name] if\
			has_attribute(attribute_name) else new_default_attribute(attribute_name)
	return attrib.get_transform_list()

func get_attribute_final_transform(attribute_name: String) -> Transform2D:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.TRANSFORM_LIST:
		push_error("Attribute not the correct type.")
	var attrib: AttributeTransformList = _attributes[attribute_name] if\
			has_attribute(attribute_name) else new_default_attribute(attribute_name)
	return attrib.get_final_transform()


func set_attribute(attribute_name: String, value: Variant) -> void:
	var attrib: Attribute
	if has_attribute(attribute_name):
		attrib = _attributes[attribute_name]
	else:
		attrib = new_attribute(attribute_name)
	
	var value_type := typeof(value)
	
	if value_type == TYPE_STRING:
		attrib.set_value(value)
	else:
		match DB.get_attribute_type(attribute_name):
			DB.AttributeType.NUMERIC:
				if value_type in [TYPE_FLOAT, TYPE_INT]: attrib.set_num(value)
				else: push_error("Invalid value set to attribute.")
			DB.AttributeType.LIST:
				if value_type in [TYPE_RECT2, TYPE_RECT2I]: attrib.set_rect(value)
				elif value_type == TYPE_PACKED_FLOAT32_ARRAY: attrib.set_list(value)
				else: push_error("Invalid value set to attribute.")
			DB.AttributeType.PATHDATA:
				if value_type == TYPE_ARRAY: attrib.set_commands(value)
				else: push_error("Invalid value set to attribute.")
			DB.AttributeType.TRANSFORM_LIST:
				if value_type == TYPE_ARRAY: attrib.set_transform_list(value)
				else: push_error("Invalid value set to attribute.")
			_:
				push_error("Invalid value set to attribute.")

func get_default(attribute_name: String) -> String:
	if attribute_name in DB.propagated_attributes:
		if is_parent_g():
			return parent.get_attribute_value(attribute_name)
		elif svg != null:
			return svg.get_attribute_value(attribute_name)
	return _get_own_default(attribute_name)

func get_all_attributes() -> Array:
	return _attributes.values()


# Why is there no way to duplicate RefCounteds, again?
func duplicate(include_children := true) -> Element:
	var type: GDScript = get_script()
	var new_element: Element
	if type == ElementUnrecognized:
		new_element = ElementUnrecognized.new(self.name)
	else:
		new_element = type.new()
	
	if type == ElementRoot:
		new_element.formatter = self.formatter
	
	for attribute in _attributes:
		new_element.set_attribute(attribute, get_attribute_value(attribute))
	
	if include_children:
		for i in get_child_count():
			new_element.insert_child(i, get_child(i).duplicate())
	return new_element

# Applies children and attributes to another element. Useful for conversion.
func apply_to(element: Element, dropped_attributes: PackedStringArray) -> void:
	element._child_elements = _child_elements
	for attribute_name in _attributes:
		if not attribute_name in dropped_attributes:
			element.set_attribute(attribute_name, get_attribute_value(attribute_name))

# Converts all percentage numeric attributes to absolute.
func make_all_attributes_absolute() -> void:
	var attributes_to_convert := _attributes.keys()
	if DB.recognized_attributes.has(self.name):
		attributes_to_convert += DB.recognized_attributes[self.name]
	for attribute_name in attributes_to_convert:
		if DB.get_attribute_type(attribute_name) == DB.AttributeType.NUMERIC:
			make_attribute_absolute(attribute_name)

# Converts a percentage numeric attribute to absolute.
func make_attribute_absolute(attribute_name: String) -> void:
	if is_attribute_percentage(attribute_name):
		var new_attrib := new_attribute(attribute_name)
		new_attrib.set_num(get_attribute_num(attribute_name))
		_attributes[attribute_name] = new_attrib


# To be overridden in extending classes.
func _get_own_default(_attribute_name: String) -> String:
	return ""

func get_percentage_handling(attribute_name: String) -> DB.PercentageHandling:
	return DB.get_attribute_default_percentage_handling(attribute_name)

func can_replace(_new_element: String) -> bool:
	return false

func get_replacement(_new_element: String) -> Element:
	return null

func get_config_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var own_name: String = self.name
	if parent != null and not DB.is_child_element_valid(parent.name, own_name):
		warnings.append(TranslationServer.translate("{element} must be inside {allowed} to have any effect.").format(
				{"element": own_name, "allowed": "[%s]" % ", ".join(DB.get_valid_parents(own_name))}))
	return warnings

func user_setup(_what = null) -> void:
	return


# Helpers
func is_parent_g() -> bool:
	return parent != null and parent is ElementG

func get_transform() -> Transform2D:
	var result := Transform2D.IDENTITY
	if is_parent_g():
		result *= parent.get_transform()
	if has_attribute("transform"):
		result *= get_attribute_final_transform("transform")
	return result

func new_attribute(name: String, value := "") -> Attribute:
	var attrib := _create_attribute(name, value)
	attrib.value_changed.connect(_on_attribute_value_changed.bind(attrib))
	return attrib

func new_default_attribute(name: String) -> Attribute:
	return _create_attribute(name, get_default(name))

func _create_attribute(name: String, value := "") -> Attribute:
	return DB.attribute(name, root.formatter if root != null else Formatter.new(), value)
