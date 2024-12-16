# This singleton handles settings.
extends Node

# A compilation of signals 
@warning_ignore("unused_signal")
signal highlighting_colors_changed
@warning_ignore("unused_signal")
signal snap_changed
@warning_ignore("unused_signal")
signal language_changed
@warning_ignore("unused_signal")
signal ui_scale_changed
@warning_ignore("unused_signal")
signal theme_changed
@warning_ignore("unused_signal")
signal shortcuts_changed
@warning_ignore("unused_signal")
signal basic_colors_changed
@warning_ignore("unused_signal")
signal handle_visuals_changed
@warning_ignore("unused_signal")
signal layout_changed

var _save_queued := false

var DEFAULT_SAVEDATA := SaveData.new()
const savedata_path = "user://savedata.tres"

var savedata: SaveData

var svg_text := "":
	set(new_value):
		if new_value != svg_text:
			svg_text = new_value
			savedata.get_current_tab().update_svg_text(svg_text)


func get_default(setting: String) -> Variant:
	return DEFAULT_SAVEDATA.get(setting)

func save() -> void:
	ResourceSaver.save(savedata, savedata_path)


var default_shortcuts := {}

func _enter_tree() -> void:
	for action in InputMap.get_actions():
		if action in ShortcutUtils.get_all_shortcuts():
			default_shortcuts[action] = InputMap.action_get_events(action)
	load_config()
	ThemeConfig.generate_and_apply_theme()
	# Connect to settings that have a global effect.
	sync_window_title()


func load_config() -> void:
	if not FileAccess.file_exists(savedata_path):
		reset_settings()
		return
	
	var loaded_savedata := ResourceLoader.load(savedata_path)
	if not is_instance_valid(loaded_savedata) or not loaded_savedata is SaveData:
		reset_settings()
		return
	
	if not is_instance_valid(loaded_savedata.theme_config):
		loaded_savedata.theme_config = ThemeConfig.new(ThemeConfig.Preset.DEFAULT_DARK)
	
	if not is_instance_valid(loaded_savedata.editor_formatter):
		loaded_savedata.editor_formatter = Formatter.new(Formatter.Preset.PRETTY)
	
	if not is_instance_valid(loaded_savedata.export_formatter):
		loaded_savedata.export_formatter = Formatter.new(Formatter.Preset.COMPACT)
	
	for action in ShortcutUtils.get_all_shortcuts():
		if ShortcutUtils.is_shortcut_modifiable(action):
			if loaded_savedata.action_has_shortcuts(action):
				loaded_savedata.apply_shortcut(action, savedata.shortcuts[action])
	
	savedata = loaded_savedata
	sync_window_title()
	sync_background_color()
	sync_locale()


func reset_settings() -> void:
	# Set up the SaveData before getting the signals paired.
	var new_savedata := SaveData.new()
	new_savedata.add_empty_tab()
	new_savedata.set_palettes([ColorPalette.new("Pure", ColorPalette.Preset.PURE)])
	new_savedata.editor_formatter = Formatter.new(Formatter.Preset.PRETTY)
	new_savedata.export_formatter = Formatter.new(Formatter.Preset.COMPACT)
	new_savedata.theme_config = ThemeConfig.new(ThemeConfig.Preset.DEFAULT_DARK)
	savedata = new_savedata


func _queue_save() -> void:
	_save_queued = true
	_save.call_deferred()

func _save() -> void:
	if _save_queued:
		_save_queued = false
		save()


# Just some helpers.

func get_actions_with_shortcut(shortcut: InputEvent) -> PackedStringArray:
	var shortcut_id = shortcut.get_keycode_with_modifiers()
	if not shortcut_id in savedata.shortcut_validities:
		return PackedStringArray()
	elif savedata.hortcut_validities[shortcut_id]:
		return PackedStringArray()
	
	var actions_with_shortcut := PackedStringArray()
	for action in ShortcutUtils.get_all_shortcuts():
		for action_shortcut: InputEventKey in InputMap.action_get_events(action):
			if action_shortcut.get_keycode_with_modifiers() == shortcut_id:
				actions_with_shortcut.append(action)
				break
	return actions_with_shortcut


# Global effects from settings. Some of them should also be used on launch.

func sync_window_title() -> void:
	var tab := savedata.get_current_tab()
	if savedata.use_filename_for_window_title and tab != null and\
	not tab.svg_file_path.is_empty():
		get_window().title = savedata.current_file_path.get_file() + " - GodSVG"
	else:
		get_window().title = "GodSVG"

func sync_background_color() -> void:
	RenderingServer.set_default_clear_color(savedata.theme_config.background_color)

func sync_locale() -> void:
	TranslationServer.set_locale(savedata.language)
