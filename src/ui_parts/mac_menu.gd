# The MacOS-specific top menu.
extends Node

var global_rid: RID
var appl_rid: RID
var help_rid: RID

var file_rid: RID
var file_idx: int
var file_optimize_idx: int
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
var view_show_reference_idx: int
var view_overlay_reference_idx: int
var view_show_debug_idx: int

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
	# Included menus
	global_rid = NativeMenu.get_system_menu(NativeMenu.MAIN_MENU_ID)
	appl_rid = NativeMenu.get_system_menu(NativeMenu.APPLICATION_MENU_ID)
	help_rid = NativeMenu.get_system_menu(NativeMenu.HELP_MENU_ID)
	# Custom menus
	_generate_main_menus()
	_setup_menu_items()
	# Updates
	Configs.language_changed.connect(_reset_menus)
	Configs.shortcuts_changed.connect(_reset_menus)
	# For now only keep check items up to date. Disabling things reliably is complicated.
	Configs.snap_changed.connect(_on_snap_changed)
	State.view_rasterized_changed.connect(_on_view_rasterized_changed)
	State.show_grid_changed.connect(_on_show_grid_changed)
	State.show_handles_changed.connect(_on_show_handles_changed)
	State.show_reference_changed.connect(_on_show_reference_changed)
	State.overlay_reference_changed.connect(_on_overlay_reference_changed)
	State.show_debug_changed.connect(_on_show_debug_changed)
	# Updating checked items didn't work without the await.
	await get_tree().process_frame
	_on_snap_changed()
	_on_view_rasterized_changed()
	_on_show_grid_changed()
	_on_show_handles_changed()
	_on_show_reference_changed()
	_on_overlay_reference_changed()
	_on_show_debug_changed()


func _reset_menus() -> void:
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


func _clear_menu_items() -> void:
	NativeMenu.clear(appl_rid)
	NativeMenu.clear(help_rid)
	NativeMenu.clear(file_rid)
	NativeMenu.clear(edit_rid)
	NativeMenu.clear(tool_rid)
	NativeMenu.clear(view_rid)
	NativeMenu.clear(snap_rid)


func _setup_menu_items() -> void:
	_clear_menu_items()
	_add_item(appl_rid, "open_settings")
	# Help menu.
	_add_icon_item(help_rid, "open_settings")
	_add_icon_item(help_rid, "about_repo")
	_add_icon_item(help_rid, "about_info")
	_add_icon_item(help_rid, "about_donate")
	_add_icon_item(help_rid, "about_website")
	_add_icon_item(help_rid, "check_updates")
	# File menu.
	_add_many_items(file_rid, PackedStringArray(["import", "export", "save", "save_as"]))
	NativeMenu.add_separator(file_rid)
	_add_item(file_rid, "copy_svg_text")
	file_optimize_idx = _add_item(file_rid, "optimize")
	NativeMenu.add_separator(file_rid)
	file_reset_svg_idx = _add_item(file_rid, "reset_svg")
	# Edit and Tool menus.
	_add_many_items(edit_rid, ShortcutUtils.get_actions(ShortcutUtils.ShortcutCategory.EDIT))
	_add_many_items(tool_rid, ShortcutUtils.get_actions(ShortcutUtils.ShortcutCategory.TOOL))
	# View menu.
	view_show_grid_idx = _add_check_item(view_rid, "view_show_grid")
	view_show_handles_idx = _add_check_item(view_rid, "view_show_handles")
	view_rasterized_svg_idx = _add_check_item(view_rid, "view_rasterized_svg")
	NativeMenu.add_separator(view_rid)
	view_show_reference_idx = _add_item(view_rid, "load_reference")
	view_show_reference_idx = _add_check_item(view_rid, "view_show_reference")
	view_overlay_reference_idx = _add_check_item(view_rid, "view_overlay_reference")
	view_show_debug_idx = _add_check_item(view_rid, "view_show_debug")
	NativeMenu.add_separator(view_rid)
	_add_many_items(view_rid, PackedStringArray(["zoom_in", "zoom_out", "zoom_reset"]))
	# Snap menu.
	snap_enable_idx = _add_check_item(snap_rid, "toggle_snap")
	NativeMenu.add_separator(snap_rid)
	snap_0125_idx = NativeMenu.add_radio_check_item(snap_rid, "0.125", _set_snap, _set_snap, 0.125)
	snap_025_idx = NativeMenu.add_radio_check_item(snap_rid, "0.25", _set_snap, _set_snap, 0.25)
	snap_05_idx = NativeMenu.add_radio_check_item(snap_rid, "0.5", _set_snap, _set_snap, 0.5)
	snap_1_idx = NativeMenu.add_radio_check_item(snap_rid, "1", _set_snap, _set_snap, 1)
	snap_2_idx = NativeMenu.add_radio_check_item(snap_rid, "2", _set_snap, _set_snap, 2)
	snap_4_idx = NativeMenu.add_radio_check_item(snap_rid, "4", _set_snap, _set_snap, 4)


