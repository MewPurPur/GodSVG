# A <rect> element.
class_name ElementRect extends Element

const name = "rect"
const possible_conversions: PackedStringArray = ["circle", "ellipse", "polygon", "path"]

func user_setup(precise_pos := PackedFloat64Array([0.0, 0.0])) -> void:
	set_attribute("width", 1.0)
	set_attribute("height", 1.0)
	if precise_pos != PackedFloat64Array([0.0, 0.0]):
		set_attribute("x", precise_pos[0])
		set_attribute("y", precise_pos[1])

func can_replace(new_element: String) -> bool:
	match new_element:
		"path":
			return true
		"polygon":
			return get_rx() == 0 and get_ry() == 0
		"ellipse":
			return get_rx() >= get_attribute_num("width") / 2 and\
					get_ry() >= get_attribute_num("height") / 2
		"circle":
			var side := get_attribute_num("width")
			return get_attribute_num("height") == side and get_rx() >= side / 2 and\
					get_ry() >= side / 2
	return false

func get_replacement(new_element: String) -> Element:
	if not can_replace(new_element):
		return null
	
	var element := DB.element(new_element)
	var dropped_attributes: PackedStringArray
	
	var x_num := get_attribute_num("x")
	var y_num := get_attribute_num("y")
	var width_num := get_attribute_num("width")
	var height_num := get_attribute_num("height")
	
	match new_element:
		"ellipse":
			dropped_attributes = PackedStringArray(["x", "y", "width", "height", "rx", "ry",
					"cx", "cy"])
			element.set_attribute("rx", width_num / 2)
			element.set_attribute("ry", height_num / 2)
			element.set_attribute("cx", x_num + width_num / 2)
			element.set_attribute("cy", y_num + height_num / 2)
		"circle":
			dropped_attributes = PackedStringArray(["x", "y", "width", "height", "rx", "ry",
					"r", "cx", "cy"])
			element.set_attribute("r", width_num / 2)
			element.set_attribute("cx", x_num + width_num / 2)
			element.set_attribute("cy", y_num + height_num / 2)
		"polygon":
			dropped_attributes = PackedStringArray(["x", "y", "width", "height", "rx", "ry",
					"points"])
			var points := PackedFloat64Array([x_num, y_num, x_num + width_num, y_num,
					x_num + width_num, y_num + height_num, x_num, y_num + height_num])
			element.get_attribute("points").set_list(points)
		"path":
			dropped_attributes = PackedStringArray(["x", "y", "width", "height", "rx", "ry",
					"d"])
			var commands: Array[PathCommand] = []
			var rx := get_rx()
			var ry := get_ry()
			
			if rx == 0 and ry == 0:
				commands.append(PathCommand.MoveCommand.new(x_num, y_num, true))
				commands.append(PathCommand.HorizontalLineCommand.new(width_num, true))
				commands.append(PathCommand.VerticalLineCommand.new(height_num, true))
				commands.append(PathCommand.HorizontalLineCommand.new(-width_num, true))
				commands.append(PathCommand.CloseCommand.new(true))
			else:
				var w := width_num - rx * 2
				var h := height_num - ry * 2
				
				if w > 0.0 and h > 0.0:
					commands.append(PathCommand.MoveCommand.new(x_num, y_num + ry, true))
					commands.append(PathCommand.EllipticalArcCommand.new(
							rx, ry, 0, 0, 1, rx, -ry, true))
					commands.append(PathCommand.HorizontalLineCommand.new(w, true))
					commands.append(PathCommand.EllipticalArcCommand.new(
							rx, ry, 0, 0, 1, rx, ry, true))
					commands.append(PathCommand.VerticalLineCommand.new(h, true))
					commands.append(PathCommand.EllipticalArcCommand.new(
							rx, ry, 0, 0, 1, -rx, ry, true))
					commands.append(PathCommand.HorizontalLineCommand.new(-w, true))
					commands.append(PathCommand.EllipticalArcCommand.new(
							rx, ry, 0, 0, 1, -rx, -ry, true))
					commands.append(PathCommand.CloseCommand.new(true))
				elif w > 0.0:
					commands.append(PathCommand.MoveCommand.new(x_num + rx + w, y_num, true))
					commands.append(PathCommand.EllipticalArcCommand.new(
							rx, ry, 0, 0, 1, 0, height_num, true))
					commands.append(PathCommand.HorizontalLineCommand.new(-w, true))
					commands.append(PathCommand.EllipticalArcCommand.new(
							rx, ry, 0, 0, 1, 0, -height_num, true))
					commands.append(PathCommand.CloseCommand.new(true))
				elif h > 0.0:
					commands.append(PathCommand.MoveCommand.new(x_num, y_num + ry, true))
					commands.append(PathCommand.EllipticalArcCommand.new(
							rx, ry, 0, 0, 1, width_num, 0, true))
					commands.append(PathCommand.VerticalLineCommand.new(h, true))
					commands.append(PathCommand.EllipticalArcCommand.new(
							rx, ry, 0, 0, 1, -width_num, 0, true))
					commands.append(PathCommand.CloseCommand.new(true))
				else:
					commands.append(PathCommand.MoveCommand.new(x_num + rx, y_num, true))
					commands.append(PathCommand.EllipticalArcCommand.new(
							rx, ry, 0, 0, 1, 0, height_num, true))
					commands.append(PathCommand.EllipticalArcCommand.new(
							rx, ry, 0, 0, 1, 0, -height_num, true))
					commands.append(PathCommand.CloseCommand.new(true))
			element.set_attribute("d", commands)
	apply_to(element, dropped_attributes)
	return element


func get_rx() -> float:
	if has_attribute("rx"):
		return minf(get_attribute_num("rx"), get_attribute_num("width") / 2)
	elif has_attribute("ry"):
		return minf(get_attribute_num("ry"), get_attribute_num("width") / 2)
	else:
		return 0.0

func get_ry() -> float:
	if has_attribute("ry"):
		return minf(get_attribute_num("ry"), get_attribute_num("height") / 2)
	elif has_attribute("rx"):
		return minf(get_attribute_num("rx"), get_attribute_num("height") / 2)
	else:
		return 0.0


func _get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"x", "y", "width", "height": return "0"
		"rx": return "auto"
		"ry": return "auto"
		"opacity": return "1"
		_: return ""

func get_bounding_box() -> Rect2:
	return Rect2(Vector2(get_attribute_num("x"), get_attribute_num("y")),
			Vector2(get_attribute_num("width"), get_attribute_num("height")))
