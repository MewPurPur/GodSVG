# The MacOS-specific top menu.
extends Node

var global_rid: RID
var appl_rid: RID
var help_rid: RID

var file_rid: RID
var file_idx: int
var file_clear_svg_idx: int
var file_optimize_idx: int
var file_clear_association_idx: int
var file_reset_svg_idx: int

var edit_rid: RID
var edit_idx: int
var tool_rid: RID
var tool_idx: int

var view_rid: RID
var view_idx: int
var view_show_grid_idx: int
var view_show_handles_idx: int
var view_rasterized_svg_idx: int

var snap_rid: RID
var snap_idx: int
var snap_enable_idx: int
var snap_0125_idx: int
var snap_025_idx: int
var snap_05_idx: int
var snap_1_idx: int
var snap_2_idx: int
var snap_4_idx: int


func _enter_tree() -> void:
	Configs.language_changed.connect(_reset_menus)
	Configs.shortcuts_changed.connect(_reset_menu_items)
	# Included menus.
	global_rid = NativeMenu.get_system_menu(NativeMenu.MAIN_MENU_ID)
	appl_rid = NativeMenu.get_system_menu(NativeMenu.APPLICATION_MENU_ID)
	help_rid = NativeMenu.get_system_menu(NativeMenu.HELP_MENU_ID)
	# Custom menus.
	_generate_main_menus()
	_setup_menu_items()
	SVG.changed.connect(_on_svg_changed)
	Configs.file_path_changed.connect(_on_file_path_changed)


func _reset_menus() -> void:
	_clear_menu_items()
	NativeMenu.remove_item(global_rid, snap_idx)
	NativeMenu.remove_item(global_rid, view_idx)
	NativeMenu.remove_item(global_rid, tool_idx)
	NativeMenu.remove_item(global_rid, edit_idx)
	NativeMenu.remove_item(global_rid, file_idx)
	NativeMenu.free_menu(file_rid)
	NativeMenu.free_menu(edit_rid)
	NativeMenu.free_menu(tool_rid)
	NativeMenu.free_menu(view_rid)
	NativeMenu.free_menu(snap_rid)
	_generate_main_menus()
	_setup_menu_items()


func _generate_main_menus() -> void:
	file_rid = NativeMenu.create_menu()
	edit_rid = NativeMenu.create_menu()
	tool_rid = NativeMenu.create_menu()
	view_rid = NativeMenu.create_menu()
	snap_rid = NativeMenu.create_menu()
	file_idx = NativeMenu.add_submenu_item(global_rid,
			Translator.translate("File"), file_rid)
	edit_idx = NativeMenu.add_submenu_item(global_rid,
			Translator.translate("Edit"), edit_rid)
	tool_idx = NativeMenu.add_submenu_item(global_rid,
			Translator.translate("Tool"), tool_rid)
	view_idx = NativeMenu.add_submenu_item(global_rid,
			Translator.translate("View"), view_rid)
	snap_idx = NativeMenu.add_submenu_item(global_rid,
			Translator.translate("Snap"), snap_rid)


func _reset_menu_items() -> void:
	_setup_menu_items()


func _clear_menu_items() -> void:
	NativeMenu.clear(appl_rid)
	NativeMenu.clear(help_rid)
	NativeMenu.clear(file_rid)
	NativeMenu.clear(edit_rid)
	NativeMenu.clear(tool_rid)
	NativeMenu.clear(view_rid)
	NativeMenu.clear(snap_rid)


func _setup_menu_items() -> void:
	# Included App and Help menus.
	_add_action(appl_rid, "open_settings")
	_add_icon_item(help_rid, "open_settings", load("res://assets/icons/Gear.svg"))
	_add_icon_item(help_rid, "about_repo", load("res://assets/icons/Link.svg"))
	_add_icon_item(help_rid, "about_info", load("res://assets/logos/icon.svg"))
	_add_icon_item(help_rid, "about_donate", load("res://assets/icons/Heart.svg"))
	_add_icon_item(help_rid, "about_website", load("res://assets/icons/Link.svg"))
	_add_icon_item(help_rid, "check_updates", load("res://assets/icons/Reload.svg"))
	# File menu.
	_add_action(file_rid, "import")
	_add_action(file_rid, "export")
	_add_action(file_rid, "save")
	NativeMenu.add_separator(file_rid)
	_add_action(file_rid, "copy_svg_text")
	file_clear_svg_idx = _add_action(file_rid, "clear_svg")
	file_optimize_idx = _add_action(file_rid, "optimize")
	NativeMenu.add_separator(file_rid)
	file_clear_association_idx = _add_action(file_rid, "clear_file_path")
	file_reset_svg_idx = _add_action(file_rid, "reset_svg")
	_on_svg_changed()
	_on_file_path_changed()
	# Edit and Tool menus.
	_add_many_actions(edit_rid, ShortcutUtils.get_shortcuts("edit"))
	_add_many_actions(tool_rid, ShortcutUtils.get_shortcuts("tool"))
	# View menu.
	view_show_grid_idx = _add_check_item(view_rid, "view_show_grid")
	view_show_handles_idx = _add_check_item(view_rid, "view_show_handles")
	view_rasterized_svg_idx = _add_check_item(view_rid, "view_rasterized_svg")
	_on_display_view_settings_updated(true, true, false)
	NativeMenu.add_separator(view_rid)
	_add_action(view_rid, "zoom_in")
	_add_action(view_rid, "zoom_out")
	_add_action(view_rid, "zoom_reset")
	# Snap menu.
	snap_enable_idx = _add_check_item(snap_rid, "toggle_snap")
	NativeMenu.add_separator(snap_rid)
	snap_0125_idx = NativeMenu.add_radio_check_item(snap_rid, "0.125", _set_snap, _set_snap, 0.125)
	snap_025_idx = NativeMenu.add_radio_check_item(snap_rid, "0.25", _set_snap, _set_snap, 0.25)
	snap_05_idx = NativeMenu.add_radio_check_item(snap_rid, "0.5", _set_snap, _set_snap, 0.5)
	snap_1_idx = NativeMenu.add_radio_check_item(snap_rid, "1", _set_snap, _set_snap, 1)
	snap_2_idx = NativeMenu.add_radio_check_item(snap_rid, "2", _set_snap, _set_snap, 2)
	snap_4_idx = NativeMenu.add_radio_check_item(snap_rid, "4", _set_snap, _set_snap, 4)


