extends Node


var global_rid: RID
var appl_rid: RID
var help_rid: RID

var file_rid: RID
var file_index: int
var file_clear_svg_index: int
var file_optimize_index: int
var file_clear_assoc_index: int
var file_reset_svg_index: int

var edit_rid: RID
var edit_index: int
var tool_rid: RID
var tool_index: int

var view_rid: RID
var view_index: int
var view_show_grid_index: int
var view_show_handles_index: int
var view_rasterized_svg_index: int

var snap_rid: RID
var snap_index: int
var snap_enable_index: int
var snap_0125_index: int
var snap_025_index: int
var snap_05_index: int
var snap_1_index: int
var snap_2_index: int
var snap_4_index: int


func _enter_tree() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_GLOBAL_MENU):
		queue_free()
		return
	# Included menus.
	global_rid = NativeMenu.get_system_menu(NativeMenu.MAIN_MENU_ID)
	appl_rid = NativeMenu.get_system_menu(NativeMenu.APPLICATION_MENU_ID)
	help_rid = NativeMenu.get_system_menu(NativeMenu.HELP_MENU_ID)
	# Custom menus.
	_generate_main_menus()
	_setup_menu_items()
	GlobalSettings.keybinds_changed.connect(_reset_menu_items)
	SVG.svg_text_changed.connect(_on_svg_text_changed)


func _notification(what: int) -> void:
	if what == Utils.CustomNotification.LANGUAGE_CHANGED:
		_clear_menu_items()
		NativeMenu.remove_item(global_rid, snap_index)
		NativeMenu.remove_item(global_rid, view_index)
		NativeMenu.remove_item(global_rid, tool_index)
		NativeMenu.remove_item(global_rid, edit_index)
		NativeMenu.remove_item(global_rid, file_index)
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
	file_index = NativeMenu.add_submenu_item(global_rid, tr("File"), file_rid)
	edit_index = NativeMenu.add_submenu_item(global_rid, tr("Edit"), edit_rid)
	tool_index = NativeMenu.add_submenu_item(global_rid, tr("Tool"), tool_rid)
	view_index = NativeMenu.add_submenu_item(global_rid, tr("View"), view_rid)
	snap_index = NativeMenu.add_submenu_item(global_rid, tr("Snap"), snap_rid)


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
	_add_action(appl_rid, "open_settings", tr("GodSVG Settings..."))
	NativeMenu.add_icon_item(help_rid, load("res://visual/icons/Gear.svg"), tr("GodSVG Settings..."), _action_call, _action_call, "open_settings")
	NativeMenu.add_icon_item(help_rid, load("res://visual/icons/Link.svg"), tr("GodSVG Repository"), _action_call, _action_call, "about_repo")
	NativeMenu.add_icon_item(help_rid, load("res://visual/icon.svg"), tr("About GodSVG"), _action_call, _action_call, "about_info")
	NativeMenu.add_icon_item(help_rid, load("res://visual/icons/Heart.svg"), tr("Donate to GodSVG"), _action_call, _action_call, "about_donate")
	# File menu.
	_add_action(file_rid, "import", tr("Import SVG"))
	_add_action(file_rid, "export", tr("Export Image"))
	_add_action(file_rid, "save", tr("Export SVG"))
	NativeMenu.add_separator(file_rid)
	_add_action(file_rid, "copy_svg_text")
	file_clear_svg_index = _add_action(file_rid, "clear_svg")
	file_optimize_index = _add_action(file_rid, "optimize_svg")
	NativeMenu.add_separator(file_rid)
	file_clear_assoc_index = _add_action(file_rid, "clear_file_path", tr("Clear Association"))
	file_reset_svg_index = _add_action(file_rid, "reset_svg")
	_on_svg_text_changed()
	# Edit and Tool menus.
	_add_many_actions(edit_rid, GlobalSettings.configurable_keybinds["edit"])
	_add_many_actions(tool_rid, GlobalSettings.unconfigurable_keybinds)
	# View menu.
	view_show_grid_index = NativeMenu.add_check_item(view_rid, tr("Show Grid"), _action_call, _action_call, "view_show_grid")
	view_show_handles_index = NativeMenu.add_check_item(view_rid, tr("Show Handles"), _action_call, _action_call, "view_show_handles")
	view_rasterized_svg_index = NativeMenu.add_check_item(view_rid, tr("Rasterized SVG"), _action_call, _action_call, "view_rasterized_svg")
	_on_display_view_settings_updated(true, true, false)
	NativeMenu.add_separator(view_rid)
	_add_action(view_rid, "zoom_in")
	_add_action(view_rid, "zoom_out")
	_add_action(view_rid, "zoom_reset")
	# Snap menu.
	snap_enable_index = NativeMenu.add_check_item(snap_rid, tr("Enable Snap"), _action_call, _action_call, "snap_toggle")
	NativeMenu.add_separator(snap_rid)
	snap_0125_index = NativeMenu.add_radio_check_item(snap_rid, "0.125", _set_snap, _set_snap, 0.125)
	snap_025_index = NativeMenu.add_radio_check_item(snap_rid, "0.25", _set_snap, _set_snap, 0.25)
	snap_05_index = NativeMenu.add_radio_check_item(snap_rid, "0.5", _set_snap, _set_snap, 0.5)
	snap_1_index = NativeMenu.add_radio_check_item(snap_rid, "1", _set_snap, _set_snap, 1)
	snap_2_index = NativeMenu.add_radio_check_item(snap_rid, "2", _set_snap, _set_snap, 2)
	snap_4_index = NativeMenu.add_radio_check_item(snap_rid, "4", _set_snap, _set_snap, 4)


