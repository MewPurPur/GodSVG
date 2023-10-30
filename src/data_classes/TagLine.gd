## A <line> tag.
class_name TagLine extends Tag

func _init() -> void:
	title = "line"
	attributes = {
		"x1": Attribute.new(Attribute.Type.FLOAT, 0.0),
		"y1": Attribute.new(Attribute.Type.FLOAT, 0.0),
		"x2": Attribute.new(Attribute.Type.FLOAT, 0.0),
		"y2": Attribute.new(Attribute.Type.FLOAT, 0.0),
		"opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"stroke": Attribute.new(Attribute.Type.COLOR, "none"),
		"stroke-opacity": Attribute.new(Attribute.Type.NFLOAT, 1.0),
		"stroke-width": Attribute.new(Attribute.Type.UFLOAT, 1.0),
		"stroke-linecap": AttributeEnum.new(["butt", "round", "square"], 0),
	}
	super()
