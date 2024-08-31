# A handle that binds to two numeric attributes.
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

func set_pos(new_pos: Vector2) -> void:
	if pos != new_pos:
		element.set_attribute(x_name, new_pos.x)
		element.set_attribute(y_name, new_pos.y)
		sync()

func sync() -> void:
	pos = Vector2(element.get_attribute_num(x_name), element.get_attribute_num(y_name))
	super()
