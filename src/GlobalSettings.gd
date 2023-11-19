## This singleton handles save data and settings.
extends Node

var save_data := SaveData.new()
const save_path = "user://save.tres"

var _palettes := SavedColorPalettes.new()
const palettes_save_path = "user://palettes.tres"

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

var invert_zoom := false:
	set(new_value):
		invert_zoom = new_value
		save_setting("input", "invert_zoom", invert_zoom)

func save_setting(section: String, setting: String, saved_value: Variant) -> void:
	config.set_value(section, setting, saved_value)
	config.save(config_path)

func modify_save_data(property: StringName, new_value: Variant) -> void:
	save_data.set(property, new_value)
	ResourceSaver.save(save_data, save_path)

func save_user_data() -> void:
	ResourceSaver.save(save_data, save_path)
	ResourceSaver.save(_palettes, palettes_save_path)

func load_user_data() -> void:
	if FileAccess.file_exists(save_path):
		save_data = ResourceLoader.load(save_path)
	
	if FileAccess.file_exists(palettes_save_path):
		_palettes = ResourceLoader.load(palettes_save_path)
	else:
		var default_palette_pure := ColorPalette.new("Pure", [
				NamedColor.new("fff", "White"),
				NamedColor.new("000", "Black"),
				NamedColor.new("f00", "Red"),
				NamedColor.new("0f0", "Green"),
				NamedColor.new("00f", "Blue"),
				NamedColor.new("ff0", "Yellow"),
				NamedColor.new("f0f", "Magenta"),
				NamedColor.new("0ff", "Cyan"),
		])
		get_palettes().append(default_palette_pure)
		ResourceSaver.save(_palettes, palettes_save_path)

func _exit_tree() -> void:
	save_data.window_mode = DisplayServer.window_get_mode()
	save_data.svg = SVG.string
	save_user_data()

func _enter_tree() -> void:
	load_settings()
	load_user_data()
	DisplayServer.window_set_mode(save_data.window_mode)
	get_window().wrap_controls = true  # Prevents the main window from getting too small.


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

func get_palettes() -> Array[ColorPalette]:
	return _palettes.palettes
