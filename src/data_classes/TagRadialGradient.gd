class_name TagRadialGradient extends Tag

const name = "radialGradient"
const possible_conversions = []

func get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"cx", "cy", "r": return "50%"
		_: return ""

func get_config_warnings() -> PackedStringArray:
	var warnings := super()
	if not (parent is TagG or parent is TagSVG or parent is TagUnrecognized):
		warnings.append(TranslationServer.translate("{tag} must be a child of {allowed} to have any effect.").format(
				{"tag": name, "allowed": "[g, svg]"}))
	if not attributes.has("id"):
		warnings.append(TranslationServer.translate("No id attribute defined."))
	
	var has_stops := false
	for child in child_tags:
		if child is TagStop:
			has_stops = true
			break
	if not has_stops:
		warnings.append(TranslationServer.translate("No stop tags under this gradient."))
	
	return warnings
