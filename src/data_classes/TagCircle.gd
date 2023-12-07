## A <circle/> tag.
class_name TagCircle extends Tag

const known_attributes = ["cx", "cy", "r",
		"opacity", "fill", "fill-opacity", "stroke", "stroke-opacity", "stroke-width"]

func _init() -> void:
	name = "circle"
	attributes = {
		"cx": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, "0"),
		"cy": AttributeNumeric.new(AttributeNumeric.Mode.FLOAT, "0"),
		"r": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, "0", "1"),
		"opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, "1"),
		"fill": AttributeColor.new("#000"),
		"fill-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, "1"),
		"stroke": AttributeColor.new("none"),
		"stroke-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, "1"),
		"stroke-width": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, "1"),
	}
	super()
