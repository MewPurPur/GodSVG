class_name AttributeUnknown extends Attribute

var name := ""

func _init(new_name: String, new_init: Variant = null) -> void:
	type = Type.UNKNOWN
	default = null
	name = new_name
	set_value(new_init)
