## This singleton handles save data and settings.
extends Node

# Session data
var save_data := SaveData.new()
const save_path = "user://save.tres"

# Settings
var config := ConfigFile.new()
const config_path = "user://config.tres"

# Don't have the language setting here, so it's not reset.
const default_config = {
	"autoformat": {
		"general_number_precision": 3,
		"general_angle_precision": 1,
		"xml_add_trailing_newline": false,
		"xml_shorthand_tags": true,
		"number_enable_autoformatting": false,
		"number_remove_zero_padding": false,
		"number_remove_leading_zero": true,
		"number_remove_plus_sign": false,
		"color_enable_autoformatting": false,
		"color_convert_rgb_to_hex": false,
		"color_convert_named_to_hex": true,
		"color_use_shorthand_hex_code": true,
		"color_use_short_named_colors": false,
		"path_compress_numbers": true,
		"path_minimize_spacing": true,
		"path_remove_spacing_after_flags": false,
		"path_remove_consecutive_commands": true,
		"transform_compress_numbers": true,
		"transform_minimize_spacing": true,
		"transform_remove_unnecessary_params": true,
	},
	"theming": {
		"highlighting_symbol_color": Color("abc9ff"),
		"highlighting_tag_color": Color("ff8ccc"),
		"highlighting_attribute_color": Color("bce0ff"),
		"highlighting_string_color": Color("a1ffe0"),
		"highlighting_comment_color": Color("cdcfd280"),
		"highlighting_text_color": Color("cdcfeaac"),
		"highlighting_cdata_color": Color("ffeda1ac"),
		"highlighting_error_color": Color("ff866b"),
		"handle_inside_color": Color("fff"),
		"handle_color": Color("#111"),
		"handle_hovered_color": Color("#aaa"),
		"handle_selected_color": Color("#46f"),
		"handle_hovered_selected_color": Color("#f44"),
		"default_value_opacity": 0.7,
		"basic_color_valid": Color("9f9"),
		"basic_color_error": Color("f99"),
		"basic_color_warning": Color("ff9"),
	},
	"other": {
		"invert_zoom": false,
		"wrap_mouse": false,
		"use_ctrl_for_zoom": true,
	},
}

# No way to fetch defaults otherwise.
var default_input_events := {}  # Dictionary{String: Array[InputEvent]}
const configurable_keybinds = ["import", "export", "save", "move_up", "move_down",
		"undo", "redo", "duplicate", "select_all", "delete", "zoom_in", "zoom_out",
		"zoom_reset"]

var language: String:
	set(new_value):
		language = new_value
		TranslationServer.set_locale(new_value)
		save_setting("localization", "language")

var palettes: Array[ColorPalette] = []

# Input
var invert_zoom := false
var wrap_mouse := false
var use_ctrl_for_zoom := true

# Autoformat
var general_number_precision := 3
var general_angle_precision := 1
var xml_add_trailing_newline := false
var xml_shorthand_tags := true
var number_enable_autoformatting := false
var number_remove_zero_padding := true
var number_remove_leading_zero := false
var color_enable_autoformatting := false
var color_convert_rgb_to_hex := false
var color_convert_named_to_hex := true
var color_use_shorthand_hex_code := true
var color_use_short_named_colors := false
var path_compress_numbers := true
var path_minimize_spacing := true
var path_remove_spacing_after_flags := false
var path_remove_consecutive_commands := true
var transform_compress_numbers := true
var transform_minimize_spacing := true
var transform_remove_unnecessary_params := true

# Theming
var highlighting_symbol_color := Color("abc9ff")
var highlighting_tag_color := Color("ff8ccc")
var highlighting_attribute_color := Color("bce0ff")
var highlighting_string_color := Color("a1ffe0")
var highlighting_comment_color := Color("cdcfd280")
var highlighting_text_color := Color("cdcfeaac")
var highlighting_cdata_color := Color("ffeda1ac")
var highlighting_error_color := Color("ff866b")
var handle_inside_color := Color("fff")
var handle_color := Color("#111")
var handle_hovered_color := Color("#aaa")
var handle_selected_color := Color("#46f")
var handle_hovered_selected_color := Color("#f44")
var default_value_opacity := 0.7
var basic_color_valid := Color("9f9")
var basic_color_error := Color("f99")
var basic_color_warning := Color("ff9")


func toggle_bool_setting(section: String, setting: String) -> void:
	set(setting, !get(setting))
	save_setting(section, setting)

func modify_setting(section: String, setting: String, new_value: Variant) -> void:
	set(setting, new_value)
	save_setting(section, setting)

func modify_keybind(action: String, new_events: Array[InputEvent]) -> void:
	InputMap.action_erase_events(action)
	for event in new_events:
		InputMap.action_add_event(action, event)
	save_keybind(action)

func save_setting(section: String, setting: String) -> void:
	config.set_value(section, setting, get(setting))
	config.save(config_path)

func save_palettes() -> void:
	config.set_value("palettes", "palettes", palettes)
	config.save(config_path)

func save_keybind(action: String) -> void:
	config.set_value("keybinds", action, InputMap.action_get_events(action))
	config.save(config_path)


func modify_save_data(property: String, new_value: Variant) -> void:
	save_data.set(property, new_value)
	ResourceSaver.save(save_data, save_path)

func load_user_data() -> void:
	if FileAccess.file_exists(save_path):
		save_data = ResourceLoader.load(save_path)

func _exit_tree() -> void:
	save_data.window_mode = DisplayServer.window_get_mode()
	ResourceSaver.save(save_data, save_path)

func _enter_tree() -> void:
	for action in InputMap.get_actions():
		default_input_events[action] = InputMap.action_get_events(action)
	load_settings()
	load_user_data()
	DisplayServer.window_set_mode(save_data.window_mode)
	get_window().wrap_controls = true  # Prevents the main window from getting too small.
	ThemeGenerator.generate_theme()


func load_settings() -> void:
	var error := config.load(config_path)
	if error:
		# File wasn't found or maybe something broke, setup defaults again.
		reset_settings()
		reset_palettes()
		reset_keybinds()
		language = "en"
	else:
		for section in config.get_sections():
			if section == "keybinds":
				for action in configurable_keybinds:
					if config.has_section_key("keybinds", action):
						modify_keybind(action, config.get_value("keybinds", action))
			else:
				for setting in config.get_section_keys(section):
					set(setting, config.get_value(section, setting))
					save_setting(section, setting)

func reset_settings() -> void:
	for section in default_config.keys():
		for setting in default_config[section].keys():
			set(setting, default_config[section][setting])
			save_setting(section, setting)

func reset_setting(section: String, setting: String) -> void:
	set(setting, default_config[section][setting])
	save_setting(section, setting)

func reset_keybinds() -> void:
	InputMap.load_from_project_settings()
	for action in configurable_keybinds:
		save_keybind(action)

func reset_palettes() -> void:
	palettes = [ColorPalette.new("Pure",
			["#fff", "#000", "#f00", "#0f0", "#00f", "#ff0", "#f0f", "#0ff"],
			["White", "Black", "Red", "Green", "Blue", "Yellow", "Magenta", "Cyan"])]
	save_palettes()

# Just a helper.
func get_validity_color(error_condition: bool, warning_condition := false) -> Color:
	return GlobalSettings.basic_color_error if error_condition else\
			GlobalSettings.basic_color_warning if warning_condition else\
			GlobalSettings.basic_color_valid
