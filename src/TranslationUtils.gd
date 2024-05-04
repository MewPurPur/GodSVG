class_name TranslationUtils extends RefCounted

static func get_shortcut_description(action_name: String) -> String:
	match action_name:
		"export": return TranslationServer.translate("Export")
		"import": return TranslationServer.translate("Import")
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
		"debug": return TranslationServer.translate("View debug information")
		_: return action_name


static func get_command_char_description(command_char: String) -> String:
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