func _add_many_actions(menu_rid: RID, actions: Array) -> void:
	for action in actions:
		_add_action(menu_rid, action)


func _add_action(menu_rid: RID, action_name: StringName, display_name: String = "") -> int:
	if display_name.is_empty():
		display_name = action_name.capitalize().replace("Svg", "SVG")
	display_name = tr(display_name)
	var key = _get_keycode_for_events(InputMap.action_get_events(action_name))
	return NativeMenu.add_item(menu_rid, display_name, _action_call, _action_call, action_name, key)


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


func _on_svg_text_changed() -> void:
	NativeMenu.set_item_disabled(file_rid, file_clear_svg_index, SVG.text == SVG.DEFAULT)
	var empty_path: bool = GlobalSettings.save_data.current_file_path.is_empty()
	NativeMenu.set_item_disabled(file_rid, file_clear_assoc_index, empty_path)
	NativeMenu.set_item_disabled(file_rid, file_reset_svg_index, empty_path or SVG.does_svg_data_match_disk_contents())


func _on_code_editor_optimize_button_enable_updated(is_optimize_enabled: bool) -> void:
	NativeMenu.set_item_disabled(file_rid, file_optimize_index, not is_optimize_enabled)


func _on_display_view_settings_updated(show_grid: bool, show_handles: bool, rasterized_svg: bool) -> void:
	NativeMenu.set_item_checked(view_rid, view_show_grid_index, show_grid)
	NativeMenu.set_item_checked(view_rid, view_show_handles_index, show_handles)
	NativeMenu.set_item_checked(view_rid, view_rasterized_svg_index, rasterized_svg)


func _on_display_snap_settings_updated(snap_enabled: bool, snap_amount: float) -> void:
	NativeMenu.set_item_checked(snap_rid, snap_enable_index, snap_enabled)
	NativeMenu.set_item_checked(snap_rid, snap_0125_index, false)
	NativeMenu.set_item_checked(snap_rid, snap_025_index, false)
	NativeMenu.set_item_checked(snap_rid, snap_05_index, false)
	NativeMenu.set_item_checked(snap_rid, snap_1_index, false)
	NativeMenu.set_item_checked(snap_rid, snap_2_index, false)
	NativeMenu.set_item_checked(snap_rid, snap_4_index, false)
	if is_equal_approx(snap_amount, 0.125):
		NativeMenu.set_item_checked(snap_rid, snap_0125_index, true)
	elif is_equal_approx(snap_amount, 0.25):
		NativeMenu.set_item_checked(snap_rid, snap_025_index, true)
	elif is_equal_approx(snap_amount, 0.5):
		NativeMenu.set_item_checked(snap_rid, snap_05_index, true)
	elif is_equal_approx(snap_amount, 1):
		NativeMenu.set_item_checked(snap_rid, snap_1_index, true)
	elif is_equal_approx(snap_amount, 2):
		NativeMenu.set_item_checked(snap_rid, snap_2_index, true)
	elif is_equal_approx(snap_amount, 4):
		NativeMenu.set_item_checked(snap_rid, snap_4_index, true)


func _set_snap(tag: float) -> void:
	%Display.set_snap_amount(tag)


func _action_call(tag: StringName) -> void:
	var a = InputEventAction.new()
	a.action = tag
	a.pressed = true
	Input.parse_input_event(a)
