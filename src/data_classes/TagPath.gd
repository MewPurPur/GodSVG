# A <path/> tag.
class_name TagPath extends TagShape

const name = "path"
const possible_conversions = []

func user_setup(pos := Vector2.ZERO) -> void:
	if pos != Vector2.ZERO:
		var attrib := get_attribute("d")
		attrib.insert_command(0, "M")
		attrib.set_command_property(0, "x", pos.x)
		attrib.set_command_property(0, "y", pos.y)

func get_own_default(attribute_name: String) -> String:
	if attribute_name == "opacity":
		return "1"
	return ""
