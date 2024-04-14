class_name TranslationUtils extends RefCounted

func get_shortcut_description(action_name: String) -> String:
	match action_name:
		"export": return tr("Export")
		"import": return tr("Import")
		"save": return tr("Save SVG")
		"optimize": return tr("Optimize")
		"copy_svg_text": return tr("Copy all text")
		"reset_svg": return tr("Reset SVG")
		"clear_svg": return tr("Clear SVG")
		"clear_file_path": return tr("Clear saving path")
		"undo": return tr("Undo")
		"redo": return tr("Redo")
		"select_all": return tr("Select all tags")
		"duplicate": return tr("Duplicate the selected tags")
		"delete": return tr("Delete the selection")
		"move_up": return tr("Move the selected tags up")
		"move_down": return tr("Move the selected tags down")
		"zoom_in": return tr("Zoom in")
		"zoom_out": return tr("Zoom out")
		"zoom_reset": return tr("Zoom reset")
		"view_show_grid": return tr("Show grid")
		"view_show_handles": return tr("Show handles")
		"view_rasterize_svg": return tr("Show rasterized SVG")
		_: return action_name


func get_command_char_description(command_char: String) -> String:
	match command_char:
		"M", "m": return tr("Move to")
		"L", "l": return tr("Line to")
		"H", "h": return tr("Horizontal Line to")
		"V", "v": return tr("Vertical Line to")
		"Z", "z": return tr("Close Path")
		"A", "a": return tr("Elliptical Arc to")
		"Q", "q": return tr("Quadratic Bezier to")
		"T", "t": return tr("Shorthand Quadratic Bezier to")
		"C", "c": return tr("Cubic Bezier to")
		"S", "s": return tr("Shorthand Cubic Bezier to")
		_: return command_char
