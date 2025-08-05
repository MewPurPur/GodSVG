## An autoload that manages the savefile. Stores signals relating to changes to settings.
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

const _SAVEDATA_PATH = "user://savedata.tres"

## Main point of access to the savefile data. This includes user settings and session data.
var savedata: SaveData:
	set(new_value):
		if savedata != new_value and is_instance_valid(new_value):
			savedata = new_value
			savedata.validate()
			savedata.changed_deferred.connect(save)

## Helper for updating the savefile.
func save() -> void:
	ResourceSaver.save(savedata, _SAVEDATA_PATH)


## Default shortcuts to be able to reset a single action to its defaults.
var default_shortcuts: Dictionary[String, Array] = {}

func _enter_tree() -> void:
	# Fill up the default shortcuts dictionary before the shortcuts are loaded.
	for action in ShortcutUtils.get_all_actions():
		if InputMap.has_action(action):
			default_shortcuts[action] = InputMap.action_get_events(action)
	_load_config()


## Sets savedata and syncs various things. Resets the savedata 
func _load_config() -> void:
	if not FileAccess.file_exists(_SAVEDATA_PATH):
		_reset_config()
		return
	
	savedata = ResourceLoader.load(_SAVEDATA_PATH)
	if not is_instance_valid(savedata):
		_reset_config()
		return
	
	post_load()

# Resets settings to their defaults.
func _reset_config() -> void:
	savedata = SaveData.new()
	savedata.reset_to_default()
	savedata.language = "en"
	savedata.set_shortcut_panel_slots({ 0: "ui_undo", 1: "ui_redo" })
	savedata.set_palettes([Palette.new("Pure", Palette.Preset.PURE)])
	save()
	post_load()

# TODO I'm not sure why I made it so syncing within the SaveData only starts when it's fully initialized.
## Syncs various settings with their savedata value.
func post_load() -> void:
	savedata.get_active_tab().activate()
	sync_canvas_color()
	sync_locale()
	sync_max_fps()
	sync_keep_screen_on()
	sync_theme()


## Syncs the canvas color to the value in the savedata.
func sync_canvas_color() -> void:
	RenderingServer.set_default_clear_color(savedata.canvas_color)

## Syncs the locale to the value in the savedata.
func sync_locale() -> void:
	if not savedata.language in TranslationServer.get_loaded_locales():
		savedata.language = "en"
	else:
		TranslationServer.set_locale(savedata.language)

## Syncs the VSync to the value in the savedata.
func sync_vsync() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if savedata.vsync else DisplayServer.VSYNC_DISABLED)

## Syncs the engine max FPS to the value in the savedata.
func sync_max_fps() -> void:
	Engine.max_fps = savedata.max_fps

## Syncs the display server's "Keep screen on" behavior to the value in the savedata.
func sync_keep_screen_on() -> void:
	DisplayServer.screen_set_keep_on(savedata.keep_screen_on)

## Syncs the app theme based on the configurations in the savedata.
func sync_theme() -> void:
	ThemeUtils.generate_and_apply_theme()
	theme_changed.emit()
