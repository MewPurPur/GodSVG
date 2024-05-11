# A <path/> tag.
class_name TagPath extends Tag

const name = "path"
const possible_conversions = []
const icon = preload("res://visual/icons/tag/path.svg")

const known_attributes = ["d", "transform", "opacity", "fill", "fill-opacity",
		"stroke", "stroke-opacity", "stroke-width", "stroke-linecap", "stroke-linejoin"]

func _init() -> void:
	for attrib_name in known_attributes:
		attributes[attrib_name] = DB.attribute(attrib_name)
	super()

func user_setup(pos := Vector2.ZERO) -> void:
	attributes.d.insert_command(0, "M")
	attributes.d.set_command_property(0, "x", pos.x)
	attributes.d.set_command_property(0, "y", pos.y)

func can_replace(_new_tag: String) -> bool:
	return false

func get_replacement(new_tag: String) -> Tag:
	if not can_replace(new_tag):
		return null
	
	return null
