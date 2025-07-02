# An <ellipse> element.
class_name ElementEllipse extends Element

const name = "ellipse"
const possible_conversions: PackedStringArray = ["circle", "rect", "path"]

func user_setup(precise_pos := PackedFloat64Array([0.0, 0.0])) -> void:
	set_attribute("rx", 1.0)
	set_attribute("ry", 1.0)
	if precise_pos != PackedFloat64Array([0.0, 0.0]):
		set_attribute("cx", precise_pos[0])
		set_attribute("cy", precise_pos[1])

func can_replace(new_element: String) -> bool:
	if new_element == "circle":
		return get_attribute_num("rx") == get_attribute_num("ry")
	else:
		return new_element in ["rect", "path"]

func get_replacement(new_element: String) -> Element:
	if not can_replace(new_element):
		return null
	
	var element := DB.element(new_element)
	var dropped_attributes: PackedStringArray
	match new_element:
		"circle":
			dropped_attributes = PackedStringArray(["rx", "ry", "r"])
			element.set_attribute("r", get_attribute_value("rx"))
		"rect":
			dropped_attributes = PackedStringArray(["cx", "cy", "x", "y", "width", "height"])
			element.set_attribute("x", get_attribute_num("cx") - get_attribute_num("rx"))
			element.set_attribute("y", get_attribute_num("cy") - get_attribute_num("ry"))
			element.set_attribute("width", get_attribute_num("rx") * 2)
			element.set_attribute("height", get_attribute_num("ry") * 2)
		"path":
			dropped_attributes = PackedStringArray(["cx", "cy", "rx", "ry", "d"])
			var commands: Array[PathCommand] = []
			commands.append(PathCommand.MoveCommand.new(get_attribute_num("cx"),
					get_attribute_num("cy") - get_ry(), true))
			commands.append(PathCommand.EllipticalArcCommand.new(get_rx(), get_ry(), 0, 0, 0, 0,
					get_ry() * 2, true))
			commands.append(PathCommand.EllipticalArcCommand.new(get_rx(), get_ry(), 0, 0, 0, 0,
					-get_ry() * 2, true))
			commands.append(PathCommand.CloseCommand.new(true))
			element.set_attribute("d", commands)
	apply_to(element, dropped_attributes)
	return element


func get_rx() -> float:
	return get_attribute_num("rx") if has_attribute("rx") else\
			get_attribute_num("ry") if has_attribute("ry") else 0.0

func get_ry() -> float:
	return get_attribute_num("ry") if has_attribute("ry") else\
			get_attribute_num("rx") if has_attribute("rx") else 0.0


func _get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"cx", "cy": return "0"
		"rx": return "auto"
		"ry": return "auto"
		"opacity": return "1"
		_: return ""

func get_bounding_box() -> Rect2:
	return Rect2(get_attribute_num("cx") - get_rx(),
			get_attribute_num("cy") - get_ry(), get_rx() * 2, get_ry() * 2)
