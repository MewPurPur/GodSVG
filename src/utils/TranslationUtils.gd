class_name TranslationUtils extends RefCounted

static func _get_locale_name(locale: String) -> String:
	match locale:
		"pt_BR": return "Brazilian Portuguese"
		"zh_CN": return "Simplified Chinese"
	return TranslationServer.get_locale_name(locale)

static func get_locale_string(locale: String) -> String:
	if not "_" in locale:
		return locale.to_upper()
	var separator_pos := locale.find("_")
	return locale.left(separator_pos) + "-" + locale.right(-separator_pos - 1).to_upper()

static func get_locale_display(locale: String) -> String:
	return "%s (%s)" % [_get_locale_name(locale), get_locale_string(locale)]


static func get_shortcut_description(action_name: String) -> String:
	match action_name:
		"export": return Translator.translate("Export")
		"import": return Translator.translate("Import")
		"save": return Translator.translate("Save")
		"save_as": return Translator.translate("Save as")
		"close_tab": return Translator.translate("Close tab")
		"new_tab": return Translator.translate("Create a new tab")
		"select_next_tab": return Translator.translate("Select the next tab")
		"select_previous_tab": return Translator.translate("Select the previous tab")
		"optimize": return Translator.translate("Optimize")
		"copy_svg_text": return Translator.translate("Copy all text")
		"reset_svg": return Translator.translate("Reset SVG")
		"open_externally": return Translator.translate("Open SVG externally")
		"open_in_folder": return Translator.translate("Show SVG in File Manager")
		"undo": return Translator.translate("Undo")
		"redo": return Translator.translate("Redo")
		"select_all": return Translator.translate("Select all")
		"duplicate": return Translator.translate("Duplicate the selection")
		"delete": return Translator.translate("Delete the selection")
		"move_up": return Translator.translate("Move the selection up")
		"move_down": return Translator.translate("Move the selection down")
		"find": return Translator.translate("Find")
		"zoom_in": return Translator.translate("Zoom in")
		"zoom_out": return Translator.translate("Zoom out")
		"zoom_reset": return Translator.translate("Zoom reset")
		"view_show_grid": return Translator.translate("Show grid")
		"view_show_handles": return Translator.translate("Show handles")
		"view_rasterized_svg": return Translator.translate("Show rasterized SVG")
		"toggle_snap": return Translator.translate("Toggle snapping")
		"load_reference": return Translator.translate("Load reference image")
		"view_show_reference": return Translator.translate("Show reference image")
		"view_overlay_reference": return Translator.translate("Overlay reference image")
		"debug": return Translator.translate("View debug information")
		"move_relative": return "%s (%s)" %\
				[get_command_description("M"), Translator.translate("Relative")]
		"move_absolute": return "%s (%s)" %\
				[get_command_description("M"), Translator.translate("Absolute")]
		"line_relative": return "%s (%s)" %\
				[get_command_description("L"), Translator.translate("Relative")]
		"line_absolute": return "%s (%s)" %\
				[get_command_description("L"), Translator.translate("Absolute")]
		"horizontal_line_relative": return "%s (%s)" %\
				[get_command_description("H"), Translator.translate("Relative")]
		"horizontal_line_absolute": return "%s (%s)" %\
				[get_command_description("H"), Translator.translate("Absolute")]
		"vertical_line_relative": return "%s (%s)" %\
				[get_command_description("V"), Translator.translate("Relative")]
		"vertical_line_absolute": return "%s (%s)" %\
				[get_command_description("V"), Translator.translate("Absolute")]
		"close_path_relative": return "%s (%s)" %\
				[get_command_description("Z"), Translator.translate("Relative")]
		"close_path_absolute": return "%s (%s)" %\
				[get_command_description("Z"), Translator.translate("Absolute")]
		"elliptical_arc_relative": return "%s (%s)" %\
				[get_command_description("A"), Translator.translate("Relative")]
		"elliptical_arc_absolute": return "%s (%s)" %\
				[get_command_description("A"), Translator.translate("Absolute")]
		"quadratic_bezier_relative": return "%s (%s)" %\
				[get_command_description("Q"), Translator.translate("Relative")]
		"quadratic_bezier_absolute": return "%s (%s)" %\
				[get_command_description("Q"), Translator.translate("Absolute")]
		"shorthand_quadratic_bezier_relative": return "%s (%s)" %\
				[get_command_description("T"), Translator.translate("Relative")]
		"shorthand_quadratic_bezier_absolute": return "%s (%s)" %\
				[get_command_description("T"), Translator.translate("Absolute")]
		"cubic_bezier_relative": return "%s (%s)" %\
				[get_command_description("C"), Translator.translate("Relative")]
		"cubic_bezier_absolute": return "%s (%s)" %\
				[get_command_description("C"), Translator.translate("Absolute")]
		"shorthand_cubic_bezier_relative": return "%s (%s)" %\
				[get_command_description("S"), Translator.translate("Relative")]
		"shorthand_cubic_bezier_absolute": return "%s (%s)" %\
				[get_command_description("S"), Translator.translate("Absolute")]
		"open_settings": return Translator.translate("Open Settings menu")
		"about_info": return Translator.translate("Open About menu")
		"about_donate": return Translator.translate("Open Donate menu")
		"about_repo": return Translator.translate("Open GodSVG repository")
		"about_website": return Translator.translate("Open GodSVG website")
		"check_updates": return Translator.translate("Check for updates")
		"quit": return Translator.translate("Quit the application")
		_: return action_name


static func get_command_description(command_char: String) -> String:
	match command_char:
		"M", "m": return Translator.translate("Move to")
		"L", "l": return Translator.translate("Line to")
		"H", "h": return Translator.translate("Horizontal Line to")
		"V", "v": return Translator.translate("Vertical Line to")
		"Z", "z": return Translator.translate("Close Path")
		"A", "a": return Translator.translate("Elliptical Arc to")
		"Q", "q": return Translator.translate("Quadratic Bezier to")
		"T", "t": return Translator.translate("Shorthand Quadratic Bezier to")
		"C", "c": return Translator.translate("Cubic Bezier to")
		"S", "s": return Translator.translate("Shorthand Cubic Bezier to")
		_: return command_char

static func get_bad_extension_alert_text(extension: String,
allowed_extensions: PackedStringArray) -> String:
	var extension_list := ", ".join(allowed_extensions)
	if extension.is_empty():
		return Translator.translate(
				"The file extension is empty. Only {extension_list} files are supported.").format(
				{"extension_list": extension_list})
	return Translator.translate(
			"The file extension {extension} is unsupported for this operation. Only {extension_list} files are supported.").format(
			{"extension": '".' + extension + '"', "extension_list": extension_list})
