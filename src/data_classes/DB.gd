## A central database for SVG element and attribute definitions.
@abstract class_name DB

enum AttributeType {NUMERIC_FRACTION, NUMERIC_ARBITRARY, NUMERIC_POSITIVE, PERCENTAGE,
		COLOR, URL, PAINT, LIST, DASHARRAY, PATHDATA, TRANSFORM_LIST, ID, HREF, NONE}
enum PercentageHandling {FRACTION, HORIZONTAL, VERTICAL, NORMALIZED}


const _RECOGNIZED_ELEMENTS: PackedStringArray = ["svg", "g", "circle", "ellipse", "rect", "path", "line", "polyline", "polygon",
		"stop", "linearGradient", "radialGradient", "use"]
		#"stop", "linearGradient", "radialGradient", "use", "marker", "clipPath", "mask", "image", "text", "tspan"]

const _ELEMENT_ICONS: Dictionary[String, Texture2D] = {
	"circle": preload("res://assets/icons/element/circle.svg"),
	"ellipse": preload("res://assets/icons/element/ellipse.svg"),
	"rect": preload("res://assets/icons/element/rect.svg"),
	"path": preload("res://assets/icons/element/path.svg"),
	"line": preload("res://assets/icons/element/line.svg"),
	"polygon": preload("res://assets/icons/element/polygon.svg"),
	"polyline": preload("res://assets/icons/element/polyline.svg"),
	"svg": preload("res://assets/icons/element/svg.svg"),
	"g": preload("res://assets/icons/element/g.svg"),
	"linearGradient": preload("res://assets/icons/element/linearGradient.svg"),
	"radialGradient": preload("res://assets/icons/element/radialGradient.svg"),
	"stop": preload("res://assets/icons/element/stop.svg"),
	# Not currently in GUI.
	"use": preload("res://assets/icons/element/use.svg"),
	#"marker": preload("res://assets/icons/element/unrecognized.svg"),
	#"clipPath": preload("res://assets/icons/element/unrecognized.svg"),
	#"mask": preload("res://assets/icons/element/mask.svg"),
	#"image": preload("res://assets/icons/element/image.svg"),
	#"text": preload("res://assets/icons/element/text.svg"),
	#"tspan": preload("res://assets/icons/element/unrecognized.svg"),
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
	"use": ["href", "transform", "x", "y"],
	#"marker": ["id", "markerUnits"],
	#"clipPath": ["id", "clipPathUnits"],
	#"mask": ["id"],
	#"image": ["x", "y", "width", "height", "href"],
	#"text": ["x", "y"],
	#"tspan": ["x", "y"],
}

const _VALID_CHILDREN: Dictionary[String, Array] = {
	"svg": ["svg", "path", "circle", "ellipse", "rect", "line", "polygon", "polyline", "g", "linearGradient", "radialGradient",
			"use", "marker", "clipPath", "mask", "text", "tspan"],
	"g": ["svg", "path", "circle", "ellipse", "rect", "line", "polygon", "polyline", "g", "linearGradient", "radialGradient", "use", "text", "tspan"],
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
	#"marker": ["path", "circle", "ellipse", "rect", "line", "polygon", "polyline", "g"],
	#"clipPath": ["path", "circle", "ellipse", "rect", "line", "polygon", "polyline", "g"],
	#"mask": ["path", "circle", "ellipse", "rect", "line", "polygon", "polyline", "g"],
	#"image": [],
	#"text": ["tspan"],
	#"tspan": [],
}

const PROPAGATED_ATTRIBUTES: PackedStringArray = ["fill", "fill-opacity", "stroke", "stroke-opacity", "stroke-width", "stroke-linecap", "stroke-linejoin",
		"stroke-miterlimit", "stroke-dasharray", "stroke-dashoffset", "color"]


