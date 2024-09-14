# A <polygon/> element.
class_name ElementPolygon extends Element

const name = "polygon"
const possible_conversions = ["path", "rect"]

func user_setup(pos := Vector2.ZERO) -> void:
	if pos != Vector2.ZERO:
		set_attribute("points", "0 0")

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
	if new_element == "rect":
		var optimized_polygon := self.duplicate()
		optimized_polygon.simplify()
		var list_points: PackedVector2Array =\
				optimized_polygon.get_attribute("points").get_points()
		if list_points.size() != 4:
			return false
		
		return (list_points[0].x == list_points[1].x and list_points[1].y == list_points[2].y and\
		list_points[2].x == list_points[3].x and list_points[3].y == list_points[0].y) or\
		(list_points[0].y == list_points[1].y and list_points[1].x == list_points[2].x and\
		list_points[2].y == list_points[3].y and list_points[3].x == list_points[0].x)
	else:
		return new_element == "path"

func get_replacement(new_element: String) -> Element:
	if not can_replace(new_element):
		return null
	
	var element := DB.element(new_element)
	var dropped_attributes: PackedStringArray
	match new_element:
		"rect":
			dropped_attributes = PackedStringArray(["points", "rx", "ry", "cx", "cy",
					"width", "height"])
			simplify()
			var pts: PackedVector2Array = get_attribute("points").get_points()
			var x1 := pts[0].x
			var y1 := pts[0].y
			var x2 := pts[2].x
			var y2 := pts[2].y
			element.set_attribute("x", minf(x1, x2))
			element.set_attribute("y", minf(y1, y2))
			element.set_attribute("width", absf(x1 - x2))
			element.set_attribute("height", absf(y1 - y2))
		"path":
			dropped_attributes = PackedStringArray(["points", "d"])
			var commands: Array[PathCommand] = []
			var pts: PackedVector2Array = get_attribute("points").get_points()
			if not pts.is_empty():
				commands.append(PathCommand.MoveCommand.new(pts[0].x, pts[0].y))
			for idx in range(1, pts.size()):
				var point := pts[idx]
				commands.append(PathCommand.LineCommand.new(point.x, point.y))
			if not pts.is_empty():
				commands.append(PathCommand.CloseCommand.new())
			element.set_attribute("d", commands)
	apply_to(element, dropped_attributes)
	return element


func simplify() -> void:
	var list_points: PackedVector2Array = get_attribute("points").get_points()
	var new_list_points := PackedVector2Array()
	
	for idx in list_points.size() - 1:
		var prev_point := list_points[idx - 1]
		var current_point := list_points[idx]
		if not is_equal_approx(prev_point.angle_to_point(current_point),
		prev_point.angle_to_point(list_points[idx + 1])):
			new_list_points.append(current_point)
	
	if not is_equal_approx(list_points[-2].angle_to_point(list_points[-1]),
	list_points[-2].angle_to_point(list_points[0])):
		new_list_points.append(list_points[-1])
	
	get_attribute("points").set_points(new_list_points)
