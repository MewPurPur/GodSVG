# A <rect/> element.
class_name ElementRect extends Element

const name = "rect"
const possible_conversions = ["circle", "ellipse", "path"]

func user_setup(pos := Vector2.ZERO) -> void:
	set_attribute("width", 1.0)
	set_attribute("height", 1.0)
	if pos != Vector2.ZERO:
		set_attribute("x", pos.x)
		set_attribute("y", pos.y)

func can_replace(new_element: String) -> bool:
	if new_element == "ellipse":
		return get_rx() >= get_attribute_num("width") / 2 and\
				get_ry() >= get_attribute_num("height") / 2
	elif new_element == "circle":
		var side := get_attribute_num("width")
		return get_attribute_num("height") == side and get_rx() >= side / 2 and\
				get_ry() >= side / 2
	else:
		return new_element == "path"

func get_replacement(new_element: String) -> Element:
	if not can_replace(new_element):
		return null
	
	var element := DB.element(new_element)
	var dropped_attributes: PackedStringArray
	match new_element:
		"ellipse":
			dropped_attributes = PackedStringArray(["x", "y", "width", "height",
					"rx", "ry", "cx", "cy"])
			element.set_attribute("rx", get_attribute_num("width") / 2)
			element.set_attribute("ry", get_attribute_num("height") / 2)
			element.set_attribute("cx", get_attribute_num("x") + get_attribute_num("width") / 2)
			element.set_attribute("cy", get_attribute_num("y") + get_attribute_num("height") / 2)
		"circle":
			dropped_attributes = PackedStringArray(["x", "y", "width", "height", "rx", "ry",
					"r", "cx", "cy"])
			element.set_attribute("r", get_attribute_num("width") / 2)
			element.set_attribute("cx", get_attribute_num("x") + get_attribute_num("width") / 2)
			element.set_attribute("cy", get_attribute_num("y") + get_attribute_num("height") / 2)
		"path":
			dropped_attributes = PackedStringArray(["x", "y", "width", "height", "rx", "ry", "d"])
			var commands: Array[PathCommand] = []
			if get_rx() == 0 and get_ry() == 0:
				commands.append(PathCommand.MoveCommand.new(get_attribute_num("x"),
						get_attribute_num("y"), true))
				commands.append(PathCommand.HorizontalLineCommand.new(
						get_attribute_num("width"), true))
				commands.append(PathCommand.VerticalLineCommand.new(
						get_attribute_num("height"), true))
				commands.append(PathCommand.HorizontalLineCommand.new(
						-get_attribute_num("width"), true))
				commands.append(PathCommand.CloseCommand.new(true))
			else:
				var w := get_attribute_num("width") - get_rx() * 2
				var h := get_attribute_num("height") - get_ry() * 2
				
				commands.append(PathCommand.MoveCommand.new(get_attribute_num("x"),
						get_attribute_num("y") + get_ry(), true))
				commands.append(PathCommand.EllipticalArcCommand.new(
						get_rx(), get_ry(), 0, 0, 1, get_rx(), -get_ry(), true))
				if w > 0.0:
					commands.append(PathCommand.HorizontalLineCommand.new(w, true))
				commands.append(PathCommand.EllipticalArcCommand.new(
						get_rx(), get_ry(), 0, 0, 1, get_rx(), get_ry(), true))
				if h > 0.0:
					commands.append(PathCommand.VerticalLineCommand.new(h, true))
				commands.append(PathCommand.EllipticalArcCommand.new(
						get_rx(), get_ry(), 0, 0, 1, -get_rx(), get_ry(), true))
				if w > 0.0:
					commands.append(PathCommand.HorizontalLineCommand.new(-w, true))
				commands.append(PathCommand.EllipticalArcCommand.new(
						get_rx(), get_ry(), 0, 0, 1, -get_rx(), -get_ry(), true))
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


func get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"x", "y", "width", "height": return "0"
		"rx": return "auto"
		"ry": return "auto"
		"opacity": return "1"
		_: return ""

func get_bounding_box() -> Rect2:
	return Rect2(Vector2(get_attribute_num("x"), get_attribute_num("y")),
			Vector2(get_attribute_num("width"), get_attribute_num("height")))
