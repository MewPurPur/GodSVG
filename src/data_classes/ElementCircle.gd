## A <circle> element.
class_name ElementCircle extends Element

const name = "circle"
const possible_conversions: PackedStringArray = ["ellipse", "rect", "path"]

func user_setup(precise_position := PackedFloat64Array([0.0, 0.0])) -> void:
	set_attribute("r", 1.0)
	if precise_position != PackedFloat64Array([0.0, 0.0]):
		set_attribute("cx", precise_position[0])
		set_attribute("cy", precise_position[1])

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
			var r := get_attribute_value("r")
			element.set_attribute("rx", r)
			element.set_attribute("ry", r)
		"rect":
			dropped_attributes = PackedStringArray(["r", "cx", "cy", "rx", "ry", "width", "height"])
			var r := get_attribute_num("r")
			element.set_attribute("x", get_attribute_num("cx") - r)
			element.set_attribute("y", get_attribute_num("cy") - r)
			element.set_attribute("width", r * 2)
			element.set_attribute("height", r * 2)
			element.set_attribute("rx", r)
			element.set_attribute("ry", r)
		"path":
			dropped_attributes = PackedStringArray(["r", "cx", "cy", "d"])
			var cx := get_attribute_num("cx")
			var cy := get_attribute_num("cy")
			var r := get_attribute_num("r")
			var commands: Array[PathCommand] = []
			commands.append(PathCommand.MoveCommand.new(cx + r, cy, true))
			commands.append(PathCommand.EllipticalArcCommand.new(r, r, 0, 0, 1, cx - r, cy, true))
			commands.append(PathCommand.EllipticalArcCommand.new(r, r, 0, 0, 1, cx + r, cy, true))
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
	var r := get_attribute_num("r")
	return Rect2(get_attribute_num("cx") - r, get_attribute_num("cy") - r, r * 2, r * 2)

func get_config_warnings() -> PackedStringArray:
	var warnings := super()
	
	if not has_attribute("r"):
		warnings.append(Translator.translate("No \"{attribute_name}\" attribute defined.").format({"attribute_name": "r"}))
	else:
		var r_value := get_attribute_num("r")
		if is_nan(r_value) or r_value < 0:
			warnings.append(Translator.translate("Attribute \"{attribute_name}\" has invalid value \"{attribute_value}\".").format(
					{"attribute_name": "r", "attribute_value": r_value}))
		elif r_value == 0:
			warnings.append(Translator.translate("Attribute \"{attribute_name}\" has value \"{attribute_value}\" and will not render.").format(
					{"attribute_name": "r", "attribute_value": r_value}))
	
	return warnings
