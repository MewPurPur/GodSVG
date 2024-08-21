# A handle that binds to two numeric attributes.
class_name XYHandle extends Handle

var x_name: String
var y_name: String
var attached_handles: Array[Handle]

func _init(new_element: Element, xref: String, yref: String,
new_attached_handles: Array[Handle] = []) -> void:
	element = new_element
	x_name = xref
	y_name = yref
	attached_handles = new_attached_handles
	sync()

func set_pos(new_pos: Vector2) -> void:
	if pos != new_pos:
		element.set_attribute(x_name, new_pos.x)
		element.set_attribute(y_name, new_pos.y)
		sync()

func sync() -> void:
	pos = Vector2(element.get_attribute_num(x_name), element.get_attribute_num(y_name))
	for handle in attached_handles:
		handle.sync()
	super()