const ATTRIBUTE_KEYWORD_VALUES: Dictionary[String, PackedStringArray] = {
	"fill": ["none", "currentColor"],
	"stroke": ["none", "currentColor"],
	"stop-color": ["currentColor"],
	"stroke-linecap": ["butt", "round", "square"],
	"stroke-linejoin": ["miter", "round", "bevel"],
	"stroke-dasharray": ["none"],
	"gradientUnits": ["userSpaceOnUse", "objectBoundingBox"],
	"spreadMethod": ["pad", "reflect", "repeat"],
	#"markerUnits": ["userSpaceOnUse", "strokeWidth"],
	#"clipPathUnits": ["userSpaceOnUse", "objectBoundingBox"],
}


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
	match attribute_name:
		"viewBox": return AttributeType.LIST
		"width": return AttributeType.NUMERIC_POSITIVE
		"height": return AttributeType.NUMERIC_POSITIVE
		"x": return AttributeType.NUMERIC_ARBITRARY
		"y": return AttributeType.NUMERIC_ARBITRARY
		"x1": return AttributeType.NUMERIC_ARBITRARY
		"y1": return AttributeType.NUMERIC_ARBITRARY
		"x2": return AttributeType.NUMERIC_ARBITRARY
		"y2": return AttributeType.NUMERIC_ARBITRARY
		"cx": return AttributeType.NUMERIC_ARBITRARY
		"cy": return AttributeType.NUMERIC_ARBITRARY
		"r": return AttributeType.NUMERIC_POSITIVE
		"rx": return AttributeType.NUMERIC_POSITIVE
		"ry": return AttributeType.NUMERIC_POSITIVE
		"fx": return AttributeType.NUMERIC_ARBITRARY
		"fy": return AttributeType.NUMERIC_ARBITRARY
		"opacity": return AttributeType.NUMERIC_FRACTION
		"fill": return AttributeType.PAINT
		"fill-opacity": return AttributeType.NUMERIC_FRACTION
		"stroke": return AttributeType.PAINT
		"stroke-opacity": return AttributeType.NUMERIC_FRACTION
		"stroke-width": return AttributeType.NUMERIC_POSITIVE
		"stroke-miterlimit": return AttributeType.NUMERIC_POSITIVE
		"stroke-dasharray": return AttributeType.DASHARRAY
		"stroke-dashoffset": return AttributeType.NUMERIC_ARBITRARY
		"color": return AttributeType.COLOR
		"d": return AttributeType.PATHDATA
		"points": return AttributeType.LIST
		"transform": return AttributeType.TRANSFORM_LIST
		"offset": return AttributeType.NUMERIC_ARBITRARY
		"stop-color": return AttributeType.COLOR
		"stop-opacity": return AttributeType.NUMERIC_ARBITRARY
		"id": return AttributeType.ID
		"gradientTransform": return AttributeType.TRANSFORM_LIST
		"href": return AttributeType.HREF
		"mask": return AttributeType.URL
	return AttributeType.NONE

## Get default percentage handling behavior for numeric attributes.
static func get_attribute_default_percentage_handling(attribute_name: String) -> PercentageHandling:
	match attribute_name:
		"stroke-width", "r": return PercentageHandling.NORMALIZED
		"width", "x", "rx", "x1", "x2", "cx", "fx": return PercentageHandling.HORIZONTAL
		"height", "y", "ry", "y1", "y2", "cy", "fy": return PercentageHandling.VERTICAL
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
		DB.AttributeType.NUMERIC_FRACTION: return AttributeNumeric.new(name, value)
		DB.AttributeType.COLOR: return AttributeColor.new(name, value)
		DB.AttributeType.LIST: return AttributeList.new(name, value)
		DB.AttributeType.PATHDATA: return AttributePathdata.new(name, value)
		DB.AttributeType.TRANSFORM_LIST: return AttributeTransformList.new(name, value)
		DB.AttributeType.ID: return AttributeID.new(name, value)
		DB.AttributeType.HREF: return AttributeHref.new(name, value)
		DB.AttributeType.DASHARRAY: return AttributeDasharray.new(name, value)
		_: return Attribute.new(name, value)
