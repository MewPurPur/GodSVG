## A <path/> tag.
class_name TagPath extends Tag

const known_attributes = ["d",
		"opacity", "fill", "fill-opacity", "stroke", "stroke-opacity", "stroke-width",
		"stroke-linecap", "stroke-linejoin"]

func _init() -> void:
	name = "path"
	attributes = {
		"d": AttributePath.new(),
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
