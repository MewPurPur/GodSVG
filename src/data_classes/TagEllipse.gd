## An <ellipse/> tag.
class_name TagEllipse extends Tag

const known_attributes = ["cx", "cy", "rx", "ry",
		"opacity", "fill", "fill-opacity", "stroke", "stroke-opacity", "stroke-width"]

func _init() -> void:
	name = "ellipse"
	attributes = {
		"cx": Attribute.new(Attribute.Type.FLOAT, 0.0),
		"cy": Attribute.new(Attribute.Type.FLOAT, 0.0),
		"rx": Attribute.new(Attribute.Type.UFLOAT, 0.0, 1.0),
		"ry": Attribute.new(Attribute.Type.UFLOAT, 0.0, 1.0),
		"opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"fill": Attribute.new(Attribute.Type.COLOR, "#000"),
		"fill-opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"stroke": Attribute.new(Attribute.Type.COLOR, "none"),
		"stroke-opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"stroke-width": Attribute.new(Attribute.Type.UFLOAT, 1.0),
	}
	super()
