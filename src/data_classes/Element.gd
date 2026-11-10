## Represents an element, either standalone (<element/>) or container (<element>...</element>).
@abstract class_name Element extends XNode

signal attribute_changed(name: String)
signal ancestor_attribute_changed(name: String)
signal descendant_attribute_changed(name: String)

var _child_elements: Array[XNode] = []
var _attributes: Dictionary[String, Array]  # Arrays are [Value (String), Current syntax (DB.AttributeSyntax), Meta (AttributeMeta)]

func _init() -> void:
	attribute_changed.connect(_on_attribute_changed)
	ancestor_attribute_changed.connect(_on_ancestor_attribute_changed)
	descendant_attribute_changed.connect(_on_descendant_attribute_changed)

func _on_attribute_changed(attribute_name: String) -> void:
	for child in get_child_xnodes():
		if child.is_element():
			child.ancestor_attribute_changed.emit(attribute_name)
	if parent != null:
		parent.descendant_attribute_changed.emit(attribute_name)
	if root != null:
		root.any_attribute_changed.emit(xid)

func _on_ancestor_attribute_changed(attribute_name: String) -> void:
	for child in get_child_xnodes():
		if child.is_element():
			child.ancestor_attribute_changed.emit(attribute_name)

func _on_descendant_attribute_changed(attribute_name: String) -> void:
	if parent != null:
		parent.descendant_attribute_changed.emit(attribute_name)


func get_child_xnodes() -> Array[XNode]:
	return _child_elements.duplicate()

func get_child(index: int) -> XNode:
	return _child_elements[index]

func has_children() -> bool:
	return not _child_elements.is_empty()

func get_child_count() -> int:
	return _child_elements.size()

func get_all_element_descendants() -> Array[Element]:
	var elements: Array[Element] = []
	for child in get_child_xnodes():
		if child.is_element():
			elements.append(child)
			elements += child.get_all_element_descendants()
	return elements

func get_all_valid_element_descendants() -> Array[Element]:
	var elements: Array[Element] = []
	for child in get_child_xnodes():
		if child.is_element() and DB.is_child_element_valid(self.name, child.name):
			elements.append(child)
			elements += child.get_all_valid_element_descendants()
	return elements

# Gets the basic XML nodes too.
func get_all_xnode_descendants() -> Array[XNode]:
	var xnodes: Array[XNode] = []
	for child in get_child_xnodes():
		xnodes.append(child)
		if child.is_element():
			xnodes += child.get_all_xnode_descendants()
	return xnodes


func replace_child(index: int, new_xnode: XNode) -> void:
	if not is_instance_valid(new_xnode):
		return
	
	var old_xnode := get_child(index)
	_child_elements[index] = new_xnode
	if new_xnode.is_element():
		for grandchild_element in new_xnode.get_child_xnodes():
			grandchild_element.parent = new_xnode
			if new_xnode is ElementSVG:
				grandchild_element.svg = new_xnode
	new_xnode.xid = old_xnode.xid
	new_xnode.parent = old_xnode.parent
	new_xnode.svg = old_xnode.svg
	new_xnode.root = old_xnode.root

func insert_child(index: int, new_xnode: XNode) -> void:
	if index < 0:
		index += get_child_count() + 1
	
	new_xnode.parent = self
	new_xnode.root = root
	new_xnode.svg = self if self is ElementSVG else svg
	
	if new_xnode is Element:
		for xnode_descendant in new_xnode.get_all_xnode_descendants():
			xnode_descendant.svg = xnode_descendant if xnode_descendant is ElementSVG else xnode_descendant.parent.svg
			xnode_descendant.root = root
	
	var new_xid := xid.duplicate()
	new_xid.append(index)
	new_xnode.xid = new_xid
	new_xnode.propagate_xid_correction()
	for i in range(index, get_child_count()):
		var child := get_child(i)
		child.xid[-1] += 1
		child.propagate_xid_correction()
	_child_elements.insert(index, new_xnode)

func remove_child(index: int) -> void:
	for i in range(index + 1, get_child_count()):
		var child := get_child(i)
		child.xid[-1] -= 1
		child.propagate_xid_correction()
	_child_elements.remove_at(index)

