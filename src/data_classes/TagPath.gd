## A <path/> tag.
class_name TagPath extends Tag

const known_attributes = ["d",
		"opacity", "fill", "fill-opacity", "stroke", "stroke-opacity", "stroke-width",
		"stroke-linecap", "stroke-linejoin"]

func _init() -> void:
	name = "path"
	attributes = {
		"d": AttributePath.new(),
		"opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, 1.0),
		"fill": AttributeColor.new("#000"),
		"fill-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, 1.0),
		"stroke": AttributeColor.new("none"),
		"stroke-opacity": AttributeNumeric.new(AttributeNumeric.Mode.NFLOAT, 1.0),
		"stroke-width": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, 1.0),
		"stroke-linecap": AttributeEnum.new(["butt", "round", "square"], 0),
		"stroke-linejoin": AttributeEnum.new(["miter", "round", "bevel"], 0),
	}
	super()
