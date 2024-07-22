# An attribute representing an element's id
class_name AttributeID extends Attribute

func set_value(new_value: String) -> void:
	super(new_value if IDParser.get_validity(new_value) != IDParser.ValidityLevel.INVALID\
			else "")
