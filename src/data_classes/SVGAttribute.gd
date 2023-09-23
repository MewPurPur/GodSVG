class_name SVGAttribute extends RefCounted

enum Type {INT, FLOAT, UFLOAT, NFLOAT, COLOR, PATHDATA, ENUM}

var type: Type
var value: Variant
var default: Variant

func _init(new_type: Type, new_default: Variant, new_init: Variant = null) -> void:
	type = new_type
	default = new_default
	value = new_init if new_init != null else new_default
