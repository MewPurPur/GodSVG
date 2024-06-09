# An <ellipse/> tag.
class_name TagEllipse extends TagShape

var rx: float
var ry: float

const name = "ellipse"
const possible_conversions = ["circle", "rect", "path"]

func user_setup(pos := Vector2.ZERO) -> void:
	set_attribute("rx", 1.0)
	set_attribute("ry", 1.0)
	if pos != Vector2.ZERO:
		set_attribute("cx", pos.x)
		set_attribute("cy", pos.y)

func can_replace(new_tag: String) -> bool:
	if new_tag == "circle":
		return get_attribute_num("rx") == get_attribute_num("ry")
	else:
		return new_tag in ["rect", "path"]

func get_replacement(new_tag: String) -> Tag:
	if not can_replace(new_tag):
		return null
	
	var tag: Tag
	var dropped_attributes: PackedStringArray
	match new_tag:
		"circle":
			tag = TagCircle.new()
			dropped_attributes = PackedStringArray(["rx", "ry"])
			tag.set_attribute("r", get_attribute_num("rx"))
		"rect":
			tag = TagRect.new()
			dropped_attributes = PackedStringArray(["cx", "cy"])
			tag.set_attribute("x", get_attribute_num("cx") - get_attribute_num("rx"))
			tag.set_attribute("y", get_attribute_num("cy") - get_attribute_num("ry"))
			tag.set_attribute("width", get_attribute_num("rx") * 2)
			tag.set_attribute("height", get_attribute_num("ry") * 2)
		"path":
			tag = TagPath.new()
			dropped_attributes = PackedStringArray(["cx", "cy", "rx", "ry"])
			var commands: Array[PathCommand] = []
			commands.append(PathCommand.MoveCommand.new(get_attribute_num("cx"),
					get_attribute_num("cy") - ry, true))
			commands.append(PathCommand.EllipticalArcCommand.new(rx, ry, 0, 0, 0, 0,
					ry * 2, true))
			commands.append(PathCommand.EllipticalArcCommand.new(rx, ry, 0, 0, 0, 0,
					-ry * 2, true))
			commands.append(PathCommand.CloseCommand.new(true))
			tag.set_attribute("d", commands)
	
	for attribute_name in attributes:
		if not attribute_name in dropped_attributes:
			tag.set_attribute(attribute_name, attributes[attribute_name])
	
	tag.child_tags = child_tags
	return tag

func update_cache() -> void:
	rx = get_attribute_num("rx") if attributes.has("rx") else get_attribute_num("ry")
	ry = get_attribute_num("ry") if attributes.has("ry") else get_attribute_num("rx")

func get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"cx", "cy": return "0"
		"rx": return "auto"
		"ry": return "auto"
		"opacity": return "1"
		_: return ""
