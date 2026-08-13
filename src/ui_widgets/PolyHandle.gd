# A handle that binds to one or two path parameters.
class_name PolyHandle extends Handle

const points_name = "points"
var point_index: int

func _init(new_element: Element, new_point_index: int) -> void:
	element = new_element
	point_index = new_point_index
	element.attribute_changed.connect(_on_attribute_changed)
	element.ancestor_attribute_changed.connect(sync.unbind(1))
	sync()

func set_position(new_position: PackedFloat64Array) -> void:
	if precise_position != new_position:
		var attrib := element.get_attribute(points_name)
		attrib.set_list_element(point_index * 2, new_position[0])
		attrib.set_list_element(point_index * 2 + 1, new_position[1])
		sync()

func sync() -> void:
	var list := element.get_attribute_list(points_name)
	if point_index >= list.size() / 2:
		# Handle might have been removed.
		return
	
	precise_position[0] = list[point_index * 2]
	precise_position[1] = list[point_index * 2 + 1]
	super()


func _on_attribute_changed(name: String) -> void:
	if name in [points_name, "transform"]:
		sync()
