class_name SVGDB extends RefCounted

const known_tags = ["svg", "circle", "ellipse", "rect", "path", "line"]

const known_tag_attributes = {  # Dictionary{}
	"svg": TagSVG.known_attributes,
	"circle": TagCircle.known_geometry_attributes + TagCircle.known_paint_attributes,
	"ellipse": TagEllipse.known_geometry_attributes + TagEllipse.known_paint_attributes,
	"rect": TagRect.known_geometry_attributes + TagRect.known_paint_attributes,
	"path": TagPath.known_geometry_attributes + TagPath.known_paint_attributes,
	"line": TagLine.known_geometry_attributes + TagLine.known_paint_attributes,
}

static func is_tag_known(tag_name: String) -> bool:
	return tag_name in known_tags

static func is_attribute_known(tag_name: String, attribute_name: String) -> bool:
	if not known_tag_attributes.has(tag_name):
		return false
	return attribute_name in known_tag_attributes[tag_name]
