class_name DB extends RefCounted

enum AttributeType {NUMERIC, COLOR, LIST, PATHDATA, ENUM, TRANSFORM_LIST, ID, UNKNOWN}
enum PercentageHandling {FRACTION, HORIZONTAL, VERTICAL, NORMALIZED}
enum NumberRange {ARBITRARY, POSITIVE, UNIT}


const recognized_elements = ["svg", "g", "circle", "ellipse", "rect", "path", "line",
		"stop", "linearGradient", "radialGradient"]

const element_icons = {
	"circle": preload("res://visual/icons/element/circle.svg"),
	"ellipse": preload("res://visual/icons/element/ellipse.svg"),
	"rect": preload("res://visual/icons/element/rect.svg"),
	"path": preload("res://visual/icons/element/path.svg"),
	"line": preload("res://visual/icons/element/line.svg"),
	"svg": preload("res://visual/icons/element/svg.svg"),
	"g": preload("res://visual/icons/element/g.svg"),
	"linearGradient": preload("res://visual/icons/element/linearGradient.svg"),
	"radialGradient": preload("res://visual/icons/element/radialGradient.svg"),
	"stop": preload("res://visual/icons/element/stop.svg"),
}
const unrecognized_xnode_icon = preload("res://visual/icons/element/unrecognized.svg")

const xnode_icons = {
	BasicXNode.NodeType.COMMENT: preload("res://visual/icons/element/xmlnodeComment.svg"),
	BasicXNode.NodeType.TEXT: preload("res://visual/icons/element/xmlnodeText.svg"),
	BasicXNode.NodeType.CDATA: preload("res://visual/icons/element/xmlnodeCDATA.svg"),
}

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

const valid_children = {  # Dictionary{String: Array[String]}
	"svg": ["svg", "path", "circle", "ellipse", "rect", "line", "g", "linearGradient",
			"radialGradient"],
	"g": ["svg", "path", "circle", "ellipse", "rect", "line", "g", "linearGradient",
			"radialGradient"],
	"linearGradient": ["stop"],
	"radialGradient": ["stop"],
	"circle": [],
	"ellipse": [],
	"rect": [],
	"path": [],
	"line": [],
	"stop": [],
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

const attribute_number_range = {
	"width": NumberRange.POSITIVE,
	"height": NumberRange.POSITIVE,
	"x": NumberRange.ARBITRARY,
	"y": NumberRange.ARBITRARY,
	"x1": NumberRange.ARBITRARY,
	"y1": NumberRange.ARBITRARY,
	"x2": NumberRange.ARBITRARY,
	"y2": NumberRange.ARBITRARY,
	"cx": NumberRange.ARBITRARY,
	"cy": NumberRange.ARBITRARY,
	"r": NumberRange.POSITIVE,
	"rx": NumberRange.POSITIVE,
	"ry": NumberRange.POSITIVE,
	"opacity": NumberRange.UNIT,
	"fill-opacity": NumberRange.UNIT,
	"stroke-opacity": NumberRange.UNIT,
	"stroke-width": NumberRange.POSITIVE,
	"offset": NumberRange.UNIT,
	"stop-opacity": NumberRange.UNIT,
}

const attribute_color_url_allowed = ["fill", "stroke"]


static func is_attribute_recognized(element_name: String, attribute_name: String) -> bool:
	return recognized_attributes.has(element_name) and\
			attribute_name in recognized_attributes[element_name]

static func is_child_element_valid(parent_name: String, child_name: String) -> bool:
	if not parent_name in recognized_elements or not child_name in recognized_elements:
		return true
	return child_name in valid_children[parent_name]

static func get_valid_parents(child_name: String) -> PackedStringArray:
	var valid_parents := PackedStringArray()
	for parent_name in valid_children.keys():
		if child_name in valid_children[parent_name]:
			valid_parents.append(parent_name)
	return valid_parents

static func get_element_icon(element_name: String) -> Texture2D:
	return element_icons[element_name] if element_icons.has(element_name) else\
			unrecognized_xnode_icon

static func get_xnode_icon(xnode_type: BasicXNode.NodeType) -> Texture2D:
	return xnode_icons[xnode_type] if xnode_icons.has(xnode_type) else\
			unrecognized_xnode_icon


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
