class_name SVGTagRect extends SVGTag

func _init() -> void:
	title = "rect"
	attributes = {
		"x": SVGAttribute.new(SVGAttribute.Type.FLOAT, 0.0),
		"y": SVGAttribute.new(SVGAttribute.Type.FLOAT, 0.0),
		"width": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 0.0, 1.0),
		"height": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 0.0, 1.0),
		"rx": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 0.0),
		"ry": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 0.0),
		"fill": SVGAttribute.new(SVGAttribute.Type.COLOR, "000"),
		"fill-opacity": SVGAttribute.new(SVGAttribute.Type.NFLOAT, 1.0),
		"stroke": SVGAttribute.new(SVGAttribute.Type.COLOR, "none"),
		"stroke-opacity": SVGAttribute.new(SVGAttribute.Type.NFLOAT, 1.0),
		"stroke-width": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 1.0),
		"stroke-linejoin": SVGEnumAttribute.new(["miter", "round", "bevel"], 0),
	}
	super()
