class_name TranslationUtils extends RefCounted

static func get_shortcut_description(action_name: String) -> String:
	match action_name:
		"export": return TranslationServer.translate("Export")
		"import": return TranslationServer.translate("Import SVG")
		"import_reference_image": return TranslationServer.translate("Import Reference Image")
		"save": return TranslationServer.translate("Save SVG")
		"optimize": return TranslationServer.translate("Optimize")
		"copy_svg_text": return TranslationServer.translate("Copy all text")
		"reset_svg": return TranslationServer.translate("Reset SVG")
		"clear_svg": return TranslationServer.translate("Clear SVG")
		"clear_file_path": return TranslationServer.translate("Clear saving path")
		"undo": return TranslationServer.translate("Undo")
		"redo": return TranslationServer.translate("Redo")
		"select_all": return TranslationServer.translate("Select all tags")
		"duplicate": return TranslationServer.translate("Duplicate the selected tags")
		"delete": return TranslationServer.translate("Delete the selection")
		"move_up": return TranslationServer.translate("Move the selected tags up")
		"move_down": return TranslationServer.translate("Move the selected tags down")
		"zoom_in": return TranslationServer.translate("Zoom in")
		"zoom_out": return TranslationServer.translate("Zoom out")
		"zoom_reset": return TranslationServer.translate("Zoom reset")
		"view_show_grid": return TranslationServer.translate("Show grid")
		"view_show_handles": return TranslationServer.translate("Show handles")
		"view_rasterized_svg": return TranslationServer.translate("Show rasterized SVG")
		"view_reference_image": return TranslationServer.translate("Show reference image")
		"debug": return TranslationServer.translate("View debug information")
		"move_relative": return "%s (%s)" %\
				[get_command_description("M"), TranslationServer.translate("Relative")]
		"move_absolute": return "%s (%s)" %\
				[get_command_description("M"), TranslationServer.translate("Absolute")]
		"line_relative": return "%s (%s)" %\
				[get_command_description("L"), TranslationServer.translate("Relative")]
		"line_absolute": return "%s (%s)" %\
				[get_command_description("L"), TranslationServer.translate("Absolute")]
		"horizontal_line_relative": return "%s (%s)" %\
				[get_command_description("H"), TranslationServer.translate("Relative")]
		"horizontal_line_absolute": return "%s (%s)" %\
				[get_command_description("H"), TranslationServer.translate("Absolute")]
		"vertical_line_relative": return "%s (%s)" %\
				[get_command_description("V"), TranslationServer.translate("Relative")]
		"vertical_line_absolute": return "%s (%s)" %\
				[get_command_description("V"), TranslationServer.translate("Absolute")]
		"close_path_relative": return "%s (%s)" %\
				[get_command_description("Z"), TranslationServer.translate("Relative")]
		"close_path_absolute": return "%s (%s)" %\
				[get_command_description("Z"), TranslationServer.translate("Absolute")]
		"elliptical_arc_relative": return "%s (%s)" %\
				[get_command_description("A"), TranslationServer.translate("Relative")]
		"elliptical_arc_absolute": return "%s (%s)" %\
				[get_command_description("A"), TranslationServer.translate("Absolute")]
		"quadratic_bezier_relative": return "%s (%s)" %\
				[get_command_description("Q"), TranslationServer.translate("Relative")]
		"quadratic_bezier_absolute": return "%s (%s)" %\
				[get_command_description("Q"), TranslationServer.translate("Absolute")]
		"shorthand_quadratic_bezier_relative": return "%s (%s)" %\
				[get_command_description("T"), TranslationServer.translate("Relative")]
		"shorthand_quadratic_bezier_absolute": return "%s (%s)" %\
				[get_command_description("T"), TranslationServer.translate("Absolute")]
		"cubic_bezier_relative": return "%s (%s)" %\
				[get_command_description("C"), TranslationServer.translate("Relative")]
		"cubic_bezier_absolute": return "%s (%s)" %\
				[get_command_description("C"), TranslationServer.translate("Absolute")]
		"shorthand_cubic_bezier_relative": return "%s (%s)" %\
				[get_command_description("S"), TranslationServer.translate("Relative")]
		"shorthand_cubic_bezier_absolute": return "%s (%s)" %\
				[get_command_description("S"), TranslationServer.translate("Absolute")]
		"open_settings": return TranslationServer.translate("Open Settings menu")
		"about_info": return TranslationServer.translate("Open About menu")
		"about_donate": return TranslationServer.translate("Open Donate menu")
		"about_repo": return TranslationServer.translate("Open GodSVG repository")
		"about_website": return TranslationServer.translate("Open GodSVG website")
		"check_updates": return TranslationServer.translate("Check for updates")
		"quit": return TranslationServer.translate("Quit the application")
		_: return action_name


static func get_command_description(command_char: String) -> String:
	match command_char:
		"M", "m": return TranslationServer.translate("Move to")
		"L", "l": return TranslationServer.translate("Line to")
		"H", "h": return TranslationServer.translate("Horizontal Line to")
		"V", "v": return TranslationServer.translate("Vertical Line to")
		"Z", "z": return TranslationServer.translate("Close Path")
		"A", "a": return TranslationServer.translate("Elliptical Arc to")
		"Q", "q": return TranslationServer.translate("Quadratic Bezier to")
		"T", "t": return TranslationServer.translate("Shorthand Quadratic Bezier to")
		"C", "c": return TranslationServer.translate("Cubic Bezier to")
		"S", "s": return TranslationServer.translate("Shorthand Cubic Bezier to")
		_: return command_char
