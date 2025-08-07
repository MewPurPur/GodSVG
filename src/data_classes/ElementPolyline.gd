## A <polyline> element.
class_name ElementPolyline extends Element

const name = "polyline"
const possible_conversions: PackedStringArray = ["path", "line"]

func user_setup(precise_pos := PackedFloat64Array([0.0, 0.0])) -> void:
	if precise_pos != PackedFloat64Array([0.0, 0.0]):
		get_attribute("points").set_list(precise_pos)
	set_attribute("fill", "none")
	set_attribute("stroke", "black")

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
	
	@warning_ignore("integer_division")
	for idx in list.get_list_size() / 2:
		var x_coord := list.get_list_element(idx * 2)
		var y_coord := list.get_list_element(idx * 2 + 1)
		min_x = minf(min_x, x_coord)
		max_x = maxf(max_x, x_coord)
		min_y = minf(min_y, y_coord)
		max_y = maxf(max_y, y_coord)
	
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


func can_replace(new_element: String) -> bool:
	if new_element == "line":
		var optimized_polyline := duplicate()
		optimized_polyline.simplify()
		return optimized_polyline.get_attribute("points").get_list_size() == 4
	else:
		return new_element == "path"

func get_replacement(new_element: String) -> Element:
	if not can_replace(new_element):
		return null
	
	var element := DB.element(new_element)
	var dropped_attributes: PackedStringArray
	match new_element:
		"line":
			dropped_attributes = PackedStringArray(["points", "rx", "ry", "cx", "cy", "width", "height", "fill", "fill-opacity", "stroke-linejoin"])
			simplify()
			var list := get_attribute_list("points")
			element.set_attribute("x1", list[0])
			element.set_attribute("y1", list[1])
			element.set_attribute("x2", list[2])
			element.set_attribute("y2", list[3])
		"path":
			dropped_attributes = PackedStringArray(["points", "d"])
			var commands: Array[PathCommand] = []
			var list := get_attribute_list("points")
			if list.size() > 1:
				commands.append(PathCommand.MoveCommand.new(list[0], list[1]))
			for idx in range(3, list.size(), 2):
				commands.append(PathCommand.LineCommand.new(list[idx - 1], list[idx]))
			element.set_attribute("d", commands)
	apply_to(element, dropped_attributes)
	return element


func simplify() -> void:
	var list := get_attribute_list("points")
	var new_list_points := PackedFloat64Array()
	
	new_list_points.append(list[0])
	new_list_points.append(list[1])
	@warning_ignore("integer_division")
	for idx in range(1, list.size() / 2 - 1):
		var prev_point := Vector2(list[idx * 2 - 2], list[idx * 2 - 1])
		if not is_equal_approx(prev_point.angle_to_point(Vector2(list[idx * 2], list[idx * 2 + 1])),
		prev_point.angle_to_point(Vector2(list[idx * 2 + 2], list[idx * 2 + 3]))):
			new_list_points.append(list[idx * 2])
			new_list_points.append(list[idx * 2 + 1])
	new_list_points.append(list[-2])
	new_list_points.append(list[-1])
	get_attribute("points").set_list(new_list_points)
