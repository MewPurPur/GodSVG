class_name TagPath extends Tag
## A <path/> tag.

const name = "path"
const possible_conversions = []
const icon = preload("res://visual/icons/tag/path.svg")

const known_attributes = ["d", "transform", "opacity", "fill", "fill-opacity",
		"stroke", "stroke-opacity", "stroke-width", "stroke-linecap", "stroke-linejoin"]

func _init(pos := Vector2.ZERO) -> void:
	attributes = {
		"transform": AttributeTransform.new(),
		"d": AttributePath.new(),
		"opacity": AttributeNumeric.new(0.0, 1.0, "1"),
		"fill": AttributeColor.new("black"),
		"fill-opacity": AttributeNumeric.new(0.0, 1.0, "1"),
		"stroke": AttributeColor.new("none"),
		"stroke-opacity": AttributeNumeric.new(0.0, 1.0, "1"),
		"stroke-width": AttributeNumeric.new(0.0, INF, "1"),
		"stroke-linecap": AttributeEnum.new(["butt", "round", "square"], 0),
		"stroke-linejoin": AttributeEnum.new(["miter", "round", "bevel"], 0),
	}
	attributes.d.insert_command(0, "M")
	attributes.d.set_command_property(0, "x", pos.x)
	attributes.d.set_command_property(0, "y", pos.y)
	super()

func can_replace(_new_tag: String) -> bool:
	return false

func get_replacement(new_tag: String) -> Tag:
	if not can_replace(new_tag):
		return null
	
	return null
