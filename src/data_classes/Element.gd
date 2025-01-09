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
		if child.is_element():
			child.ancestor_attribute_changed.emit(attribute_name)
	if parent != null:
		parent.descendant_attribute_changed.emit(attribute_name)
	if root != null:
		root.any_attribute_changed.emit(xid)

func _on_ancestor_attribute_changed(attribute_name: String) -> void:
	for child in get_children():
		if child.is_element():
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
		if child.is_element():
			elements.append(child)
			elements += child.get_all_element_descendants()
	return elements

# Gets the basic XML nodes too.
func get_all_xnode_descendants() -> Array[XNode]:
	var xnodes: Array[XNode] = []
	for child in get_children():
		xnodes.append(child)
		if child.is_element():
			xnodes += child.get_all_xnode_descendants()
	return xnodes


func replace_child(idx: int, new_xnode: XNode) -> void:
	var old_xnode := get_child(idx)
	_child_elements[idx] = new_xnode
	if new_xnode.is_element():
		for grandchild_element in new_xnode.get_children():
			grandchild_element.parent = new_xnode
			if new_xnode is ElementSVG:
				grandchild_element.svg = new_xnode
	new_xnode.xid = old_xnode.xid
	new_xnode.parent = old_xnode.parent
	new_xnode.svg = old_xnode.svg
	new_xnode.root = old_xnode.root

func insert_child(idx: int, new_xnode: XNode) -> void:
	if idx < 0:
		idx += get_child_count() + 1
	
	new_xnode.parent = self
	new_xnode.root = root
	new_xnode.svg = self if self is ElementSVG else svg
	
	if new_xnode is Element:
		for xnode_descendant in new_xnode.get_all_xnode_descendants():
			xnode_descendant.svg = xnode_descendant if xnode_descendant is ElementSVG else\
					xnode_descendant.parent.svg
			xnode_descendant.root = root
	
	var new_xid := xid.duplicate()
	new_xid.append(idx)
	new_xnode.xid = new_xid
	new_xnode.propagate_xid_correction()
	for i in range(idx, get_child_count()):
		var child := get_child(i)
		child.xid[-1] += 1
		child.propagate_xid_correction()
	_child_elements.insert(idx, new_xnode)

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
		var percentage_handling := get_percentage_handling(attribute_name)
		if percentage_handling == DB.PercentageHandling.FRACTION:
			return num
		elif root == self:
			# TODO Implement this properly.
			match percentage_handling:
				DB.PercentageHandling.HORIZONTAL: return 1024 * num
				DB.PercentageHandling.VERTICAL: return 1024 * num
				DB.PercentageHandling.NORMALIZED: return 1024 * num
		else:
			match percentage_handling:
				DB.PercentageHandling.HORIZONTAL: return svg.width * num
				DB.PercentageHandling.VERTICAL: return svg.height * num
				DB.PercentageHandling.NORMALIZED: return svg.normalized_diagonal * num
	return num

func get_attribute_true_color(attribute_name: String) -> String:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.COLOR:
		push_error("Attribute not the correct type.")
	var attrib: AttributeColor = _attributes[attribute_name] if\
			has_attribute(attribute_name) else new_default_attribute(attribute_name)
	var attrib_value := attrib.get_value()
	if attrib_value == "currentColor":
		return get_default("color")
	return attrib_value

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

func get_attribute_list(attribute_name: String) -> PackedFloat64Array:
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

func get_attribute_final_precise_transform(attribute_name: String) -> PackedFloat64Array:
	if DB.get_attribute_type(attribute_name) != DB.AttributeType.TRANSFORM_LIST:
		push_error("Attribute not the correct type.")
	var attrib: AttributeTransformList = _attributes[attribute_name] if\
			has_attribute(attribute_name) else new_default_attribute(attribute_name)
	return attrib.get_final_precise_transform()


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
				if value_type == TYPE_PACKED_FLOAT64_ARRAY: attrib.set_list(value)
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


func duplicate(include_children := true) -> Element:
	var type: GDScript = get_script()
	var new_element: Element
	if type == ElementUnrecognized:
		new_element = ElementUnrecognized.new(self.name)
	elif type == ElementRoot:
		new_element = ElementRoot.new(self.formatter)
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

# Converts a percentage numeric attribute to absolute.
# TODO this is no longer used, but might become useful again in the future.
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
		warnings.append(Translator.translate("{element} must be inside {allowed} to have any effect.").format(
				{"element": own_name, "allowed": "[%s]" % ", ".join(DB.get_valid_parents(own_name))}))
	return warnings

func user_setup(_what = null) -> void:
	return


# Helpers
func is_parent_g() -> bool:
	return parent != null and parent is ElementG


func get_precise_transform() -> PackedFloat64Array:
	var result := PackedFloat64Array([1.0, 0.0, 0.0, 1.0, 0.0, 0.0])
	if is_parent_g():
		result = Utils64Bit.transforms_mult(result, parent.get_precise_transform())
	if has_attribute("transform"):
		result = Utils64Bit.transforms_mult(result,
				get_attribute_final_precise_transform("transform"))
	return result

func get_transform() -> Transform2D:
	return Utils64Bit.get_transform(get_precise_transform())

func new_attribute(name: String, value := "") -> Attribute:
	var attrib := _create_attribute(name, value)
	attrib.value_changed.connect(_on_attribute_value_changed.bind(attrib))
	return attrib

func new_default_attribute(name: String) -> Attribute:
	return _create_attribute(name, get_default(name))

func _create_attribute(name: String, value := "") -> Attribute:
	if root != null:
		return DB.attribute(name, root.formatter, value)
	elif root == self:
		return DB.attribute(name, self.formatter, value)
	else:
		return DB.attribute(name, Formatter.new(), value)
