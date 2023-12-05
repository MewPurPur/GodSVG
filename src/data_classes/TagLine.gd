## A <line/> tag.
class_name TagLine extends Tag

const known_attributes = ["x1", "y1", "x2", "y2",
		"opacity", "stroke", "stroke-opacity", "stroke-width", "stroke-linecap"]

func _init() -> void:
	name = "line"
	attributes = {
		"x1": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, 0.0),
		"y1": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, 0.0),
		"x2": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, 0.0),
		"y2": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, 0.0),
		"opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, 1.0),
		"stroke": AttributeColor.new("none", "#000"),
		"stroke-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, 1.0),
		"stroke-width": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, 1.0),
		"stroke-linecap": AttributeEnum.new(["butt", "round", "square"], 0),
	}
	super()
