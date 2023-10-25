extends Node

const save_path = "user://save.tres"
var save_data := SaveData.new()

const config_path = "user://config.tres"
var config := ConfigFile.new()

# Don't have the language setting here, so it's not reset.
const default_config = {
	"session": {
		"save_svg": true,
		"save_window_mode": true,
	},
	"input": {
		"invert_zoom": false,
	},
}

var language: StringName:
	set(new_value):
		language = new_value
		TranslationServer.set_locale(new_value)
		save_setting("text", "language", language)

var save_window_mode := false:
	set(new_value):
		save_window_mode = new_value
		save_setting("session", "save_window_mode", save_window_mode)

var save_svg := false:
	set(new_value):
		save_svg = new_value
		save_setting("session", "save_svg", save_svg)
var invert_zoom := false:
	set(new_value):
		invert_zoom = new_value
		save_setting("input", "invert_zoom", invert_zoom)

func save_setting(section: String, setting: String, saved_value: Variant) -> void:
	config.set_value(section, setting, saved_value)
	config.save(config_path)

func save_user_data() -> void:
	ResourceSaver.save(save_data, save_path)

func load_user_data() -> void:
	if FileAccess.file_exists(save_path):
		save_data = ResourceLoader.load(save_path)

func _exit_tree() -> void:
	save_data.window_mode = DisplayServer.window_get_mode()
	save_data.svg = SVG.string
	save_user_data()

func _enter_tree() -> void:
	load_settings()
	load_user_data()
	if save_window_mode:
		DisplayServer.window_set_mode(save_data.window_mode)


func load_settings() -> void:
	var error := config.load(config_path)
	if error:
		reset_settings()
		language = &"en"
	else:
		for section in config.get_sections():
			for setting in config.get_section_keys(section):
				set(setting, config.get_value(section, setting))

func reset_settings() -> void:
	for section in default_config.keys():
		for setting in default_config[section].keys():
			set(setting, default_config[section][setting])
