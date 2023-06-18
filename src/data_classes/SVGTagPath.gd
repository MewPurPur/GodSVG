class_name SVGTagPath extends SVGTag

func _init():
	title = "path"
	attributes = {
		"d": SVGAttribute.new(SVGAttribute.Type.PATH_DEF, ""),
		"fill": SVGAttribute.new(SVGAttribute.Type.COLOR, "000"),
		"stroke": SVGAttribute.new(SVGAttribute.Type.COLOR, "none"),
		"stroke-width": SVGAttribute.new(SVGAttribute.Type.UFLOAT, 1.0),
	}
