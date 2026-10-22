## An attribute representing a reference to an ID.
class_name AttributeHref extends Attribute

func set_value(new_value: String) -> void:
	super(new_value if ParserID.get_href_validity(new_value) != ParserID.NameValidityLevel.INVALID else "")
