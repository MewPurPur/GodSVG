class_name TagShape extends Tag

func get_config_warnings() -> PackedStringArray:
	var warnings := super()
	if not (parent is TagG or parent is TagSVG or parent is TagUnrecognized):
		warnings.append(TranslationServer.translate("{tag} must be a child of {allowed} to have any effect.").format(
				{"tag": self.name, "allowed": "[svg, g]"}))
	return warnings
