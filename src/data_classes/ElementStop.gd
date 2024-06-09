# A <stop/> element.
class_name ElementStop extends Element

const name = "stop"
const possible_conversions = []

func get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"offset": return "0"
		"stop-color": return "black"
		"stop-opacity": return "1"
		_: return ""

func get_config_warnings() -> PackedStringArray:
	var warnings := super()
	if not (parent is ElementLinearGradient or parent is ElementRadialGradient):
		warnings.append(TranslationServer.translate("{element} must be inside {allowed} to have any effect.").format(
				{"element": name, "allowed": "[linearGradient, radialGradient]"}))
	return warnings