func _add_many_actions(menu_rid: RID, actions: Array) -> void:
	for action in actions:
		_add_action(menu_rid, action)


func _add_action(menu_rid: RID, action_name: StringName) -> int:
	var display_name = _get_action_display_name(action_name)
	var key = _get_keycode_for_events(InputMap.action_get_events(action_name))
	return NativeMenu.add_item(menu_rid, display_name, _action_call, _action_call, action_name, key)


func _add_check_item(menu_rid: RID, action_name: StringName) -> int:
	var display_name = _get_action_display_name(action_name)
	return NativeMenu.add_check_item(menu_rid, display_name, _action_call, _action_call, action_name)


func _add_icon_item(menu_rid: RID, action_name: StringName, icon: Texture2D) -> int:
	var display_name = _get_action_display_name(action_name)
	return NativeMenu.add_icon_item(menu_rid, icon, display_name, _action_call, _action_call, action_name)


func _get_action_display_name(action_name: StringName) -> String:
	var display_name = TranslationUtils.get_shortcut_description(action_name)
	if display_name.is_empty():
		display_name = action_name.capitalize().replace("Svg", "SVG")
	return display_name


func _get_keycode_for_events(input_events: Array[InputEvent]) -> Key:
	for input_event in input_events:
		if input_event is InputEventKey:
			var key = input_event.get_keycode_with_modifiers()
			if key != KEY_NONE:
				return key
			key = input_event.get_physical_keycode_with_modifiers()
			if key != KEY_NONE:
				return key
	return KEY_NONE


func _on_svg_changed() -> void:
	NativeMenu.set_item_disabled(file_rid, file_clear_svg_idx, SVG.text == SVG.DEFAULT)
	NativeMenu.set_item_disabled(file_rid, file_reset_svg_idx,
			FileUtils.compare_svg_to_disk_contents() == FileUtils.FileState.DIFFERENT)

func _on_file_path_changed() -> void:
	NativeMenu.set_item_disabled(file_rid, file_clear_association_idx,
			Configs.savedata.current_file_path.is_empty())


func _on_display_view_settings_updated(show_grid: bool, show_handles: bool, rasterized_svg: bool) -> void:
	NativeMenu.set_item_checked(view_rid, view_show_grid_idx, show_grid)
	NativeMenu.set_item_checked(view_rid, view_show_handles_idx, show_handles)
	NativeMenu.set_item_checked(view_rid, view_rasterized_svg_idx, rasterized_svg)


func _on_display_snap_settings_updated(snap_enabled: bool, snap_amount: float) -> void:
	NativeMenu.set_item_checked(snap_rid, snap_enable_idx, snap_enabled)
	NativeMenu.set_item_checked(snap_rid, snap_0125_idx, is_equal_approx(snap_amount, 0.125))
	NativeMenu.set_item_checked(snap_rid, snap_025_idx, is_equal_approx(snap_amount, 0.25))
	NativeMenu.set_item_checked(snap_rid, snap_05_idx, is_equal_approx(snap_amount, 0.5))
	NativeMenu.set_item_checked(snap_rid, snap_1_idx, is_equal_approx(snap_amount, 1))
	NativeMenu.set_item_checked(snap_rid, snap_2_idx, is_equal_approx(snap_amount, 2))
	NativeMenu.set_item_checked(snap_rid, snap_4_idx, is_equal_approx(snap_amount, 4))


func _set_snap(tag: float) -> void:
	%Display.set_snap_amount(tag)


func _action_call(tag: StringName) -> void:
	var a = InputEventAction.new()
	a.action = tag
	a.pressed = true
	Input.parse_input_event(a)
