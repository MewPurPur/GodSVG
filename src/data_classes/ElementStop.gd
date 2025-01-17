# A <stop> element.
class_name ElementStop extends Element

const name = "stop"
const possible_conversions: Array[String] = []

func _get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"offset": return "0"
		"stop-color": return "black"
		"stop-opacity": return "1"
		_: return ""
