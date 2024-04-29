# An attribute that's not recognized by GodSVG.
class_name AttributeUnknown extends Attribute

func _init(new_name: String, new_init := "") -> void:
	name = new_name
	set_value(new_init, SyncMode.SILENT)
