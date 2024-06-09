# A <circle/> tag.
class_name TagCircle extends TagShape

const name = "circle"
const possible_conversions = ["ellipse", "rect", "path"]

func user_setup(pos := Vector2.ZERO) -> void:
	set_attribute("r", 1.0)
	if pos != Vector2.ZERO:
		set_attribute("cx", pos.x)
		set_attribute("cy", pos.y)

func can_replace(new_tag: String) -> bool:
	return new_tag in ["ellipse", "rect", "path"]

func get_replacement(new_tag: String) -> Tag:
	if not can_replace(new_tag):
		return null
	
	var tag: Tag
	var dropped_attributes: PackedStringArray
	match new_tag:
		"ellipse":
			tag = TagEllipse.new()
			dropped_attributes = PackedStringArray(["r"])
			tag.set_attribute("rx", get_attribute_num("r"))
			tag.set_attribute("ry", get_attribute_num("r"))
		"rect":
			tag = TagRect.new()
			dropped_attributes = PackedStringArray(["r", "cx", "cy"])
			tag.set_attribute("x", get_attribute_num("cx") - get_attribute_num("r"))
			tag.set_attribute("y", get_attribute_num("cy") - get_attribute_num("r"))
			tag.set_attribute("width", get_attribute_num("r"))
			tag.set_attribute("height", get_attribute_num("r"))
			tag.set_attribute("rx", get_attribute_num("r"))
			tag.set_attribute("ry", get_attribute_num("r"))
		"path":
			tag = TagPath.new()
			dropped_attributes = PackedStringArray(["r", "cx", "cy"])
			var commands: Array[PathCommand] = []
			commands.append(PathCommand.MoveCommand.new(get_attribute_num("cx"),
					get_attribute_num("cy") - get_attribute_num("r"), true))
			commands.append(PathCommand.EllipticalArcCommand.new(get_attribute_num("r"),
					get_attribute_num("r"), 0, 0, 0, 0, get_attribute_num("r") * 2, true))
			commands.append(PathCommand.EllipticalArcCommand.new(get_attribute_num("r"),
					get_attribute_num("r"), 0, 0, 0, 0, -get_attribute_num("r") * 2, true))
			commands.append(PathCommand.CloseCommand.new(true))
			tag.set_attribute("d", commands)
	
	for attribute_name in attributes:
		if not attribute_name in dropped_attributes:
			tag.set_attribute(attribute_name, attributes[attribute_name])
	
	tag.child_tags = child_tags
	return tag


func get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"cx", "cy": return "0"
		"r": return "0"
		"opacity": return "1"
		_: return ""
