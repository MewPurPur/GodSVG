## A <rect/> tag.
class_name TagRect extends Tag

const known_attributes = ["x", "y", "width", "height", "rx", "ry",
		"opacity", "fill", "fill-opacity", "stroke", "stroke-opacity", "stroke-width",
		"stroke-linejoin"]

func _init() -> void:
	name = "rect"
	attributes = {
		"x": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, 0.0),
		"y": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, 0.0),
		"width": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, 0.0, 1.0),
		"height": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, 0.0, 1.0),
		"rx": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, 0.0),
		"ry": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, 0.0),
		"opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, 1.0),
		"fill": AttributeColor.new("#000"),
		"fill-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, 1.0),
		"stroke": AttributeColor.new("none"),
		"stroke-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, 1.0),
		"stroke-width": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, 1.0),
		"stroke-linejoin": AttributeEnum.new(["miter", "round", "bevel"], 0),
	}
	super()
