## A handle whose x and y coordinates bind to two numeric attributes.
class_name XYHandle extends Handle

var x_name: String
var y_name: String

func _init(new_element: Element, xref: String, yref: String) -> void:
	element = new_element
	x_name = xref
	y_name = yref
	element.attribute_changed.connect(sync.unbind(1))
	element.ancestor_attribute_changed.connect(sync.unbind(1))
	sync()

func set_position(new_position: PackedFloat64Array) -> void:
	if precise_position != new_position:
		element.set_attribute(x_name, new_position[0])
		element.set_attribute(y_name, new_position[1])
		sync()

func sync() -> void:
	precise_position[0] = element.get_attribute_num(x_name)
	precise_position[1] = element.get_attribute_num(y_name)
	super()
