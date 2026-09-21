## An <ellipse> element.
class_name ElementEllipse extends Element

const name = "ellipse"
const possible_conversions: PackedStringArray = ["circle", "rect", "path"]

func user_setup(precise_position := PackedFloat64Array([0.0, 0.0])) -> void:
	set_attribute("rx", 1.0)
	set_attribute("ry", 1.0)
	if precise_position != PackedFloat64Array([0.0, 0.0]):
		set_attribute("cx", precise_position[0])
		set_attribute("cy", precise_position[1])

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
			var rx := get_attribute_num("rx")
			var ry := get_attribute_num("ry")
			dropped_attributes = PackedStringArray(["cx", "cy", "x", "y", "width", "height"])
			element.set_attribute("x", get_attribute_num("cx") - rx)
			element.set_attribute("y", get_attribute_num("cy") - ry)
			element.set_attribute("width", rx * 2)
			element.set_attribute("height", ry * 2)
		"path":
			dropped_attributes = PackedStringArray(["cx", "cy", "rx", "ry", "d"])
			var cx := get_attribute_num("cx")
			var cy := get_attribute_num("cy")
			var rx := get_attribute_num("rx")
			var ry := get_attribute_num("ry")
			var commands: Array[PathCommand] = []
			commands.append(PathCommand.MoveCommand.new(cx + rx, cy, true))
			commands.append(PathCommand.EllipticalArcCommand.new(rx, ry, 0, 0, 1, cx - rx, cy, true))
			commands.append(PathCommand.EllipticalArcCommand.new(rx, ry, 0, 0, 1, cx + rx, cy, true))
			commands.append(PathCommand.CloseCommand.new(true))
			element.set_attribute("d", commands)
	apply_to(element, dropped_attributes)
	return element


func _get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"cx", "cy": return "0"
		"opacity": return "1"
		_: return ""

func get_bounding_box() -> Rect2:
	var rx := get_attribute_num("rx")
	var ry := get_attribute_num("ry")
	return Rect2(get_attribute_num("cx") - rx, get_attribute_num("cy") - ry, rx * 2, ry * 2)

func get_config_warnings() -> PackedStringArray:
	var warnings := super()
	
	for r_attrib in ["rx", "ry"]:
		if not has_attribute(r_attrib):
			var warning := Translator.translate("No \"{attribute_name}\" attribute defined.").format({"attribute_name": r_attrib})
			warning += " " + Translator.translate("This may be interpreted differently by different SVG software.")
			warnings.append(warning)
		else:
			var r_attrib_value := get_attribute_num(r_attrib)
			if r_attrib_value <= 0:
				warnings.append(Translator.translate("Invalid value for \"{attribute_name}\" attribute.").format({"attribute_name": r_attrib}))
	
	return warnings
