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
	var is_width_different: bool = attributes.width.value != new_width
	var is_height_different: bool = attributes.height.value != new_height
	var is_viewbox_different: bool = attributes.viewBox.value != new_viewbox
	# Ensure the signal is not emitted unless dimensions have really changed.
	if is_width_different or is_height_different or is_viewbox_different:
		if is_width_different:
			attributes.width.value = new_width
		if is_height_different:
			attributes.height.value = new_height
		attribute_changed.emit()
