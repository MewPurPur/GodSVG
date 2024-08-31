# A handle that binds to a numeric attribute, relative to two other numeric attributes.
class_name DeltaHandle extends Handle

# Required.
var x_name: String
var y_name: String
var d_name: String
var horizontal: bool

func _init(new_element: Element, xref: String, yref: String, dref: String,
p_horizontal: bool) -> void:
	element = new_element
	x_name = xref
	y_name = yref
	d_name = dref
	horizontal = p_horizontal
	display_mode = Display.SMALL
	element.attribute_changed.connect(sync)
	element.ancestor_attribute_changed.connect(sync)
	sync()

func set_pos(new_pos: Vector2) -> void:
	if horizontal:
		new_pos.y = element.get_attribute_num(y_name)
	else:
		new_pos.x = element.get_attribute_num(x_name)
	
	if pos != new_pos:
		pos = new_pos
		element.set_attribute(d_name, absf(new_pos.x - element.get_attribute_num(x_name)\
				if horizontal else new_pos.y - element.get_attribute_num(y_name)))

func sync() -> void:
	if horizontal:
		pos = Vector2(element.get_attribute_num(x_name) + element.get_attribute_num(d_name),
				element.get_attribute_num(y_name))
	else:
		pos = Vector2(element.get_attribute_num(x_name),
				element.get_attribute_num(y_name) + element.get_attribute_num(d_name))
	super()
