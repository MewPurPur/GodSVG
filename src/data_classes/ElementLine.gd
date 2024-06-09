# A <line/> element.
class_name ElementLine extends Element

const name = "line"
const possible_conversions = ["path"]

func user_setup(pos := Vector2.ZERO) -> void:
	if pos != Vector2.ZERO:
		set_attribute("x1", pos.x)
		set_attribute("y1", pos.y)
		set_attribute("y2", pos.y)
	set_attribute("x2", pos.x + 1)
	set_attribute("stroke", "black")

func can_replace(new_element: String) -> bool:
	return new_element == "path"

func get_replacement(new_element: String) -> Element:
	if not can_replace(new_element):
		return null
	
	var element := DB.element(new_element)
	var dropped_attributes: PackedStringArray
	match new_element:
		"path":
			element = ElementPath.new()
			dropped_attributes = PackedStringArray(["x1", "y1", "x2", "y2", "d"])
			var commands: Array[PathCommand] = []
			commands.append(PathCommand.MoveCommand.new(get_attribute_num("x1"),
					get_attribute_num("y1"), true))
			commands.append(PathCommand.LineCommand.new(
					get_attribute_num("x2") - get_attribute_num("x1"),
					get_attribute_num("y2") - get_attribute_num("y1"), true))
			element.set_attribute("d", commands)
	apply_to(element, dropped_attributes)
	return element


func get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"x1", "y1", "x2", "y2": return "0"
		"opacity": return "1"
		_: return ""

func get_bounding_box() -> Rect2:
	var rect: Rect2
	rect.position = Vector2(minf(get_attribute_num("x1"), get_attribute_num("x2")),
			minf(get_attribute_num("y1"), get_attribute_num("y2")))
	rect.end = Vector2(maxf(get_attribute_num("x1"), get_attribute_num("x2")),
			maxf(get_attribute_num("y1"), get_attribute_num("y2")))
	return rect

func get_config_warnings() -> PackedStringArray:
	var warnings := super()
	if not (parent is ElementG or parent is ElementSVG or parent is ElementUnrecognized):
		warnings.append(TranslationServer.translate("{element} must be inside {allowed} to have any effect.").format(
				{"element": self.name, "allowed": "[svg, g]"}))
	return warnings
