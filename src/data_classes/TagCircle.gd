## A <circle/> tag.
class_name TagCircle extends Tag

const known_attributes = ["cx", "cy", "r",
		"opacity", "fill", "fill-opacity", "stroke", "stroke-opacity", "stroke-width"]

func _init() -> void:
	name = "circle"
	attributes = {
		"cx": Attribute.new(Attribute.Type.FLOAT, 0.0),
		"cy": Attribute.new(Attribute.Type.FLOAT, 0.0),
		"r": Attribute.new(Attribute.Type.UFLOAT, 0.0, 1.0),
		"opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"fill": Attribute.new(Attribute.Type.COLOR, "#000"),
		"fill-opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"stroke": Attribute.new(Attribute.Type.COLOR, "none"),
		"stroke-opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"stroke-width": Attribute.new(Attribute.Type.UFLOAT, 1.0),
	}
	super()
