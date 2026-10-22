## An attribute representing an element's ID.
class_name AttributeID extends Attribute

func set_value(new_value: String) -> void:
	super(new_value if ParserID.get_id_validity(new_value) != ParserID.NameValidityLevel.INVALID else "")
