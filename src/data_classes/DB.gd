## A central database for SVG element and attribute definitions.
@abstract class_name DB

enum AttributeType {NUMERIC, COLOR, LIST, PATHDATA, ENUM, TRANSFORM_LIST, ID, HREF, UNKNOWN}
enum PercentageHandling {FRACTION, HORIZONTAL, VERTICAL, NORMALIZED}
enum NumberRange {ARBITRARY, POSITIVE, UNIT}


const _RECOGNIZED_ELEMENTS: PackedStringArray = ["svg", "g", "circle", "ellipse", "rect", "path", "line", "polyline", "polygon",
		"stop", "linearGradient", "radialGradient", "use"]

const _ELEMENT_ICONS: Dictionary[String, Texture2D] = {
	"circle": preload("res://assets/icons/element/circle.svg"),
	"ellipse": preload("res://assets/icons/element/ellipse.svg"),
	"rect": preload("res://assets/icons/element/rect.svg"),
	"path": preload("res://assets/icons/element/path.svg"),
	"line": preload("res://assets/icons/element/line.svg"),
	"polygon":  preload("res://assets/icons/element/polygon.svg"),
	"polyline":  preload("res://assets/icons/element/polyline.svg"),
	"svg": preload("res://assets/icons/element/svg.svg"),
	"g": preload("res://assets/icons/element/g.svg"),
	"linearGradient": preload("res://assets/icons/element/linearGradient.svg"),
	"radialGradient": preload("res://assets/icons/element/radialGradient.svg"),
	"stop": preload("res://assets/icons/element/stop.svg"),
	"use": preload("res://assets/icons/element/use.svg"),
}
const _UNRECOGNIZED_XNODE_ICON = preload("res://assets/icons/element/unrecognized.svg")

const _XNODE_ICONS: Dictionary[BasicXNode.NodeType, Texture2D] = {
	BasicXNode.NodeType.COMMENT: preload("res://assets/icons/element/xmlnodeComment.svg"),
	BasicXNode.NodeType.TEXT: preload("res://assets/icons/element/xmlnodeText.svg"),
	BasicXNode.NodeType.CDATA: preload("res://assets/icons/element/xmlnodeCDATA.svg"),
}

const _RECOGNIZED_ATTRIBUTES: Dictionary[String, Array] = {
	# TODO this is just PROPAGATED_ATTRIBUTES, but it ruins the const because of Godot bug.
	# TODO Add "color" to "g" when we're ready.
	"svg": ["xmlns", "x", "y", "width", "height", "viewBox", "fill", "fill-opacity",
			"stroke", "stroke-opacity", "stroke-width", "stroke-linecap", "stroke-linejoin", "color"],
	"g": ["transform", "opacity", "fill", "fill-opacity", "stroke", "stroke-opacity",
			"stroke-width", "stroke-linecap", "stroke-linejoin"],
	"linearGradient": ["id", "gradientTransform", "gradientUnits", "spreadMethod",
			"x1", "y1", "x2", "y2"],
	"radialGradient": ["id", "gradientTransform", "gradientUnits", "spreadMethod",
			"cx", "cy", "r", "fx", "fy"],
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
	"polygon": ["transform", "opacity", "fill", "fill-opacity", "stroke", "stroke-opacity",
			"stroke-width", "stroke-linejoin", "points"],
	"polyline": ["transform", "opacity", "fill", "fill-opacity", "stroke",
			"stroke-opacity", "stroke-width", "stroke-linecap", "stroke-linejoin", "points"],
	"stop": ["offset", "stop-color", "stop-opacity"],
	"use": ["href", "transform", "x", "y"]
}

const _VALID_CHILDREN: Dictionary[String, Array] = {
	"svg": ["svg", "path", "circle", "ellipse", "rect", "line", "polygon", "polyline", "g", "linearGradient", "radialGradient", "use"],
	"g": ["svg", "path", "circle", "ellipse", "rect", "line", "polygon", "polyline", "g", "linearGradient", "radialGradient", "use"],
	"linearGradient": ["stop"],
	"radialGradient": ["stop"],
	"circle": [],
	"ellipse": [],
	"rect": [],
	"path": [],
	"line": [],
	"polygon": [],
	"polyline": [],
	"stop": [],
	"use": [],
}

const PROPAGATED_ATTRIBUTES: PackedStringArray = ["fill", "fill-opacity", "stroke", "stroke-opacity", "stroke-width", "stroke-linecap", "stroke-linejoin",
		"color"]

const _ATTRIBUTE_TYPES: Dictionary[String, AttributeType] = {
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
	"fx": AttributeType.NUMERIC,
	"fy": AttributeType.NUMERIC,
	"opacity": AttributeType.NUMERIC,
	"fill": AttributeType.COLOR,
	"fill-opacity": AttributeType.NUMERIC,
	"stroke": AttributeType.COLOR,
	"stroke-opacity": AttributeType.NUMERIC,
	"stroke-width": AttributeType.NUMERIC,
	"stroke-linecap": AttributeType.ENUM,
	"stroke-linejoin": AttributeType.ENUM,
	"color": AttributeType.COLOR,
	"d": AttributeType.PATHDATA,
	"points": AttributeType.LIST,
	"transform": AttributeType.TRANSFORM_LIST,
	"offset": AttributeType.NUMERIC,
	"stop-color": AttributeType.COLOR,
	"stop-opacity": AttributeType.NUMERIC,
	"id": AttributeType.ID,
	"gradientTransform": AttributeType.TRANSFORM_LIST,
	"gradientUnits": AttributeType.ENUM,
	"spreadMethod": AttributeType.ENUM,
	"href": AttributeType.HREF,
}

