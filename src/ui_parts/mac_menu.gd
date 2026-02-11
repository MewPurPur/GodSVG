# The MacOS-specific top menu.
extends Node

# TODO This menu became a lot more primitive after some reworks.
# It should have a close relationship with ShortcutsRegistration.
# Logic for checked and disabled items should also be reinstated through this class.

var global_rid: RID
var appl_rid: RID
var help_rid: RID

var file_rid: RID
var file_idx: int

var edit_rid: RID
var edit_idx: int

var tool_rid: RID
var tool_idx: int

var view_rid: RID
var view_idx: int


func _enter_tree() -> void:
	global_rid = NativeMenu.get_system_menu(NativeMenu.MAIN_MENU_ID)
	appl_rid = NativeMenu.get_system_menu(NativeMenu.APPLICATION_MENU_ID)
	help_rid = NativeMenu.get_system_menu(NativeMenu.HELP_MENU_ID)
	_generate_main_menus()
	Configs.language_changed.connect(_reset_menus)
	Configs.shortcuts_changed.connect(_reset_menus)


func _reset_menus() -> void:
	NativeMenu.remove_item(global_rid, view_idx)
	NativeMenu.remove_item(global_rid, tool_idx)
	NativeMenu.remove_item(global_rid, edit_idx)
	NativeMenu.remove_item(global_rid, file_idx)
	NativeMenu.free_menu(file_rid)
	NativeMenu.free_menu(edit_rid)
	NativeMenu.free_menu(tool_rid)
	NativeMenu.free_menu(view_rid)
	_generate_main_menus()


func _generate_main_menus() -> void:
	file_rid = NativeMenu.create_menu()
	edit_rid = NativeMenu.create_menu()
	tool_rid = NativeMenu.create_menu()
	view_rid = NativeMenu.create_menu()
	file_idx = NativeMenu.add_submenu_item(global_rid, Translator.translate("File"), file_rid)
	edit_idx = NativeMenu.add_submenu_item(global_rid, Translator.translate("Edit"), edit_rid)
	tool_idx = NativeMenu.add_submenu_item(global_rid, Translator.translate("Tool"), tool_rid)
	view_idx = NativeMenu.add_submenu_item(global_rid, Translator.translate("View"), view_rid)
	
	NativeMenu.clear(appl_rid)
	NativeMenu.clear(help_rid)
	NativeMenu.clear(file_rid)
	NativeMenu.clear(edit_rid)
	NativeMenu.clear(tool_rid)
	NativeMenu.clear(view_rid)
	
	_add_item(appl_rid, "open_settings")
	
	var help_actions := ShortcutUtils.get_actions("help").duplicate()
	help_actions.erase("quit")
	_add_many_items(help_rid, help_actions)
	_add_many_items(file_rid, ShortcutUtils.get_actions("file"))
	_add_many_items(edit_rid, ShortcutUtils.get_actions("edit"))
	_add_many_items(tool_rid, ShortcutUtils.get_actions("tool"))
	_add_many_items(view_rid, ShortcutUtils.get_actions("view"))
	
	# Can be removed after issue #114204 is solved.
	await get_tree().process_frame
	NativeMenu.set_system_menu_text(NativeMenu.WINDOW_MENU_ID, Translator.translate("Window"))
	NativeMenu.set_system_menu_text(NativeMenu.HELP_MENU_ID, Translator.translate("Help"))


func _add_many_items(menu_rid: RID, actions: PackedStringArray) -> void:
	for action in actions:
		_add_item(menu_rid, action)


func _add_item(menu_rid: RID, action_name: String) -> int:
	return NativeMenu.add_item(menu_rid, TranslationUtils.get_action_description(action_name),
			HandlerGUI.throw_action_event, HandlerGUI.throw_action_event, action_name, _get_action_keycode(action_name))


func _get_action_keycode(action: String) -> Key:
	var shortcut := ShortcutUtils.get_action_first_valid_shortcut(action)
	if is_instance_valid(shortcut):
		return shortcut.get_keycode_with_modifiers()
	return KEY_NONE
