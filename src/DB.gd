class_name DB extends RefCounted

enum AttributeType {NUMERIC, COLOR, LIST, PATHDATA, ENUM, TRANSFORM_LIST, ID, UNKNOWN}

const recognized_tags = ["svg", "g", "circle", "ellipse", "rect", "path", "line", "stop",
		"linearGradient", "radialGradient"]

const tag_icons = {
	"circle": preload("res://visual/icons/tag/circle.svg"),
	"ellipse": preload("res://visual/icons/tag/ellipse.svg"),
	"rect": preload("res://visual/icons/tag/rect.svg"),
	"path": preload("res://visual/icons/tag/path.svg"),
	"line": preload("res://visual/icons/tag/line.svg"),
	"g": preload("res://visual/icons/tag/g.svg"),
	"linearGradient": preload("res://visual/icons/tag/linearGradient.svg"),
	"radialGradient": preload("res://visual/icons/tag/radialGradient.svg"),
	"stop": preload("res://visual/icons/tag/stop.svg"),
}
const unrecognized_tag_icon = preload("res://visual/icons/tag/unrecognized.svg")

const recognized_attributes = {  # Dictionary{String: Array[String]}
	# TODO this is just propagated_attributes, but it ruins the const because of Godot bug.
	"svg": ["xmlns", "width", "height", "viewBox", "fill", "fill-opacity", "stroke",
			"stroke-opacity", "stroke-width", "stroke-linecap", "stroke-linejoin"],
	"g": ["transform", "opacity", "fill", "fill-opacity", "stroke", "stroke-opacity",
			"stroke-width", "stroke-linecap", "stroke-linejoin"],
	"linearGradient": ["id", "gradientTransform", "gradientUnits", "x1", "y1", "x2", "y2"],
	"radialGradient": ["id", "gradientTransform", "gradientUnits", "cx", "cy", "r"],
	"circle": ["transform", "opacity", "fill", "fill-opacity", "stroke", "stroke-opacity",
			"stroke-width", "cx", "cy", "r"],
	"ellipse": ["transform", "opacity", "fill", "fill-opacity", "stroke", "stroke-opacity",
			"stroke-width", "cx", "cy", "rx", "ry"],
	"rect": ["transform", "opacity", "fill", "fill-opacity", "stroke", "stroke-opacity",
			"stroke-width", "stroke-linejoin", "x", "y", "width", "height", "rx", "ry"],
	"path": ["transform", "opacity", "fill", "fill-opacity", "stroke", "stroke-opacity",
			"stroke-width", "stroke-linecap", "stroke-linejoin", "d"],
	"line": ["transform", "opacity", "stroke", "stroke-opacity", "stroke-width",
			"stroke-linecap", "x1", "y1", "x2", "y2"],
	"stop": ["offset", "stop-color", "stop-opacity"],
}

const propagated_attributes = ["fill", "fill-opacity", "stroke", "stroke-opacity",
		"stroke-width", "stroke-linecap", "stroke-linejoin"]

const attribute_types = {
	"viewBox": AttributeType.LIST,
	"width": AttributeType.NUMERIC,
	"height": AttributeType.NUMERIC,
	"x": AttributeType.NUMERIC,
	"y": AttributeType.NUMERIC,
	"x1": AttributeType.NUMERIC,
	"y1": AttributeType.NUMERIC,
	"x2": AttributeType.NUMERIC,
	"y2": AttributeType.NUMERIC,
	"cx": AttributeType.NUMERIC,
	"cy": AttributeType.NUMERIC,
	"r": AttributeType.NUMERIC,
	"rx": AttributeType.NUMERIC,
	"ry": AttributeType.NUMERIC,
	"opacity": AttributeType.NUMERIC,
	"fill": AttributeType.COLOR,
	"fill-opacity": AttributeType.NUMERIC,
	"stroke": AttributeType.COLOR,
	"stroke-opacity": AttributeType.NUMERIC,
	"stroke-width": AttributeType.NUMERIC,
	"stroke-linecap": AttributeType.ENUM,
	"stroke-linejoin": AttributeType.ENUM,
	"d": AttributeType.PATHDATA,
	"transform": AttributeType.TRANSFORM_LIST,
	"offset": AttributeType.NUMERIC,
	"stop-color": AttributeType.COLOR,
	"stop-opacity": AttributeType.NUMERIC,
	"id": AttributeType.ID,
	"gradientTransform": AttributeType.TRANSFORM_LIST,
	"gradientUnits": AttributeType.ENUM,
}

const attribute_enum_values = {
	"stroke-linecap": ["butt", "round", "square"],
	"stroke-linejoin": ["miter", "round", "bevel"],
	"gradientUnits": ["userSpaceOnUse", "objectBoundingBox"]
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


static func is_attribute_recognized(tag_name: String, attribute_name: String) -> bool:
	return recognized_attributes.has(tag_name) and\
			attribute_name in recognized_attributes[tag_name]

static func get_tag_icon(tag_name: String) -> Texture2D:
	return tag_icons[tag_name] if tag_icons.has(tag_name) else unrecognized_tag_icon

static func get_attribute_type(attribute_name: String) -> AttributeType:
	return attribute_types[attribute_name] if attribute_types.has(attribute_name)\
			else AttributeType.UNKNOWN

# Creates an attribute with a certain value.
static func attribute(name: String, initial_value := "") -> Attribute:
	match get_attribute_type(name):
		AttributeType.NUMERIC: return AttributeNumeric.new(name, initial_value)
		AttributeType.COLOR: return AttributeColor.new(name, initial_value)
		AttributeType.LIST: return AttributeList.new(name, initial_value)
		AttributeType.PATHDATA: return AttributePathdata.new(name, initial_value)
		AttributeType.ENUM: return AttributeEnum.new(name, initial_value)
		AttributeType.TRANSFORM_LIST: return AttributeTransformList.new(name, initial_value)
		AttributeType.ID: return AttributeID.new(name, initial_value)
		_: return Attribute.new(name, initial_value)

static func tag(name: String, user_setup_value = null) -> Tag:
	var tag: Tag
	match name:
		"svg": tag = TagSVG.new()
		"g": tag = TagG.new()
		"circle": tag = TagCircle.new()
		"ellipse": tag = TagEllipse.new()
		"rect": tag = TagRect.new()
		"path": tag = TagPath.new()
		"line": tag = TagLine.new()
		"linearGradient": tag = TagLinearGradient.new()
		"radialGradient": tag = TagRadialGradient.new()
		"stop": tag = TagStop.new()
		_: tag = TagUnrecognized.new(name)
	if user_setup_value != null:
		tag.user_setup(user_setup_value)
	return tag
