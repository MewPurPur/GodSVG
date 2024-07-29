class_name ShortcutUtils extends RefCounted

static func fn_call(shortcut: String) -> void:
	fn(shortcut).call()

# The methods that should be called if these shortcuts aren't handled.
static func fn(shortcut: String) -> Callable:
	match shortcut:
		"save": return FileUtils.open_save_dialog.bind("svg",
				FileUtils.native_file_save, FileUtils.save_svg_to_file)
		"import": return FileUtils.open_import_dialog
		"export": return FileUtils.open_export_dialog
		"copy_svg_text": return DisplayServer.clipboard_set.bind(SVG.text)
		"clear_svg": return SVG.apply_svg_text.bind(SVG.DEFAULT)
		"optimize": return SVG.optimize
		"clear_file_path": return GlobalSettings.modify_save_data.bind(
				"current_file_path", "")
		"reset_svg": return FileUtils.apply_svg_from_path.bind(
				GlobalSettings.save_data.current_file_path)
		"redo": return SVG.redo
		"undo": return SVG.undo
		"ui_cancel": return Indications.clear_all_selections
		"delete": return Indications.delete_selected
		"move_up": return Indications.move_up_selected
		"move_down": return Indications.move_down_selected
		"duplicate": return Indications.duplicate_selected
		"select_all": return Indications.select_all
		"about_info": return HandlerGUI.open_about
		"about_donate": return HandlerGUI.open_donate
		"about_repo": return OS.shell_open.bind("https://github.com/MewPurPur/GodSVG")
		"about_website": return OS.shell_open.bind("https://godsvg.com")
		"check_updates": return HandlerGUI.open_update_checker
		"open_settings": return HandlerGUI.open_settings
		_: return Callable()
