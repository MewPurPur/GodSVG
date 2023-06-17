class_name SVGTagCircle extends SVGTag

func _init():
	title = "circle"
	attributes = {
		"cx": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 0.0),
		"cy": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 0.0),
		"r": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 0.0),
		"fill": SVGAttribute.new(SVGAttribute.Type.COLOR, "000"),
		"stroke": SVGAttribute.new(SVGAttribute.Type.COLOR, "none"),
		"stroke-width": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 1.0),
	}
