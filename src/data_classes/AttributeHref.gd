# An attribute representing an element's href
class_name AttributeHref extends Attribute

func set_value(new_value: String) -> void:
	super(new_value if get_validity(new_value) != NameValidityLevel.INVALID else "")
	
	
static func get_validity(id: String) -> NameValidityLevel:
	if id.is_empty():
		return NameValidityLevel.INVALID
	
	# Allow '#'.
	return get_name_validity(id.trim_prefix("#"))
