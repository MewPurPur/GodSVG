class_name SVGEnumAttribute extends SVGAttribute

var possible_values: Array[String]

func _init(new_possible_values: Array[String], new_default_idx := 0) -> void:
	type = Type.ENUM
	possible_values = new_possible_values
	default = possible_values[new_default_idx]
	value = possible_values[new_default_idx]
