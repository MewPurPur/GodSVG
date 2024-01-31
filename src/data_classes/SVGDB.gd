class_name SVGDB extends RefCounted

const known_tags = ["svg", "circle", "ellipse", "rect", "path", "line"]

const known_tag_attributes = {  # Dictionary{String: Array[String]}
	"svg": TagSVG.known_attributes,
	"circle": TagCircle.known_shape_attributes + TagCircle.known_inheritable_attributes,
	"ellipse": TagEllipse.known_shape_attributes + TagEllipse.known_inheritable_attributes,
	"rect": TagRect.known_shape_attributes + TagRect.known_inheritable_attributes,
	"path": TagPath.known_shape_attributes + TagPath.known_inheritable_attributes,
	"line": TagLine.known_shape_attributes + TagLine.known_inheritable_attributes,
}

static func is_tag_known(tag_name: String) -> bool:
	return tag_name in known_tags

static func is_attribute_known(tag_name: String, attribute_name: String) -> bool:
	if not known_tag_attributes.has(tag_name):
		return false
	return attribute_name in known_tag_attributes[tag_name]

static func get_tag_icon(tag_name: String) -> Texture2D:
	match tag_name:
		"circle": return TagCircle.icon
		"ellipse": return TagEllipse.icon
		"rect": return TagRect.icon
		"path": return TagPath.icon
		"line": return TagLine.icon
		_: return TagUnknown.icon
