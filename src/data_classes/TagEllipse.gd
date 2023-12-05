## An <ellipse/> tag.
class_name TagEllipse extends Tag

const known_attributes = ["cx", "cy", "rx", "ry",
		"opacity", "fill", "fill-opacity", "stroke", "stroke-opacity", "stroke-width"]

func _init() -> void:
	name = "ellipse"
	attributes = {
		"cx": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, 0.0),
		"cy": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, 0.0),
		"rx": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, 0.0, 1.0),
		"ry": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, 0.0, 1.0),
		"opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, 1.0),
		"fill": AttributeColor.new("#000"),
		"fill-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, 1.0),
		"stroke": AttributeColor.new("none"),
		"stroke-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, 1.0),
		"stroke-width": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, 1.0),
	}
	super()
