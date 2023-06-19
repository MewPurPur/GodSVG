class_name SVGTagEllipse extends SVGTag

func _init():
	title = "ellipse"
	attributes = {
		"cx": SVGAttribute.new(SVGAttribute.Type.FLOAT, 0.0),
		"cy": SVGAttribute.new(SVGAttribute.Type.FLOAT, 0.0),
		"rx": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 0.0, 1.0),
		"ry": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 0.0, 1.0),
		"fill": SVGAttribute.new(SVGAttribute.Type.COLOR, "000"),
		"stroke": SVGAttribute.new(SVGAttribute.Type.COLOR, "none"),
		"stroke-width": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 1.0),
	}
