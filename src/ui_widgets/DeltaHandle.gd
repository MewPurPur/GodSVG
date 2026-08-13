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

func set_position(new_position: PackedFloat64Array) -> void:
	if horizontal:
		new_position[1] = element.get_attribute_num(y_name)
	else:
		new_position[0] = element.get_attribute_num(x_name)
	
	if precise_position != new_position:
		element.set_attribute(d_name, absf(new_position[0] - element.get_attribute_num(x_name) if\
				horizontal else new_position[1] - element.get_attribute_num(y_name)))
		sync()

func sync() -> void:
	if horizontal:
		precise_position[0] = element.get_attribute_num(x_name) + element.get_attribute_num(d_name)
		precise_position[1] = element.get_attribute_num(y_name)
	else:
		precise_position[0] = element.get_attribute_num(x_name)
		precise_position[1] = element.get_attribute_num(y_name) + element.get_attribute_num(d_name)
	super()
