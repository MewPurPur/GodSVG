# This singleton handles session data and settings.
extends Node

@warning_ignore_start("unused_signal")
signal highlighting_colors_changed
signal snap_changed
signal language_changed
signal ui_scale_changed
signal theme_changed
signal shortcuts_changed
signal basic_colors_changed
signal handle_visuals_changed
signal selection_rectangle_visuals_changed
signal grid_color_changed
signal shortcut_panel_changed
signal active_tab_status_changed
signal active_tab_reference_changed
signal active_tab_changed
signal tabs_changed
signal layout_changed
@warning_ignore_restore("unused_signal")

const savedata_path = "user://savedata.tres"
var savedata: SaveData:
	set(new_value):
		if savedata != new_value and is_instance_valid(new_value):
			savedata = new_value
			savedata.validate()
			savedata.changed_deferred.connect(save)


func save() -> void:
	ResourceSaver.save(savedata, savedata_path)


var default_shortcuts: Dictionary[String, Array] = {}

func _enter_tree() -> void:
	# Fill up the default shortcuts dictionary before the shortcuts are loaded.
	for action in ShortcutUtils.get_all_actions():
		if InputMap.has_action(action):
			default_shortcuts[action] = InputMap.action_get_events(action)
	load_config()


func load_config() -> void:
	if not FileAccess.file_exists(savedata_path):
		reset_settings()
		return
	
	savedata = ResourceLoader.load(savedata_path)
	if not is_instance_valid(savedata):
		reset_settings()
		return
	
	post_load()


func reset_settings() -> void:
	savedata = SaveData.new()
	savedata.reset_to_default()
	savedata.language = "en"
	savedata.set_shortcut_panel_slots({ 0: "ui_undo", 1: "ui_redo" })
	savedata.set_palettes([Palette.new("Pure", Palette.Preset.PURE)])
	save()
	post_load()

func post_load() -> void:
	savedata.get_active_tab().activate()
	sync_canvas_color()
	sync_locale()
	sync_max_fps()
	sync_theme()


# Global effects from settings. Some of them should also be used on launch.

func sync_canvas_color() -> void:
	RenderingServer.set_default_clear_color(savedata.canvas_color)

func sync_locale() -> void:
	if not savedata.language in TranslationServer.get_loaded_locales():
		savedata.language = "en"
	else:
		TranslationServer.set_locale(savedata.language)

func sync_vsync() -> void:
	DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if savedata.vsync else DisplayServer.VSYNC_DISABLED)

func sync_max_fps() -> void:
	Engine.max_fps = savedata.max_fps

func sync_theme() -> void:
	ThemeUtils.generate_and_apply_theme()
	theme_changed.emit()
