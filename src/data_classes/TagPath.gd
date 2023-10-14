class_name TagPath extends Tag

func _init() -> void:
	title = "path"
	attributes = {
		"d": Attribute.new(Attribute.Type.PATHDATA, ""),
		"opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"fill": Attribute.new(Attribute.Type.COLOR, "#000"),
		"fill-opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"stroke": Attribute.new(Attribute.Type.COLOR, "none"),
		"stroke-opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"stroke-width": Attribute.new(Attribute.Type.UFLOAT, 1.0),
		"stroke-linecap": AttributeEnum.new(["butt", "round", "square"], 0),
		"stroke-linejoin": AttributeEnum.new(["miter", "round", "bevel"], 0),
	}
	super()