func _add_item(menu_rid: RID, action_name: String) -> int:
	return NativeMenu.add_item(menu_rid,
			TranslationUtils.get_action_description(action_name),
			HandlerGUI.throw_action_event, HandlerGUI.throw_action_event, action_name,
			_get_action_keycode(action_name))

func _add_many_items(menu_rid: RID, actions: PackedStringArray) -> void:
	for action in actions:
		_add_item(menu_rid, action)

func _add_check_item(menu_rid: RID, action_name: String) -> int:
	return NativeMenu.add_check_item(menu_rid,
			TranslationUtils.get_action_description(action_name),
			HandlerGUI.throw_action_event, HandlerGUI.throw_action_event, action_name)

func _add_many_icon_items(menu_rid: RID, actions: PackedStringArray) -> void:
	for action in actions:
		_add_icon_item(menu_rid, action)

func _add_icon_item(menu_rid: RID, action_name: String) -> int:
	return NativeMenu.add_icon_item(menu_rid,
			ShortcutUtils.get_action_icon(action_name),
			TranslationUtils.get_action_description(action_name),
			HandlerGUI.throw_action_event, HandlerGUI.throw_action_event, action_name)


func _get_action_keycode(action: String) -> Key:
	var shortcut := ShortcutUtils.get_action_first_valid_shortcut(action)
	if is_instance_valid(shortcut):
		return shortcut.get_keycode_with_modifiers()
	return KEY_NONE


func _on_view_rasterized_changed() -> void:
	NativeMenu.set_item_checked(view_rid, view_rasterized_svg_idx, State.view_rasterized)

func _on_show_grid_changed() -> void:
	NativeMenu.set_item_checked(view_rid, view_show_grid_idx, State.show_grid)

func _on_show_handles_changed() -> void:
	NativeMenu.set_item_checked(view_rid, view_show_handles_idx, State.show_handles)

func _on_show_reference_changed() -> void:
	NativeMenu.set_item_checked(view_rid, view_show_reference_idx, State.show_reference)

func _on_overlay_reference_changed() -> void:
	NativeMenu.set_item_checked(view_rid, view_overlay_reference_idx, State.overlay_reference)

func _on_show_debug_changed() -> void:
	NativeMenu.set_item_checked(view_rid, view_show_debug_idx, State.show_debug)


func _on_snap_changed() -> void:
	var snap_amount := absf(Configs.savedata.snap)
	NativeMenu.set_item_checked(snap_rid, snap_enable_idx, Configs.savedata.snap > 0)
	NativeMenu.set_item_checked(snap_rid, snap_0125_idx, is_equal_approx(snap_amount, 0.125))
	NativeMenu.set_item_checked(snap_rid, snap_025_idx, is_equal_approx(snap_amount, 0.25))
	NativeMenu.set_item_checked(snap_rid, snap_05_idx, is_equal_approx(snap_amount, 0.5))
	NativeMenu.set_item_checked(snap_rid, snap_1_idx, is_equal_approx(snap_amount, 1))
	NativeMenu.set_item_checked(snap_rid, snap_2_idx, is_equal_approx(snap_amount, 2))
	NativeMenu.set_item_checked(snap_rid, snap_4_idx, is_equal_approx(snap_amount, 4))

func _set_snap(amount: float) -> void:
	Configs.savedata.snap = amount
