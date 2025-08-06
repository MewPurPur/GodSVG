## An attribute with only a set of meaningful values.
class_name AttributeEnum extends Attribute

func set_value(new_value: String) -> void:
	super(new_value if (new_value.is_empty() or new_value in DB.attribute_enum_values[name]) else "")
