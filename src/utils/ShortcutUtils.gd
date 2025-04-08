class_name ShortcutUtils extends RefCounted

# Can be activated in all contexts.
const UNIVERSAL_ACTIONS: PackedStringArray = ["quit", "about_info", "about_donate",
		"check_updates", "open_settings", "about_repo", "about_website", "open_externally",
		"open_in_folder"]

# Requires there being no dialogs.
const EFFECT_ACTIONS: PackedStringArray = ["view_show_grid", "view_show_handles",
		"view_rasterized_svg", "view_show_reference", "view_overlay_reference",
		"load_reference", "toggle_snap"]

# Requires there being no popups either.
const EDITOR_ACTIONS: PackedStringArray = ["import", "export", "save", "save_as",
		"close_tab", "close_tabs_to_left", "close_tabs_to_right", "close_all_other_tabs",
		"new_tab", "select_next_tab", "select_previous_tab", "copy_svg_text", "optimize",
		"reset_svg", "debug"]

# Requires no drag-and-drop actions ongoing.
const PRISTINE_ACTIONS: PackedStringArray = ["ui_undo", "ui_redo", "ui_cancel", "delete",
		"move_up", "move_down", "duplicate", "select_all"]


# The bool after each action is for whether the action can be modified.
const _action_categories_dict: Dictionary[String, Dictionary] = {
	"file": {
		"import": true,
		"export": true,
		"save": true,
		"save_as": true,
		"close_tab": true,
		"close_tabs_to_left": true,
		"close_tabs_to_right": true,
		"close_all_other_tabs": true,
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
		"ui_undo": true,
		"ui_redo": true,
		"ui_copy": true,
		"ui_paste": true,
		"ui_cut": true,
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

static func get_shortcut_icon(shortcut: String) -> CompressedTexture2D:
	match shortcut:
		"ui_paste": return load("res://assets/icons/Paste.svg")
		"ui_cut": return load("res://assets/icons/Cut.svg")
		"import": return load("res://assets/icons/Import.svg")
		"export": return load("res://assets/icons/Export.svg")
		"save", "save_as": return load("res://assets/icons/Save.svg")
		"new_tab": return load("res://assets/icons/CreateTab.svg")
		"copy_svg_text", "ui_copy": return load("res://assets/icons/Copy.svg")
		"optimize": return load("res://assets/icons/Compress.svg")
		"reset_svg", "zoom_reset", "check_updates": return load("res://assets/icons/Reload.svg")
		"open_externally": return load("res://assets/icons/OpenFile.svg")
		"open_in_folder": return load("res://assets/icons/OpenFolder.svg")
		"ui_undo": return load("res://assets/icons/Undo.svg")
		"ui_redo": return load("res://assets/icons/Redo.svg")
		"duplicate": return load("res://assets/icons/Duplicate.svg")
		"move_up": return load("res://assets/icons/MoveUp.svg")
		"move_down": return load("res://assets/icons/MoveDown.svg")
		"delete": return load("res://assets/icons/Delete.svg")
		"find": return load("res://assets/icons/Search.svg")
		"zoom_in": return load("res://assets/icons/Plus.svg")
		"zoom_out": return load("res://assets/icons/Minus.svg")
		"debug": return load("res://assets/icons/Debug.svg")
		"toggle_snap": return load("res://assets/icons/Snap.svg")
		"quit": return load("res://assets/icons/Quit.svg")
		"open_settings": return load("res://assets/icons/Gear.svg")
		"about_donate": return load("res://assets/icons/Heart.svg")
		"about_repo", "about_website": return load("res://assets/icons/Link.svg")
		"load_reference": return load("res://assets/icons/Reference.svg")
		_: return load("res://assets/icons/Placeholder.svg")

static func get_actions(category: String) -> PackedStringArray:
	return _action_categories_dict[category].keys()

static func get_all_actions() -> PackedStringArray:
	var shortcuts := PackedStringArray()
	for category in _action_categories_dict:
		shortcuts += get_actions(category)
	return shortcuts

static func is_action_modifiable(shortcut: String) -> bool:
	for category in _action_categories_dict:
		if _action_categories_dict[category].has(shortcut):
			return _action_categories_dict[category][shortcut]
	return false

static func get_action_showcase_text(action: String) -> String:
	var shortcut := get_action_first_valid_shortcut(action)
	if is_instance_valid(shortcut):
		return shortcut.as_text_keycode()
	return ""

static func get_action_all_valid_shortcuts(action: String) -> Array[InputEventKey]:
	var shortcuts: Array[InputEventKey] = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and is_shortcut_valid(event, action):
			shortcuts.append(event.duplicate())
	return shortcuts

static func get_action_first_valid_shortcut(action: String) -> InputEventKey:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and is_shortcut_valid(event, action):
			return event
	return null

static func is_shortcut_valid(shortcut: InputEventKey, action: String) -> bool:
	return not is_action_modifiable(action) or Configs.savedata.is_shortcut_valid(shortcut)

static func is_action_pressed(event: InputEvent, action: String) -> bool:
	# TODO Sometimes MacOS gives us an InputEventAction here.
	# This doesn't happen on my Linux laptop. I don't know which platform's behavior
	# is the correct one... But it should be handled gracefully.
	if event is InputEventAction:
		if event.event_index == -1:
			# The action has no associated shortcut, so we don't need to check validity.
			return event.pressed and event.action == action
		event = InputMap.action_get_events(event.action)[event.event_index]
	return event.is_action_pressed(action, false, true) and is_shortcut_valid(event, action)
