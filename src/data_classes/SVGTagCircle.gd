class_name SVGTagCircle extends SVGTag

func _init() -> void:
	title = "circle"
	attributes = {
		"cx": SVGAttribute.new(SVGAttribute.Type.FLOAT, 0.0),
		"cy": SVGAttribute.new(SVGAttribute.Type.FLOAT, 0.0),
		"r": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 0.0, 1.0),
		"opacity": SVGAttribute.new(SVGAttribute.Type.NFLOAT, 1.0),
		"fill": SVGAttribute.new(SVGAttribute.Type.COLOR, "#000"),
		"fill-opacity": SVGAttribute.new(SVGAttribute.Type.NFLOAT, 1.0),
		"stroke": SVGAttribute.new(SVGAttribute.Type.COLOR, "none"),
		"stroke-opacity": SVGAttribute.new(SVGAttribute.Type.NFLOAT, 1.0),
		"stroke-width": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 1.0),
	}
	super()
