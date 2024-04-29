# An attribute with only a set of meaningful values.
class_name AttributeEnum extends Attribute

func set_value(new_value: String, sync_mode := SyncMode.LOUD) -> void:
	if new_value.is_empty() or new_value in DB.attribute_enum_values[name]:
		super(new_value, sync_mode)
	else:
		super(get_default(), sync_mode)
