# A handle that binds to one or two path parameters.
class_name PolyHandle extends Handle

const points_name = "points"
var point_index: int

func _init(new_element: Element, point_idx: int) -> void:
	element = new_element
	point_index = point_idx
	element.attribute_changed.connect(_on_attribute_changed)
	element.ancestor_attribute_changed.connect(sync.unbind(1))
	sync()

func set_pos(new_pos: PackedFloat64Array) -> void:
	if precise_pos != new_pos:
		var attrib := element.get_attribute(points_name)
		attrib.set_list_element(point_index * 2, new_pos[0])
		attrib.set_list_element(point_index * 2 + 1, new_pos[1])
		sync()

func sync() -> void:
	var list := element.get_attribute_list(points_name)
	if point_index >= list.size() / 2:
		# Handle might have been removed.
		return
	
	precise_pos[0] = list[point_index * 2]
	precise_pos[1] = list[point_index * 2 + 1]
	super()


func _on_attribute_changed(name: String) -> void:
	if name in [points_name, "transform"]:
		sync()
