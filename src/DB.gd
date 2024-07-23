class_name DB extends RefCounted

enum AttributeType {NUMERIC, COLOR, LIST, PATHDATA, ENUM, TRANSFORM_LIST, ID, UNKNOWN}
enum PercentageHandling {FRACTION, HORIZONTAL, VERTICAL, NORMALIZED}


const recognized_elements = ["svg", "g", "circle", "ellipse", "rect", "path", "line",
		"stop", "linearGradient", "radialGradient"]

const element_icons = {
	"circle": preload("res://visual/icons/element/circle.svg"),
	"ellipse": preload("res://visual/icons/element/ellipse.svg"),
	"rect": preload("res://visual/icons/element/rect.svg"),
	"path": preload("res://visual/icons/element/path.svg"),
	"line": preload("res://visual/icons/element/line.svg"),
	"g": preload("res://visual/icons/element/g.svg"),
	"linearGradient": preload("res://visual/icons/element/linearGradient.svg"),
	"radialGradient": preload("res://visual/icons/element/radialGradient.svg"),
	"stop": preload("res://visual/icons/element/stop.svg"),
}
const unrecognized_element_icon = preload("res://visual/icons/element/unrecognized.svg")

const recognized_attributes = {  # Dictionary{String: Array[String]}
	# TODO this is just propagated_attributes, but it ruins the const because of Godot bug.
	"svg": ["xmlns", "width", "height", "viewBox", "fill", "fill-opacity", "stroke",
			"stroke-opacity", "stroke-width", "stroke-linecap", "stroke-linejoin"],
	"g": ["transform", "opacity", "fill", "fill-opacity", "stroke", "stroke-opacity",
			"stroke-width", "stroke-linecap", "stroke-linejoin"],
	"linearGradient": ["id", "gradientTransform", "gradientUnits", "spreadMethod",
			"x1", "y1", "x2", "y2"],
	"radialGradient": ["id", "gradientTransform", "gradientUnits", "spreadMethod",
			"cx", "cy", "r"],
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
	"spreadMethod": AttributeType.ENUM,
}

const attribute_enum_values = {
	"stroke-linecap": ["butt", "round", "square"],
	"stroke-linejoin": ["miter", "round", "bevel"],
	"gradientUnits": ["userSpaceOnUse", "objectBoundingBox"],
	"spreadMethod": ["pad", "reflect", "repeat"],
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


static func is_attribute_recognized(element_name: String, attribute_name: String) -> bool:
	return recognized_attributes.has(element_name) and\
			attribute_name in recognized_attributes[element_name]

static func get_element_icon(element_name: String) -> Texture2D:
	return element_icons[element_name] if element_icons.has(element_name) else\
			unrecognized_element_icon

static func get_attribute_type(attribute_name: String) -> AttributeType:
	return attribute_types[attribute_name] if attribute_types.has(attribute_name)\
			else AttributeType.UNKNOWN

static func get_attribute_default_percentage_handling(
attribute_name: String) -> PercentageHandling:
	match attribute_name:
		"width": return PercentageHandling.HORIZONTAL
		"height": return PercentageHandling.VERTICAL
		"x": return PercentageHandling.HORIZONTAL
		"y": return PercentageHandling.VERTICAL
		"rx": return PercentageHandling.HORIZONTAL
		"ry": return PercentageHandling.VERTICAL
		"stroke-width": return PercentageHandling.NORMALIZED
		"x1": return PercentageHandling.HORIZONTAL
		"y1": return PercentageHandling.VERTICAL
		"x2": return PercentageHandling.HORIZONTAL
		"y2": return PercentageHandling.VERTICAL
		"cx": return PercentageHandling.HORIZONTAL
		"cy": return PercentageHandling.VERTICAL
		"r": return PercentageHandling.NORMALIZED
		_: return PercentageHandling.FRACTION


static func element_with_setup(name: String, user_setup_value = null) -> Element:
	var new_element := element(name)
	if user_setup_value != null:
		new_element.user_setup(user_setup_value)
	else:
		new_element.user_setup()
	return new_element

static func element(name: String) -> Element:
	match name:
		"svg": return ElementSVG.new()
		"g": return ElementG.new()
		"circle": return ElementCircle.new()
		"ellipse": return ElementEllipse.new()
		"rect": return ElementRect.new()
		"path": return ElementPath.new()
		"line": return ElementLine.new()
		"linearGradient": return ElementLinearGradient.new()
		"radialGradient": return ElementRadialGradient.new()
		"stop": return ElementStop.new()
		_: return ElementUnrecognized.new(name)