const ATTRIBUTE_ENUM_VALUES: Dictionary[String, Array] = {
	"stroke-linecap": ["butt", "round", "square"],
	"stroke-linejoin": ["miter", "round", "bevel"],
	"gradientUnits": ["userSpaceOnUse", "objectBoundingBox"],
	"spreadMethod": ["pad", "reflect", "repeat"],
}

const ATTRIBUTE_NUMBER_RANGE: Dictionary[String, NumberRange] = {
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
	"fx": NumberRange.ARBITRARY,
	"fy": NumberRange.ARBITRARY,
	"opacity": NumberRange.UNIT,
	"fill-opacity": NumberRange.UNIT,
	"stroke-opacity": NumberRange.UNIT,
	"stroke-width": NumberRange.POSITIVE,
	"offset": NumberRange.UNIT,
	"stop-opacity": NumberRange.UNIT,
}

const COLOR_ATTRIBUTES_WITH_URL_ALLOWED: PackedStringArray = ["fill", "stroke"]
const COLOR_ATTRIBUTES_WITH_NONE_ALLOWED: PackedStringArray = ["fill", "stroke"]
const COLOR_ATTRIBUTES_WITH_CURRENT_COLOR_ALLOWED: PackedStringArray = ["fill", "stroke", "stop-color"]

static func is_element_recognized(element_name: String) -> bool:
	return _RECOGNIZED_ELEMENTS.has(element_name)

## Get all recognized attributes for a specific element.
static func get_recognized_attributes(element_name: String) -> Array:
	return _RECOGNIZED_ATTRIBUTES.get(element_name, [])

## Check if an attribute is recognized for a given element.
static func is_attribute_recognized(element_name: String, attribute_name: String) -> bool:
	return _RECOGNIZED_ATTRIBUTES.has(element_name) and attribute_name in _RECOGNIZED_ATTRIBUTES[element_name]

## Check if the given child element is valid for the given parent element.
static func is_child_element_valid(parent_name: String, child_name: String) -> bool:
	if not parent_name in _RECOGNIZED_ELEMENTS or not child_name in _RECOGNIZED_ELEMENTS:
		return true
	return child_name in _VALID_CHILDREN[parent_name]

## Get all valid parent elements for a given child element.
static func get_valid_parents(child_name: String) -> PackedStringArray:
	var valid_parents := PackedStringArray()
	for parent_name in _VALID_CHILDREN:
		if child_name in _VALID_CHILDREN[parent_name]:
			valid_parents.append(parent_name)
	return valid_parents

## Get the icon for an element type.
static func get_element_icon(element_name: String) -> Texture2D:
	return _ELEMENT_ICONS.get(element_name, _UNRECOGNIZED_XNODE_ICON)

## Get the icon for an XML node that's not an element.
static func get_xnode_icon(xnode_type: BasicXNode.NodeType) -> Texture2D:
	return _XNODE_ICONS.get(xnode_type, _UNRECOGNIZED_XNODE_ICON)

## Get the data type for an attribute.
static func get_attribute_type(attribute_name: String) -> AttributeType:
	return _ATTRIBUTE_TYPES.get(attribute_name, AttributeType.UNKNOWN)

## Get default percentage handling behavior for numeric attributes.
static func get_attribute_default_percentage_handling(attribute_name: String) -> PercentageHandling:
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
		"fx": return PercentageHandling.HORIZONTAL
		"fy": return PercentageHandling.VERTICAL
		"r": return PercentageHandling.NORMALIZED
		_: return PercentageHandling.FRACTION

## Create an element with initial arbitrary setup values based on that element's user_setup() method.
static func element_with_setup(name: String, user_setup_values: Array) -> Element:
	var new_element := element(name)
	new_element.user_setup.callv(user_setup_values)
	return new_element

## Factory method to create typed element instances.
static func element(name: String) -> Element:
	match name:
		"svg": return ElementSVG.new()
		"g": return ElementG.new()
		"circle": return ElementCircle.new()
		"ellipse": return ElementEllipse.new()
		"rect": return ElementRect.new()
		"path": return ElementPath.new()
		"line": return ElementLine.new()
		"polygon": return ElementPolygon.new()
		"polyline": return ElementPolyline.new()
		"linearGradient": return ElementLinearGradient.new()
		"radialGradient": return ElementRadialGradient.new()
		"stop": return ElementStop.new()
		"use": return ElementUse.new()
		_: return ElementUnrecognized.new(name)

## Factory method to create typed attribute instances.
static func attribute(name: String, value: String) -> Attribute:
	match DB.get_attribute_type(name):
		DB.AttributeType.NUMERIC: return AttributeNumeric.new(name, value)
		DB.AttributeType.COLOR: return AttributeColor.new(name, value)
		DB.AttributeType.LIST: return AttributeList.new(name, value)
		DB.AttributeType.PATHDATA: return AttributePathdata.new(name, value)
		DB.AttributeType.ENUM: return AttributeEnum.new(name, value)
		DB.AttributeType.TRANSFORM_LIST: return AttributeTransformList.new(name, value)
		DB.AttributeType.ID: return AttributeID.new(name, value)
		DB.AttributeType.HREF: return AttributeHref.new(name, value)
		_: return Attribute.new(name, value)
