class_name SVGDB extends RefCounted

const known_tags = ["svg", "circle", "ellipse", "rect", "path", "line", "stop"]

const known_tag_attributes = {  # Dictionary{String: Array[String]}
	"svg": TagSVG.known_attributes,
	"circle": TagCircle.known_attributes,
	"ellipse": TagEllipse.known_attributes,
	"rect": TagRect.known_attributes,
	"path": TagPath.known_attributes,
	"line": TagLine.known_attributes,
	"stop": TagStop.known_attributes,
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
		"stop": return TagStop.icon
		_: return TagUnknown.icon
