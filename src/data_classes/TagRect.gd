# A <rect/> tag.
class_name TagRect extends TagShape

var rx: float
var ry: float

const name = "rect"
const possible_conversions = ["circle", "ellipse", "path"]

func user_setup(pos := Vector2.ZERO) -> void:
	set_attribute("width", 1.0)
	set_attribute("height", 1.0)
	if pos != Vector2.ZERO:
		set_attribute("x", pos.x)
		set_attribute("y", pos.y)

func can_replace(new_tag: String) -> bool:
	if new_tag == "ellipse":
		return rx >= get_attribute_num("width") / 2 and ry >= get_attribute_num("height") / 2
	elif new_tag == "circle":
		var side := get_attribute_num("width")
		return get_attribute_num("height") == side and rx >= side / 2 and ry >= side / 2
	else:
		return new_tag == "path"

func get_replacement(new_tag: String) -> Tag:
	if not can_replace(new_tag):
		return null
	
	var tag: Tag
	var dropped_attributes: PackedStringArray
	match new_tag:
		"ellipse":
			tag = TagEllipse.new()
			dropped_attributes = PackedStringArray(["x", "y", "width", "height"])
			tag.set_attribute("rx", get_attribute_num("width") / 2)
			tag.set_attribute("ry", get_attribute_num("height") / 2)
			tag.set_attribute("cx", get_attribute_num("x") + get_attribute_num("width") / 2)
			tag.set_attribute("cy", get_attribute_num("y") + get_attribute_num("height") / 2)
		"circle":
			tag = TagCircle.new()
			dropped_attributes = PackedStringArray(["x", "y", "width", "height", "rx", "ry"])
			tag.set_attribute("r", get_attribute_num("width") / 2)
			tag.set_attribute("cx", get_attribute_num("x") + get_attribute_num("width") / 2)
			tag.set_attribute("cy", get_attribute_num("y") + get_attribute_num("height") / 2)
		"path":
			tag = TagPath.new()
			dropped_attributes = PackedStringArray(["x", "y", "width", "height", "rx", "ry"])
			var commands: Array[PathCommand] = []
			if rx == 0 and ry == 0:
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
				var w := get_attribute_num("width") - rx * 2
				var h := get_attribute_num("height") - ry * 2
				
				commands.append(PathCommand.MoveCommand.new(get_attribute_num("x"),
						get_attribute_num("y") + ry, true))
				commands.append(PathCommand.EllipticalArcCommand.new(
						rx, ry, 0, 0, 1, rx, -ry, true))
				if w > 0.0:
					commands.append(PathCommand.HorizontalLineCommand.new(w, true))
				commands.append(PathCommand.EllipticalArcCommand.new(
						rx, ry, 0, 0, 1, rx, ry, true))
				if h > 0.0:
					commands.append(PathCommand.VerticalLineCommand.new(h, true))
				commands.append(PathCommand.EllipticalArcCommand.new(
						rx, ry, 0, 0, 1, -rx, ry, true))
				if w > 0.0:
					commands.append(PathCommand.HorizontalLineCommand.new(-w, true))
				commands.append(PathCommand.EllipticalArcCommand.new(
						rx, ry, 0, 0, 1, -rx, -ry, true))
				commands.append(PathCommand.CloseCommand.new(true))
			tag.set_attribute("d", commands)
	
	for attribute_name in attributes:
		if not attribute_name in dropped_attributes:
			tag.set_attribute(attribute_name, attributes[attribute_name])
	
	tag.child_tags = child_tags
	return tag

func update_cache() -> void:
	rx = ry if !attributes.has("rx") else minf(get_attribute_num("rx"),
			get_attribute_num("width") / 2)
	ry = rx if !attributes.has("ry") else minf(get_attribute_num("ry"),
			get_attribute_num("height") / 2)

func get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"x", "y", "width", "height": return "0"
		"rx": return "auto"
		"ry": return "auto"
		"opacity": return "1"
		_: return ""
