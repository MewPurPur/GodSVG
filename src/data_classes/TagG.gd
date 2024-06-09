class_name TagG extends Tag

const name = "g"
const possible_conversions = []

func get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"opacity": return "1"
		_: return ""

func get_config_warnings() -> PackedStringArray:
	var warnings := super()
	if not (parent is TagG or parent is TagSVG or parent is TagUnrecognized):
		warnings.append(TranslationServer.translate("{tag} must be a child of {allowed} to have any effect.").format(
				{"tag": self.name, "allowed": "[svg, g]"}))
	return warnings