func pop_child(index: int) -> XNode:
	for i in range(index + 1, get_child_count()):
		var child := get_child(i)
		child.xid[-1] -= 1
		child.propagate_xid_correction()
	return _child_elements.pop_at(index)


func propagate_xid_correction() -> void:
	for i in get_child_count():
		var new_xid := xid.duplicate()
		new_xid.append(i)
		var child := get_child(i)
		child.xid = new_xid
		child.propagate_xid_correction()


func has_attribute(attribute_name: String) -> bool:
	return attribute_name in _attributes

func get_attribute_value(attribute_name: String) -> String:
	if has_attribute(attribute_name):
		return _attributes[attribute_name][0]
	return ""

func get_attribute_current_syntax(attribute_name: String) -> DB.AttributeSyntax:
	if has_attribute(attribute_name):
		return _attributes[attribute_name][1]
	return DB.AttributeSyntax.INVALID

func get_attribute_meta(attribute_name: String) -> AttributeMeta:
	if has_attribute(attribute_name):
		return _attributes[attribute_name][2]
	return null

func get_attribute_implied_value(attribute_name: String) -> String:
	if has_attribute(attribute_name):
		return _attributes[attribute_name][0]
	return get_default(attribute_name)

func get_attribute_implied_color(attribute_name: String) -> String:
	if get_attribute_current_syntax(attribute_name) != DB.AttributeSyntax.COLOR:
		push_error("Attribute not the correct type.")
		return ""
	var attrib_value := get_attribute_implied_value(attribute_name)
	if attrib_value == "currentColor":
		return get_default("color")
	return attrib_value

func get_attribute_num(attribute_name: String) -> float:
	var meta := get_attribute_meta(attribute_name)
	if not meta is AttributeMetaNumeric:
		push_error("Attribute not the correct type.")
		return 0.0
	var meta_numeric: AttributeMetaNumeric = meta
	var num := meta_numeric.get_number()
	# Possibly adjust for percentage.
	if is_attribute_percentage(attribute_name):
		var percentage_handling := get_percentage_handling(attribute_name)
		if percentage_handling == DB.PercentageHandling.BASIC:
			return num
		elif root == self:
			# TODO Implement this properly.
			match percentage_handling:
				DB.PercentageHandling.HORIZONTAL: return 1024 * num
				DB.PercentageHandling.VERTICAL: return 1024 * num
				DB.PercentageHandling.NORMALIZED: return 1024 * num
		else:
			match percentage_handling:
				DB.PercentageHandling.HORIZONTAL: return svg.viewbox.size.x * num
				DB.PercentageHandling.VERTICAL: return svg.viewbox.size.y * num
				DB.PercentageHandling.NORMALIZED: return svg.viewbox_normalized_diagonal * num
	return num

func is_attribute_percentage(attribute_name: String) -> bool:
	return get_attribute_current_syntax(attribute_name) == DB.AttributeSyntax.ARBITRARY_PERCENTAGE

func get_attribute_list(attribute_name: String) -> PackedFloat64Array:
	var meta := get_attribute_meta(attribute_name)
	if not meta is AttributeMetaList:
		push_error("Attribute not the correct type.")
		return PackedFloat64Array()
	var meta_list: AttributeMetaList = meta
	return meta_list.get_list()

func get_attribute_final_precise_transform(attribute_name: String) -> PackedFloat64Array:
	var meta := get_attribute_meta(attribute_name)
	if not meta is AttributeMetaTransformList:
		push_error("Attribute not the correct type.")
		return PackedFloat64Array()
	var meta_transform_list: AttributeMetaTransformList = meta
	return meta_transform_list.get_final_precise_transform()


