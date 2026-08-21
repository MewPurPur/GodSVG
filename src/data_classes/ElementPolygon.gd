## A <polygon> element.
class_name ElementPolygon extends Element

const name = "polygon"
const possible_conversions: PackedStringArray = ["path", "rect"]

func user_setup(precise_position := PackedFloat64Array([0.0, 0.0])) -> void:
	if precise_position != PackedFloat64Array([0.0, 0.0]):
		get_attribute("points").set_list(precise_position)

func _get_own_default(attribute_name: String) -> String:
	if attribute_name == "opacity":
		return "1"
	return ""

func get_bounding_box() -> Rect2:
	if not has_attribute("points"):
		return Rect2()
	
	var list: AttributeList = get_attribute("points")
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	
	for i in range(0, list.get_list_size(), 2):
		var x_coord := list.get_list_element(i)
		var y_coord := list.get_list_element(i + 1)
		min_x = minf(min_x, x_coord)
		max_x = maxf(max_x, x_coord)
		min_y = minf(min_y, y_coord)
		max_y = maxf(max_y, y_coord)
	
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


func can_replace(new_element: String) -> bool:
	if new_element == "rect":
		var optimized_polygon := duplicate()
		optimized_polygon.simplify()
		var list: PackedFloat64Array = optimized_polygon.get_attribute_list("points")
		if list.size() != 8:
			return false
		# Do the x or y coordinates match between opposite pairs of points?
		return (list[0] == list[2] and list[3] == list[5] and list[4] == list[6] and list[7] == list[1]) or\
				(list[1] == list[3] and list[2] == list[4] and list[5] == list[7] and list[6] == list[0])
	else:
		return new_element == "path"

func get_replacement(new_element: String) -> Element:
	if not can_replace(new_element):
		return null
	
	var element := DB.element(new_element)
	var dropped_attributes: PackedStringArray
	match new_element:
		"rect":
			dropped_attributes = PackedStringArray(["points", "rx", "ry", "x", "y", "width", "height"])
			simplify()
			var list: PackedFloat64Array = get_attribute_list("points")
			var x1 := list[0]
			var y1 := list[1]
			var x2 := list[4]
			var y2 := list[5]
			element.set_attribute("x", minf(x1, x2))
			element.set_attribute("y", minf(y1, y2))
			element.set_attribute("width", absf(x1 - x2))
			element.set_attribute("height", absf(y1 - y2))
		"path":
			dropped_attributes = PackedStringArray(["points", "d"])
			var commands: Array[PathCommand] = []
			var list := get_attribute_list("points")
			if list.size() > 1:
				commands.append(PathCommand.MoveCommand.new(list[0], list[1]))
			for i in range(3, list.size(), 2):
				commands.append(PathCommand.LineCommand.new(list[i - 1], list[i]))
			if list.size() > 3:
				commands.append(PathCommand.CloseCommand.new())
			element.set_attribute("d", commands)
	apply_to(element, dropped_attributes)
	return element


func simplify() -> void:
	var list := get_attribute_list("points")
	var list_size := list.size()
	if list_size < 6:
		return
	var new_list_points := PackedFloat64Array()
	
	for i in range(0, list_size - 2, 2):
		var prev_point := Vector2(list[i - 2], list[i - 1])
		if not is_equal_approx(prev_point.angle_to_point(Vector2(list[i], list[i + 1])),
		prev_point.angle_to_point(Vector2(list[i + 2], list[i + 3]))):
			new_list_points.append(list[i])
			new_list_points.append(list[i + 1])
	
	var second_to_last_point := Vector2(list[-4], list[-3])
	if not is_equal_approx(second_to_last_point.angle_to_point(Vector2(list[-2], list[-1])),
	second_to_last_point.angle_to_point(Vector2(list[0], list[1]))):
		new_list_points.append(list[-2])
		new_list_points.append(list[-1])
	
	get_attribute("points").set_list(new_list_points)
