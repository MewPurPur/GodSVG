## A <path/> tag.
class_name TagPath extends Tag

const name = "path"
const possible_conversions = []
const icon = preload("res://visual/icons/tag/path.svg")

const known_shape_attributes = ["d"]
const known_inheritable_attributes = ["transform", "opacity", "fill", "fill-opacity",
		"stroke", "stroke-opacity", "stroke-width", "stroke-linecap", "stroke-linejoin"]

func _init() -> void:
	attributes = {
		"transform": AttributeTransform.new(),
		"d": AttributePath.new(),
		"opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, "1"),
		"fill": AttributeColor.new("#000"),
		"fill-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, "1"),
		"stroke": AttributeColor.new("none"),
		"stroke-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, "1"),
		"stroke-width": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, "1"),
		"stroke-linecap": AttributeEnum.new(["butt", "round", "square"], 0),
		"stroke-linejoin": AttributeEnum.new(["miter", "round", "bevel"], 0),
	}
	super()


func move_to(pos: Vector2) -> void:
	# Since this function is currently only used when adding a tag,
	# there's no logic for anything more than just a single MoveCommand.
	if attributes.d.get_command_count() == 1 and\
	attributes.d.get_command(0) is PathCommand.MoveCommand:
		attributes.d.set_command_property(0, &"x", pos.x, Attribute.SyncMode.NO_PROPAGATION)
		attributes.d.set_command_property(0, &"y", pos.y, Attribute.SyncMode.INTERMEDIATE)

func can_replace(_new_tag: String) -> bool:
	return false

func get_replacement(new_tag: String) -> Tag:
	if not can_replace(new_tag):
		return null
	
	return null
