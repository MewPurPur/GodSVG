class_name SVGTagLine extends SVGTag

func _init() -> void:
	title = "line"
	attributes = {
		"x1": SVGAttribute.new(SVGAttribute.Type.FLOAT, 0.0),
		"y1": SVGAttribute.new(SVGAttribute.Type.FLOAT, 0.0),
		"x2": SVGAttribute.new(SVGAttribute.Type.FLOAT, 0.0),
		"y2": SVGAttribute.new(SVGAttribute.Type.FLOAT, 0.0),
		"opacity": SVGAttribute.new(SVGAttribute.Type.NFLOAT, 1.0),
		"stroke": SVGAttribute.new(SVGAttribute.Type.COLOR, "none"),
		"stroke-opacity": SVGAttribute.new(SVGAttribute.Type.NFLOAT, 1.0),
		"stroke-width": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 1.0),
		"stroke-linecap": SVGEnumAttribute.new(["butt", "round", "square"], 0),
	}
	super()
