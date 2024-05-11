# A <line/> tag.
class_name TagLine extends Tag

const name = "line"
const possible_conversions = ["path"]
const icon = preload("res://visual/icons/tag/line.svg")

const known_attributes = ["transform", "opacity", "stroke", "stroke-opacity",
		"stroke-width", "stroke-linecap", "x1", "y1", "x2", "y2", ]

func _init(pos := Vector2.ZERO) -> void:
	for attrib_name in known_attributes:
		attributes[attrib_name] = DB.attribute(attrib_name)
	super()

func user_setup(pos := Vector2.ZERO) -> void:
	if pos != Vector2.ZERO:
		attributes.x1.set_num(pos.x)
		attributes.y1.set_num(pos.y)
		attributes.x2.set_num(pos.x + 1)
		attributes.y2.set_num(pos.y)
	attributes.stroke.set_value("black")

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
