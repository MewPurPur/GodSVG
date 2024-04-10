class_name AttributeUnknown extends Attribute
## An attribute not recognized by GodSVG.

var name := ""

func _init(new_name: String, new_init := "") -> void:
	default = ""
	name = new_name
	set_value(new_init, SyncMode.SILENT)
