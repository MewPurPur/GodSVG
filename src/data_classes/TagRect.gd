# A <rect/> tag.
class_name TagRect extends Tag

const name = "rect"
const possible_conversions = ["circle", "ellipse", "path"]
const icon = preload("res://visual/icons/tag/rect.svg")

const known_attributes = ["x", "y", "width", "height", "rx", "ry", "transform",
		"opacity", "fill", "fill-opacity", "stroke", "stroke-opacity", "stroke-width",
		"stroke-linejoin"]

func _init(pos := Vector2.ZERO) -> void:
	for attrib_name in ["transform", "x", "y", "rx", "ry", "opacity", "fill",
	"fill-opacity", "stroke", "stroke-opacity", "stroke-width", "stroke-linejoin"]:
		attributes[attrib_name] = DB.attribute(attrib_name)
	attributes.width = DB.attribute("width", "1")
	attributes.height = DB.attribute("height", "1")
	if pos != Vector2.ZERO:
		attributes.x.set_num(pos.x)
		attributes.y.set_num(pos.y)
	super()


func can_replace(new_tag: String) -> bool:
	if new_tag == "ellipse":
		var rx: float = attributes.rx.get_num()
		var ry: float = attributes.ry.get_num()
		if rx == 0:
			rx = ry
		elif ry == 0:
			ry = rx
		return rx >= attributes.width.get_num() / 2 and ry >= attributes.height.get_num() / 2
	elif new_tag == "circle":
		var rx: float = attributes.rx.get_num()
		var ry: float = attributes.ry.get_num()
		if rx == 0:
			rx = ry
		elif ry == 0:
			ry = rx
		var side: float = attributes.width.get_num()
		return attributes.height.get_num() == side and rx >= side / 2 and ry >= side / 2
	else:
		return new_tag == "path"

func get_replacement(new_tag: String) -> Tag:
	if not can_replace(new_tag):
		return null
	
	var tag: Tag
	var retained_attributes: Array[String] = []
	match new_tag:
		"ellipse":
			tag = TagEllipse.new()
			retained_attributes = ["transform", "opacity", "fill", "fill-opacity", "stroke",
					"stroke-opacity", "stroke-width"]
			tag.attributes.rx.set_num(attributes.width.get_num() / 2,
					Attribute.SyncMode.SILENT)
			tag.attributes.ry.set_num(attributes.height.get_num() / 2,
					Attribute.SyncMode.SILENT)
			tag.attributes.cx.set_num(attributes.x.get_num() +\
					attributes.width.get_num() / 2, Attribute.SyncMode.SILENT)
			tag.attributes.cy.set_num(attributes.y.get_num() +\
					attributes.height.get_num() / 2, Attribute.SyncMode.SILENT)
		"circle":
			tag = TagCircle.new()
			retained_attributes = ["transform", "opacity", "fill", "fill-opacity",
					"stroke", "stroke-opacity", "stroke-width"]
			tag.attributes.r.set_num(attributes.width.get_num() / 2,
					Attribute.SyncMode.SILENT)
			tag.attributes.cx.set_num(attributes.x.get_num() +\
					attributes.width.get_num() / 2, Attribute.SyncMode.SILENT)
			tag.attributes.cy.set_num(attributes.y.get_num() +\
					attributes.height.get_num() / 2, Attribute.SyncMode.SILENT)
		"path":
			tag = TagPath.new()
			retained_attributes = ["transform", "opacity", "fill", "fill-opacity", "stroke",
					"stroke-opacity", "stroke-width", "stroke-linejoin"]
			var rx := minf(attributes.rx.get_num(), attributes.width.get_num() / 2)
			var ry := minf(attributes.ry.get_num(), attributes.height.get_num() / 2)
			var commands: Array[PathCommand] = []
			if rx == 0 and ry == 0:
				commands.append(PathCommand.MoveCommand.new(attributes.x.get_num(),
						attributes.y.get_num(), true))
				commands.append(PathCommand.HorizontalLineCommand.new(
						attributes.width.get_num(), true))
				commands.append(PathCommand.VerticalLineCommand.new(
						attributes.height.get_num(), true))
				commands.append(PathCommand.HorizontalLineCommand.new(
						-attributes.width.get_num(), true))
				commands.append(PathCommand.CloseCommand.new(true))
			else:
				if rx == 0:
					rx = ry
				elif ry == 0:
					ry = rx
				var w: float = attributes.width.get_num() - rx * 2
				var h: float = attributes.height.get_num() - ry * 2
				
				commands.append(PathCommand.MoveCommand.new(attributes.x.get_num(),
						attributes.y.get_num() + ry, true))
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
			tag.attributes.d.set_commands(commands, Attribute.SyncMode.SILENT)
			
	for k in retained_attributes:
		tag.attributes[k].set_value(attributes[k].get_value(), Attribute.SyncMode.SILENT)
	tag.child_tags = child_tags
	
	return tag
