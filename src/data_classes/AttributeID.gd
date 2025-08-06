## An attribute representing an element's ID.
class_name AttributeID extends Attribute

func set_value(new_value: String) -> void:
	super(new_value if get_validity(new_value) != NameValidityLevel.INVALID else "")


static func get_validity(id: String) -> NameValidityLevel:
	if id.is_empty() or id[0] == "#":
		return NameValidityLevel.INVALID
	
	return get_id_validity(id)
