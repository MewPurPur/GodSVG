## A <g> element.
class_name ElementG extends Element

const name = "g"
const possible_conversions: PackedStringArray = []

func _get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"opacity": return "1"
		_: return ""

func get_config_warnings() -> PackedStringArray:
	var warnings := super()
	if get_child_count() == 0:
		warnings.append(Translator.translate("This group has no elements."))
	elif get_child_count() == 1:
		warnings.append(Translator.translate("This group has only one element."))
	return warnings
