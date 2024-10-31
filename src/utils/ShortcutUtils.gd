class_name ShortcutUtils extends RefCounted

const _keybinds_dict = {
	"file": {
		"import": true,
		"export": true,
		"save": true,
		"optimize": true,
		"copy_svg_text": true,
		"clear_svg": true,
		"clear_file_path": true,
		"reset_svg": true,
	},
	"edit": {
		"undo": true,
		"redo": true,
		"select_all": true,
		"duplicate": true,
		"move_up": true,
		"move_down": true,
		"delete": true,
		"find": true,
	},
	"view": {
		"zoom_in": true,
		"zoom_out": true,
		"zoom_reset": true,
		"debug": false,
		"view_show_grid": true,
		"view_show_handles": true,
		"view_rasterized_svg": true,
		"load_reference": true,
		"view_show_reference": true,
		"view_overlay_reference": true,
	},
	"tool": {
		"toggle_snap": true,
		"move_relative": false,
		"move_absolute": false,
		"line_relative": false,
		"line_absolute": false,
		"horizontal_line_relative": false,
		"horizontal_line_absolute": false,
		"vertical_line_relative": false,
		"vertical_line_absolute": false,
		"close_path_relative": false,
		"close_path_absolute": false,
		"elliptical_arc_relative": false,
		"elliptical_arc_absolute": false,
		"quadratic_bezier_relative": false,
		"quadratic_bezier_absolute": false,
		"shorthand_quadratic_bezier_relative": false,
		"shorthand_quadratic_bezier_absolute": false,
		"cubic_bezier_relative": false,
		"cubic_bezier_absolute": false,
		"shorthand_cubic_bezier_relative": false,
		"shorthand_cubic_bezier_absolute": false,
	},
	"help": {
		"quit": false,
		"open_settings": true,
		"about_info": true,
		"about_donate": true,
		"about_repo": true,
		"about_website": true,
		"check_updates": true,
	}
}

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
		"clear_file_path": return GlobalSettings.modify_setting.bind(
				"current_file_path", "")
		"reset_svg": return FileUtils.apply_svg_from_path.bind(
				GlobalSettings.savedata.current_file_path)
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
		"toggle_snap": return Callable()
		_: return Callable()

static func get_keybinds(category: String) -> PackedStringArray:
	return _keybinds_dict[category].keys()

static func get_all_keybinds() -> PackedStringArray:
	var keybinds := PackedStringArray()
	for category in _keybinds_dict:
		keybinds += get_keybinds(category)
	return keybinds

static func is_keybind_modifiable(keybind: String) -> bool:
	for category in _keybinds_dict:
		if _keybinds_dict[category].has(keybind):
			return _keybinds_dict[category][keybind]
	return false

static func is_action_pressed(event: InputEvent, action: String) -> bool:
	return event.is_action_pressed(action) and GlobalSettings.is_shortcut_valid(event)
