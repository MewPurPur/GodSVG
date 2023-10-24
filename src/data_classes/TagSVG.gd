class_name TagSVG extends TagB

func _init() -> void:
	title = "svg"
	attributes = {
		"height": Attribute.new(Attribute.Type.UFLOAT, null, 16.0),
		"width": Attribute.new(Attribute.Type.UFLOAT, null, 16.0),
		"viewBox": AttributeRect.new(null, Rect2(0, 0, 16, 16)),
	}
	super()

func set_canvas(new_width: float, new_height: float, new_viewbox: Rect2) -> void:
	var is_width_different: bool = attributes.width.get_value() != new_width
	var is_height_different: bool = attributes.height.get_value() != new_height
	var is_viewbox_different: bool = attributes.viewBox.get_value() != new_viewbox
	# Ensure the signal is not emitted unless dimensions have really changed.
	if is_width_different or is_height_different or is_viewbox_different:
		if is_width_different:
			attributes.width.set_value(new_width)
		if is_height_different:
			attributes.height.set_value(new_height)
		if is_viewbox_different:
			attributes.viewBox.set_value(new_viewbox)
		attribute_changed.emit()

func duplicate() -> TagSVG:
	var new_tagSVG = TagSVG.new()
	new_tagSVG.title = title
	var new_attributes:Dictionary
	for attribute_key in attributes:
		new_attributes[attribute_key] = attributes[attribute_key].duplicate()
	new_tagSVG.attributes = new_attributes
	var new_child_tags:Array[Tag]
	for child in child_tags:
		new_child_tags.append(child.duplicate())
	new_tagSVG.child_tags = new_child_tags
	return new_tagSVG
