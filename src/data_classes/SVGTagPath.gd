class_name SVGTagPath extends SVGTag

func _init() -> void:
	title = "path"
	attributes = {
		"d": SVGAttribute.new(SVGAttribute.Type.PATHDATA, ""),
		"fill": SVGAttribute.new(SVGAttribute.Type.COLOR, "000"),
		"fill-opacity": SVGAttribute.new(SVGAttribute.Type.NFLOAT, 1.0),
		"stroke": SVGAttribute.new(SVGAttribute.Type.COLOR, "none"),
		"stroke-opacity": SVGAttribute.new(SVGAttribute.Type.NFLOAT, 1.0),
		"stroke-width": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 1.0),
		"stroke-linecap": SVGEnumAttribute.new(["butt", "round", "square"], 0),
		"stroke-linejoin": SVGEnumAttribute.new(["miter", "round", "bevel"], 0),
	}
	super()
