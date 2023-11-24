## An attribute with only a set of meaningful values.
class_name AttributeEnum extends Attribute

var possible_values: Array[String]

func _init(new_possible_values: Array[String], new_default_idx := 0) -> void:
	type = Type.ENUM
	possible_values = new_possible_values
	default = possible_values[new_default_idx]
	set_value(default, SyncMode.SILENT)
