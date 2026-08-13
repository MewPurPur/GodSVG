## A <use> element.
class_name ElementUse extends Element

const name = "use"
const possible_conversions: PackedStringArray = []

func user_setup(precise_position := PackedFloat64Array([0.0, 0.0])) -> void:
	if precise_position != PackedFloat64Array([0.0, 0.0]):
		set_attribute("x", precise_position[0])
		set_attribute("y", precise_position[1])

func _get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"x", "y": return "0"
		_: return ""
