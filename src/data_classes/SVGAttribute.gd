class_name SVGAttribute extends RefCounted

enum Type {INT, FLOAT, UFLOAT, NFLOAT, COLOR, PATH_DEFINITION}

var type: Type
var value: Variant
var default: Variant

func _init(new_type: Type, new_default: Variant):
	type = new_type
	default = new_default
	value = new_default
