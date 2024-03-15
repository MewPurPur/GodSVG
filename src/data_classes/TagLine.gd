## A <line/> tag.
class_name TagLine extends Tag

const name = "line"
const possible_conversions = ["path"]
const icon = preload("res://visual/icons/tag/line.svg")

const known_shape_attributes = ["x1", "y1", "x2", "y2"]
const known_inheritable_attributes = ["transform", "opacity", "stroke", "stroke-opacity",
		"stroke-width", "stroke-linecap"]

func _init(pos := Vector2.ZERO) -> void:
	attributes = {
		"transform": AttributeTransform.new(),
		"x1": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, "0"),
		"y1": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, "0"),
		"x2": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, "0", "1"),
		"y2": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, "0"),
		"opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, "1"),
		"stroke": AttributeColor.new("none", "#000"),
		"stroke-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, "1"),
		"stroke-width": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, "1"),
		"stroke-linecap": AttributeEnum.new(["butt", "round", "square"], 0),
	}
	attributes.x1.set_num(pos.x)
	attributes.y1.set_num(pos.y)
	attributes.x2.set_num(pos.x + 1)
	attributes.y2.set_num(pos.y)
	super()


func can_replace(new_tag: String) -> bool:
	return new_tag == "path"

func get_replacement(new_tag: String) -> Tag:
	if not can_replace(new_tag):
		return null
	
	var tag: Tag
	var retained_attributes: Array[String] = []
	match new_tag:
		"path":
			tag = TagPath.new()
			retained_attributes = ["transform", "opacity", "stroke", "stroke-opacity",
					"stroke-width", "stroke-linecap"]
			var commands: Array[PathCommand] = []
			commands.append(PathCommand.MoveCommand.new(attributes.x1.get_num(),
					attributes.y1.get_num(), true))
			commands.append(PathCommand.LineCommand.new(
					attributes.x2.get_num() - attributes.x1.get_num(),
					attributes.y2.get_num() - attributes.y1.get_num(), true))
			tag.attributes.d.set_commands(commands, Attribute.SyncMode.SILENT)
	
	for k in retained_attributes:
		tag.attributes[k].set_value(attributes[k].get_value(), Attribute.SyncMode.SILENT)
	tag.child_tags = child_tags
	
	return tag
