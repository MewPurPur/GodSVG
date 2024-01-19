## A <circle/> tag.
class_name TagCircle extends Tag

const name = "circle"
const possible_conversions = ["ellipse", "rect", "path"]
const known_attributes = ["transform", "cx", "cy", "r",
		"opacity", "fill", "fill-opacity", "stroke", "stroke-opacity", "stroke-width"]

func _init() -> void:
	attributes = {
		"transform": AttributeTransform.new("matrix(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)"),
		"cx": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, "0"),
		"cy": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, "0"),
		"r": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, "0", "1"),
		"opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, "1"),
		"fill": AttributeColor.new("#000"),
		"fill-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, "1"),
		"stroke": AttributeColor.new("none"),
		"stroke-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, "1"),
		"stroke-width": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, "1"),
	}
	super()


func can_replace(new_tag: String) -> bool:
	return new_tag in ["ellipse", "rect", "path"]

func get_replacement(new_tag: String) -> Tag:
	if not can_replace(new_tag):
		return null
	
	var tag: Tag
	var retained_attributes: Array[String] = []
	match new_tag:
		"ellipse":
			tag = TagEllipse.new()
			retained_attributes = ["cx", "cy", "opacity", "fill", "fill-opacity", "stroke",
					"stroke-opacity", "stroke-width"]
			tag.attributes.rx.set_num(attributes.r.get_num(), Attribute.SyncMode.SILENT)
			tag.attributes.ry.set_num(attributes.r.get_num(), Attribute.SyncMode.SILENT)
		"rect":
			tag = TagRect.new()
			retained_attributes = ["opacity", "fill", "fill-opacity", "stroke",
					"stroke-opacity", "stroke-width"]
			tag.attributes.x.set_num(attributes.cx.get_num() - attributes.r.get_num(),
					Attribute.SyncMode.SILENT)
			tag.attributes.y.set_num(attributes.cy.get_num() - attributes.r.get_num(),
					Attribute.SyncMode.SILENT)
			tag.attributes.width.set_num(attributes.r.get_num() * 2,
					Attribute.SyncMode.SILENT)
			tag.attributes.height.set_num(attributes.r.get_num() * 2,
					Attribute.SyncMode.SILENT)
			tag.attributes.rx.set_num(attributes.r.get_num(), Attribute.SyncMode.SILENT)
			tag.attributes.ry.set_num(attributes.r.get_num(), Attribute.SyncMode.SILENT)
		"path":
			tag = TagPath.new()
			retained_attributes = ["opacity", "fill", "fill-opacity", "stroke",
					"stroke-opacity", "stroke-width"]
			var commands: Array[PathCommand] = []
			commands.append(PathCommand.MoveCommand.new(attributes.cx.get_num(),
					attributes.cy.get_num() - attributes.r.get_num(), true))
			commands.append(PathCommand.EllipticalArcCommand.new(attributes.r.get_num(),
					attributes.r.get_num(), 0, 0, 0, 0, attributes.r.get_num() * 2, true))
			commands.append(PathCommand.EllipticalArcCommand.new(attributes.r.get_num(),
					attributes.r.get_num(), 0, 0, 0, 0, -attributes.r.get_num() * 2, true))
			commands.append(PathCommand.CloseCommand.new(true))
			tag.attributes.d.set_commands(commands, Attribute.SyncMode.SILENT)
	for k in retained_attributes:
		tag.attributes[k].set_value(attributes[k].get_value(), Attribute.SyncMode.SILENT)
	
	return tag
