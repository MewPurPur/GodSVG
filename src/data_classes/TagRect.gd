class_name TagRect extends Tag

func _init() -> void:
	title = "rect"
	attributes = {
		"x": Attribute.new(Attribute.Type.FLOAT, 0.0),
		"y": Attribute.new(Attribute.Type.FLOAT, 0.0),
		"width": Attribute.new(Attribute.Type.UFLOAT, 0.0, 1.0),
		"height": Attribute.new(Attribute.Type.UFLOAT, 0.0, 1.0),
		"rx": Attribute.new(Attribute.Type.UFLOAT, 0.0),
		"ry": Attribute.new(Attribute.Type.UFLOAT, 0.0),
		"opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"fill": Attribute.new(Attribute.Type.COLOR, "#000"),
		"fill-opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"stroke": Attribute.new(Attribute.Type.COLOR, "none"),
		"stroke-opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"stroke-width": Attribute.new(Attribute.Type.UFLOAT, 1.0),
		"stroke-linejoin": AttributeEnum.new(["miter", "round", "bevel"], 0),
	}
	super()
