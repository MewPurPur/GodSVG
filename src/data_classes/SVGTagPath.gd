class_name SVGTagPath extends SVGTag

func _init() -> void:
	title = "path"
	attributes = {
		"d": SVGAttribute.new(SVGAttribute.Type.PATHDATA, ""),
		"fill": SVGAttribute.new(SVGAttribute.Type.COLOR, "000"),
		"stroke": SVGAttribute.new(SVGAttribute.Type.COLOR, "none"),
		"stroke-width": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 1.0),
		"stroke-linecap": SVGEnumAttribute.new(["butt", "round", "square"], 0),
		"stroke-linejoin": SVGEnumAttribute.new(["butt", "round", "square"], 0),
	}
