## An attribute with only a set of meaningful values.
class_name AttributeEnum extends Attribute

var possible_values: Array[String]

func _init(new_possible_values: Array[String], new_default_idx := 0) -> void:
	possible_values = new_possible_values
	default = possible_values[new_default_idx]
	set_value(default, SyncMode.SILENT)

func set_value(new_value: String, sync_mode := SyncMode.LOUD) -> void:
	super(new_value if new_value in possible_values else default, sync_mode)
