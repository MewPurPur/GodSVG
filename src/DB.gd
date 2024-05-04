class_name DB extends RefCounted

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

const attribute_defaults = {
	"viewBox": "",
	"width": "0",
	"height": "0",
	"x": "0",
	"y": "0",
	"x1": "0",
	"y1": "0",
	"x2": "0",
	"y2": "0",
	"cx": "0",
	"cy": "0",
	"r": "0",
	"rx": "0",
	"ry": "0",
	"opacity": "1",
	"fill": "black",
	"fill-opacity": "1",
	"stroke": "none",
	"stroke-opacity": "1",
	"stroke-width": "1",
	"stroke-linecap": "butt",
	"stroke-linejoin": "miter",
	"d": "",
	"transform": "",
	"offset": "0",
	"stop-color": "black",
	"stop-opacity": "1",
}

const attribute_enum_values = {
	"stroke-linecap": ["butt", "round", "square"],
	"stroke-linejoin": ["miter", "round", "bevel"],
}

const attribute_numeric_bounds = {
	"width": Vector2(0, INF),
	"height": Vector2(0, INF),
	"x": Vector2(-INF, INF),
	"y": Vector2(-INF, INF),
	"x1": Vector2(-INF, INF),
	"y1": Vector2(-INF, INF),
	"x2": Vector2(-INF, INF),
	"y2": Vector2(-INF, INF),
	"cx": Vector2(-INF, INF),
	"cy": Vector2(-INF, INF),
	"r": Vector2(0, INF),
	"rx": Vector2(0, INF),
	"ry": Vector2(0, INF),
	"opacity": Vector2(0, 1),
	"fill-opacity": Vector2(0, 1),
	"stroke-opacity": Vector2(0, 1),
	"stroke-width": Vector2(0, INF),
	"offset": Vector2(0, 1),
	"stop-opacity": Vector2(0, 1),
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

static func attribute(name: String, initial_value := "") -> Attribute:
	match name:
		"viewBox": return AttributeList.new(name, initial_value)
		"width": return AttributeNumeric.new(name, initial_value)
		"height": return AttributeNumeric.new(name, initial_value)
		"x": return AttributeNumeric.new(name, initial_value)
		"y": return AttributeNumeric.new(name, initial_value)
		"x1": return AttributeNumeric.new(name, initial_value)
		"y1": return AttributeNumeric.new(name, initial_value)
		"x2": return AttributeNumeric.new(name, initial_value)
		"y2": return AttributeNumeric.new(name, initial_value)
		"cx": return AttributeNumeric.new(name, initial_value)
		"cy": return AttributeNumeric.new(name, initial_value)
		"r": return AttributeNumeric.new(name, initial_value)
		"rx": return AttributeNumeric.new(name, initial_value)
		"ry": return AttributeNumeric.new(name, initial_value)
		"opacity": return AttributeNumeric.new(name, initial_value)
		"fill": return AttributeColor.new(name, initial_value)
		"fill-opacity": return AttributeNumeric.new(name, initial_value)
		"stroke": return AttributeColor.new(name, initial_value)
		"stroke-opacity": return AttributeNumeric.new(name, initial_value)
		"stroke-width": return AttributeNumeric.new(name, initial_value)
		"stroke-linecap": return AttributeEnum.new(name, initial_value)
		"stroke-linejoin": return AttributeEnum.new(name, initial_value)
		"d": return AttributePath.new(name, initial_value)
		"transform": return AttributeTransform.new(name, initial_value)
		"offset": return AttributeNumeric.new(name, initial_value)
		"stop-color": return AttributeColor.new(name, initial_value)
		"stop-opacity": return AttributeNumeric.new(name, initial_value)
		_: return Attribute.new(name, initial_value)
