# A <line/> tag.
class_name TagLine extends TagShape

const name = "line"
const possible_conversions = ["path"]

func user_setup(pos := Vector2.ZERO) -> void:
	if pos != Vector2.ZERO:
		set_attribute("x1", pos.x)
		set_attribute("y1", pos.y)
		set_attribute("y2", pos.y)
	set_attribute("x2", pos.x + 1)
	set_attribute("stroke", "black")

func can_replace(new_tag: String) -> bool:
	return new_tag == "path"

func get_replacement(new_tag: String) -> Tag:
	if not can_replace(new_tag):
		return null
	
	var tag: Tag
	var dropped_attributes: PackedStringArray
	match new_tag:
		"path":
			tag = TagPath.new()
			dropped_attributes = PackedStringArray(["x1", "y1", "x2", "y2"])
			var commands: Array[PathCommand] = []
			commands.append(PathCommand.MoveCommand.new(get_attribute_num("x1"),
					get_attribute_num("y1"), true))
			commands.append(PathCommand.LineCommand.new(
					get_attribute_num("x2") - get_attribute_num("x1"),
					get_attribute_num("y2") - get_attribute_num("y1"), true))
			tag.set_attribute("d", commands)
	
	for attribute_name in attributes:
		if not attribute_name in dropped_attributes:
			tag.set_attribute(attribute_name, attributes[attribute_name])
	
	tag.child_tags = child_tags
	return tag


func get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"x1", "y1", "x2", "y2": return "0"
		"opacity": return "1"
		_: return ""
