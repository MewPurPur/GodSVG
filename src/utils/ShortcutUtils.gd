class_name ShortcutUtils extends RefCounted

# The bool after each action is for whether the shortcut can be modified.
const _shortcut_categories_dict: Dictionary[String, Dictionary] = {
	"file": {
		"import": true,
		"export": true,
		"save": true,
		"save_as": true,
		"close_tab": true,
		"new_tab": true,
		"select_next_tab": true,
		"select_previous_tab": true,
		"optimize": true,
		"copy_svg_text": true,
		"reset_svg": true,
		"open_externally": true,
		"open_in_folder": true,
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
# Should bind only constants, otherwise the binds can get outdated before being used.
static func fn(shortcut: String) -> Callable:
	match shortcut:
		"save": return FileUtils.save_svg
		"save_as": return FileUtils.save_svg_as
		"export": return HandlerGUI.open_export
		"import": return FileUtils.open_svg_import_dialog
		"close_tab": return FileUtils.close_tabs.bind(Configs.savedata.get_active_tab_index())
		"new_tab": return Configs.savedata.add_empty_tab
		"select_next_tab": return func() -> void: Configs.savedata.set_active_tab_index(
				posmod(Configs.savedata.get_active_tab_index() + 1,
				Configs.savedata.get_tab_count()))
		"select_previous_tab": return func() -> void: Configs.savedata.set_active_tab_index(
				posmod(Configs.savedata.get_active_tab_index() - 1,
				Configs.savedata.get_tab_count()))
		"copy_svg_text": return DisplayServer.clipboard_set.bind(State.svg_text)
		"optimize": return State.optimize
		"reset_svg": return FileUtils.reset_svg
		"open_externally": return func() -> void: FileUtils.open_svg(
				Configs.savedata.get_active_tab().svg_file_path)
		"open_in_folder": return func() -> void: FileUtils.open_svg_folder(
				Configs.savedata.get_active_tab().svg_file_path)
		"redo": return Configs.savedata.get_active_tab().redo
		"undo": return Configs.savedata.get_active_tab().undo
		"ui_cancel": return State.clear_all_selections
		"delete": return State.delete_selected
		"move_up": return State.move_up_selected
		"move_down": return State.move_down_selected
		"duplicate": return State.duplicate_selected
		"select_all": return State.select_all
		"about_info": return HandlerGUI.open_about
		"about_donate": return HandlerGUI.open_donate
		"about_repo": return OS.shell_open.bind("https://github.com/MewPurPur/GodSVG")
		"about_website": return OS.shell_open.bind("https://godsvg.com")
		"check_updates": return HandlerGUI.open_update_checker
		"open_settings": return HandlerGUI.open_settings
		"toggle_snap": return Callable()
		_: return Callable()

static func get_shortcut_icon(shortcut: String) -> CompressedTexture2D:
	match shortcut:
		"import": return load("res://assets/icons/Import.svg")
		"export": return load("res://assets/icons/Export.svg")
		"save": return load("res://assets/icons/Save.svg")
		"save_as": return load("res://assets/icons/Save.svg")
		"new_tab": return load("res://assets/icons/CreateTab.svg")
		"copy_svg_text": return load("res://assets/icons/Copy.svg")
		"optimize": return load("res://assets/icons/Compress.svg")
		"reset_svg", "zoom_reset": return load("res://assets/icons/Reload.svg")
		"open_externally": return load("res://assets/icons/OpenFile.svg")
		"open_in_folder": return load("res://assets/icons/OpenFolder.svg")
		"undo": return load("res://assets/icons/Undo.svg")
		"redo": return load("res://assets/icons/Redo.svg")
		"duplicate": return load("res://assets/icons/Duplicate.svg")
		"move_up": return load("res://assets/icons/MoveUp.svg")
		"move_down": return load("res://assets/icons/MoveDown.svg")
		"delete": return load("res://assets/icons/Delete.svg")
		"find": return load("res://assets/icons/Search.svg")
		"zoom_in": return load("res://assets/icons/Plus.svg")
		"zoom_out": return load("res://assets/icons/Minus.svg")
		"debug": return load("res://assets/icons/Debug.svg")
		"toggle_snap": return load("res://assets/icons/Snap.svg")
		"open_settings": return load("res://assets/icons/Gear.svg")
		_: return load("res://assets/icons/Placeholder.svg")

static func get_shortcuts(category: String) -> PackedStringArray:
	return _shortcut_categories_dict[category].keys()

static func get_all_shortcuts() -> PackedStringArray:
	var shortcuts := PackedStringArray()
	for category in _shortcut_categories_dict:
		shortcuts += get_shortcuts(category)
	return shortcuts

static func is_shortcut_modifiable(shortcut: String) -> bool:
	for category in _shortcut_categories_dict:
		if _shortcut_categories_dict[category].has(shortcut):
			return _shortcut_categories_dict[category][shortcut]
	return false

static func is_action_pressed(event: InputEvent, action: String) -> bool:
	# TODO Sometimes MacOS gives us an InputEventAction here.
	# This doesn't happen on my Linux laptop. I don't know which platform's behavior
	# is the correct one... But it should be handled gracefully.
	if event is InputEventAction:
		event = InputMap.action_get_events(event.action)[event.event_index]
	return event.is_action_pressed(action) and Configs.savedata.is_shortcut_valid(event)
