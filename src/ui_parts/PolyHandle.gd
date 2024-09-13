# A handle that binds to one or two path parameters.
class_name PolyHandle extends Handle

const points_name = "points"
var point_index: int

func _init(new_element: Element, point_idx: int) -> void:
	element = new_element
	point_index = point_idx
	element.attribute_changed.connect(sync.unbind(1))
	element.ancestor_attribute_changed.connect(sync.unbind(1))
	sync()

func set_pos(new_pos: Vector2) -> void:
	if pos != new_pos:
		var attrib := element.get_attribute(points_name)
		attrib.set_list_element(point_index * 2, new_pos.x)
		attrib.set_list_element(point_index * 2 + 1, new_pos.y)
		sync()

func sync() -> void:
	pos = element.get_attribute(points_name).get_points()[point_index]
	super()
