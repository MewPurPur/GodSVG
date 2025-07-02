# A <circle> element.
class_name ElementCircle extends Element

const name = "circle"
const possible_conversions: PackedStringArray = ["ellipse", "rect", "path"]

func user_setup(precise_pos := PackedFloat64Array([0.0, 0.0])) -> void:
	set_attribute("r", 1.0)
	if precise_pos != PackedFloat64Array([0.0, 0.0]):
		set_attribute("cx", precise_pos[0])
		set_attribute("cy", precise_pos[1])

func can_replace(new_element: String) -> bool:
	return new_element in ["ellipse", "rect", "path"]

func get_replacement(new_element: String) -> Element:
	if not can_replace(new_element):
		return null
	
	var element := DB.element(new_element)
	var dropped_attributes: PackedStringArray
	match new_element:
		"ellipse":
			dropped_attributes = PackedStringArray(["r", "rx", "ry"])
			element.set_attribute("rx", get_attribute_value("r"))
			element.set_attribute("ry", get_attribute_value("r"))
		"rect":
			dropped_attributes = PackedStringArray(["r", "cx", "cy", "rx", "ry",
					"width", "height"])
			element.set_attribute("x", get_attribute_num("cx") - get_attribute_num("r"))
			element.set_attribute("y", get_attribute_num("cy") - get_attribute_num("r"))
			element.set_attribute("width", get_attribute_num("r") * 2)
			element.set_attribute("height", get_attribute_num("r") * 2)
			element.set_attribute("rx", get_attribute_value("r"))
			element.set_attribute("ry", get_attribute_value("r"))
		"path":
			dropped_attributes = PackedStringArray(["r", "cx", "cy", "d"])
			var commands: Array[PathCommand] = []
			commands.append(PathCommand.MoveCommand.new(get_attribute_num("cx"),
					get_attribute_num("cy") - get_attribute_num("r"), true))
			commands.append(PathCommand.EllipticalArcCommand.new(get_attribute_num("r"),
					get_attribute_num("r"), 0, 0, 0, 0, get_attribute_num("r") * 2, true))
			commands.append(PathCommand.EllipticalArcCommand.new(get_attribute_num("r"),
					get_attribute_num("r"), 0, 0, 0, 0, -get_attribute_num("r") * 2, true))
			commands.append(PathCommand.CloseCommand.new(true))
			element.set_attribute("d", commands)
	apply_to(element, dropped_attributes)
	return element


func _get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"cx", "cy": return "0"
		"r": return "0"
		"opacity": return "1"
		_: return ""

func get_bounding_box() -> Rect2:
	var d := get_attribute_num("r") * 2.0
	return Rect2(get_attribute_num("cx") - get_attribute_num("r"),
			get_attribute_num("cy") - get_attribute_num("r"), d, d)
