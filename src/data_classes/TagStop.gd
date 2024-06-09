# A <stop/> tag.
class_name TagStop extends Tag

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
	if not (parent is TagLinearGradient or parent is TagRadialGradient):
		warnings.append(TranslationServer.translate("{tag} must be a child of {allowed} to have any effect.").format(
				{"tag": name, "allowed": "[linearGradient, radialGradient]"}))
	return warnings
