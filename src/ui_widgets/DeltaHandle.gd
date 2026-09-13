# A handle that binds to a numeric attribute, relative to two other numeric attributes.
class_name DeltaHandle extends Handle

# Required.
var x_name: String
var y_name: String
var d_name: String
var horizontal: bool

func _init(new_element: Element, xref: String, yref: String, dref: String, p_horizontal: bool) -> void:
	element = new_element
	x_name = xref
	y_name = yref
	d_name = dref
	horizontal = p_horizontal
	display_mode = Display.SMALL
	element.attribute_changed.connect(sync.unbind(1))
	element.ancestor_attribute_changed.connect(sync.unbind(1))
	sync()

func set_position(new_position: Vector2, snap_size: float) -> void:
	var x_pos := element.get_attribute_num(x_name)
	var y_pos := element.get_attribute_num(y_name)
	if horizontal:
		var final_position := apply_restrictions(new_position, snap_size, [PackedFloat64Array([x_pos, y_pos, x_pos + 1, y_pos])])
		if precise_position != final_position:
			element.set_attribute(d_name, absf(final_position[0] - element.get_attribute_num(x_name)))
	else:
		var final_position := apply_restrictions(new_position, snap_size, [PackedFloat64Array([x_pos, y_pos, x_pos, y_pos + 1])])
		if precise_position != final_position:
			element.set_attribute(d_name, absf(final_position[1] - element.get_attribute_num(y_name)))
	sync()

func sync() -> void:
	precise_position = [element.get_attribute_num(x_name), element.get_attribute_num(y_name)]
	precise_position[0 if horizontal else 1] += element.get_attribute_num(d_name)
	super()
