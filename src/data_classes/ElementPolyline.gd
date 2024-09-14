# A <polyline/> element.
class_name ElementPolyline extends Element

const name = "polyline"
const possible_conversions = ["path", "line"]

func user_setup(pos := Vector2.ZERO) -> void:
	if pos != Vector2.ZERO:
		set_attribute("points", "0 0")
	set_attribute("fill", "none")
	set_attribute("stroke", "black")

func get_own_default(attribute_name: String) -> String:
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
		var optimized_polyline := self.duplicate()
		optimized_polyline.simplify()
		var list_points: PackedVector2Array =\
				optimized_polyline.get_attribute("points").get_points()
		return list_points.size() == 2
	else:
		return new_element == "path"

func get_replacement(new_element: String) -> Element:
	if not can_replace(new_element):
		return null
	
	var element := DB.element(new_element)
	var dropped_attributes: PackedStringArray
	match new_element:
		"line":
			dropped_attributes = PackedStringArray(["points", "rx", "ry", "cx", "cy",
					"width", "height"])
			simplify()
			var pts: PackedVector2Array = get_attribute("points").get_points()
			element.set_attribute("x1", pts[0].x)
			element.set_attribute("y1", pts[0].y)
			element.set_attribute("x2", pts[1].x)
			element.set_attribute("y2", pts[1].y)
		"path":
			dropped_attributes = PackedStringArray(["points", "d"])
			var commands: Array[PathCommand] = []
			var pts: PackedVector2Array = get_attribute("points").get_points()
			if not pts.is_empty():
				commands.append(PathCommand.MoveCommand.new(pts[0].x, pts[0].y))
			for idx in range(1, pts.size()):
				var point := pts[idx]
				commands.append(PathCommand.LineCommand.new(point.x, point.y))
			element.set_attribute("d", commands)
	apply_to(element, dropped_attributes)
	return element


func simplify() -> void:
	var list_points: PackedVector2Array = get_attribute("points").get_points()
	var new_list_points := PackedVector2Array()
	new_list_points.append(list_points[0])
	for idx in range(1, list_points.size() - 1):
		var prev_point := list_points[idx - 1]
		var current_point := list_points[idx]
		if not is_equal_approx(prev_point.angle_to_point(current_point),
		prev_point.angle_to_point(list_points[idx + 1])):
			new_list_points.append(current_point)
	new_list_points.append(list_points[-1])
	get_attribute("points").set_points(new_list_points)