# It's up to attribute fields and other specialized editing modes to give valid values here.
# Wrong values don't get discarded, only trimmed and not formatted.
func set_attribute(attribute_name: String, new_value: Variant) -> void:
	var value_type := typeof(new_value)
	
	if value_type == TYPE_STRING:
		new_value = new_value.strip_edges()  # Always strip edges before further processing.
		
		# Deal with situations where the attribute data should be cleared or added.
		var has_attrib := has_attribute(attribute_name)
		if has_attrib:
			if new_value.is_empty():
				_attributes.erase(attribute_name)
				return
		else:
			if new_value.is_empty():
				return
			else:
				# Create an initial array to be updated later in this method.
				_attributes[attribute_name] = ["", DB.AttributeSyntax.INVALID, null]
		
		var current_value := get_attribute_value(attribute_name)
		
		# Formatting can be expensive, so do this cheap check first.
		# TODO Check why this condition is true so often to begin with.
		if new_value == current_value:
			return
		
		# If matching a keyword, set to it.
		if (attribute_name in DB.ATTRIBUTE_KEYWORDS and new_value in DB.ATTRIBUTE_KEYWORDS[attribute_name]):
			if new_value != current_value:
				_attributes[attribute_name] = [new_value, DB.AttributeSyntax.INVALID, null]
			return
		
		var format_result := Configs.savedata.editor_formatter.format_attribute(attribute_name, new_value)
		var formatted_value: String = format_result[0]
		var new_syntax: DB.AttributeSyntax = format_result[1]
		_attributes[attribute_name][0] = formatted_value
		_attributes[attribute_name][1] = new_syntax
		if is_instance_valid(_attributes[attribute_name][2]):
			_attributes[attribute_name][2].sync(formatted_value)
		else:
			_attributes[attribute_name][2] = _create_attribute_meta(new_syntax, formatted_value)
	else:
		var available_syntaxes := DB.get_attribute_syntaxes(attribute_name)
		var meta := get_attribute_meta(attribute_name)
		if value_type in [TYPE_INT, TYPE_FLOAT]:
			if meta is AttributeMetaNumeric:
				var meta_numeric: AttributeMetaNumeric = meta
				var new_value_string := meta_numeric.set_number(new_value)
				_attributes[attribute_name][0] = new_value_string
			elif not is_instance_valid(meta):
				for syntax_attempt in [DB.AttributeSyntax.FRACTION, DB.AttributeSyntax.ARBITRARY_NUMERIC, DB.AttributeSyntax.POSITIVE_NUMERIC]:
					if syntax_attempt in available_syntaxes:
						var new_meta: AttributeMetaNumeric = _create_attribute_meta(syntax_attempt, "")
						var new_value_string := new_meta.set_number(new_value)
						_attributes[attribute_name][2] = new_meta
						_attributes[attribute_name][0] = new_value_string

func get_default(attribute_name: String) -> String:
	if attribute_name in DB.PROPAGATED_ATTRIBUTES:
		if is_parent_g():
			return parent.get_attribute_implied_value(attribute_name)
		elif svg != null:
			return svg.get_attribute_implied_value(attribute_name)
	return _get_own_default(attribute_name)


func duplicate(include_children := true) -> Element:
	var type: GDScript = get_script()
	var new_element: Element
	if type == ElementUnrecognized:
		new_element = ElementUnrecognized.new(self.name)
	else:
		new_element = type.new()
	
	for attribute_name in _attributes:
		new_element.set_attribute(attribute_name, get_attribute_value(attribute_name))
	
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


func get_percentage_handling(attribute_name: String) -> DB.PercentageHandling:
	if _force_use_basic_attribute_handling(attribute_name):
		return DB.PercentageHandling.BASIC
	return DB.get_attribute_default_percentage_handling(attribute_name)

func _get_own_default(_attribute_name: String) -> String:
	return ""

func _force_use_basic_attribute_handling(_attribute_name: String) -> bool:
	return false

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
		result = Utils64Bit.transforms_mult(result, get_attribute_final_precise_transform("transform"))
	return result

func get_transform() -> Transform2D:
	return Utils64Bit.get_transform(get_precise_transform())

func _create_attribute_meta(syntax: DB.AttributeSyntax, attribute_value: String) -> AttributeMeta:
	match syntax:
		DB.AttributeSyntax.FRACTION, DB.AttributeSyntax.ARBITRARY_NUMERIC, DB.AttributeSyntax.POSITIVE_NUMERIC: return AttributeMetaNumeric.new(attribute_value)
		DB.AttributeSyntax.LIST: return AttributeMetaList.new(attribute_value)
		DB.AttributeSyntax.DASHARRAY: return AttributeMetaDasharray.new(attribute_value)
		DB.AttributeSyntax.PATHDATA: return AttributeMetaPathdata.new(attribute_value)
		DB.AttributeSyntax.TRANSFORM_LIST: return AttributeMetaTransformList.new(attribute_value)
	return null
