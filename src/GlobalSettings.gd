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
		"use_native_file_dialog": true,
		"handle_size": 1.0,
		"ui_scale": 1.0,
		"auto_ui_scale": true,
	},
}

# No way to fetch defaults otherwise.
var default_input_events := {}  # Dictionary{String: Array[InputEvent]}

const configurable_keybinds = {
	"file": ["import", "export", "save", "optimize", "copy_svg_text", "clear_svg",
			"clear_file_path", "reset_svg"],
	"edit": ["undo", "redo", "select_all", "duplicate", "move_up", "move_down", "delete"],
	"view": ["zoom_in", "zoom_out", "zoom_reset", "view_show_grid", "view_show_handles",
			"view_rasterized_svg"]}

const unconfigurable_keybinds = [
	"move_relative", "move_absolute", "line_relative", "line_absolute",
	"horizontal_line_relative", "horizontal_line_absolute", "vertical_line_relative",
	"vertical_line_absolute", "close_path_relative", "close_path_absolute",
	"elliptical_arc_relative", "elliptical_arc_absolute", "quadratic_bezier_relative",
	"quadratic_bezier_absolute", "shorthand_quadratic_bezier_relative",
	"shorthand_quadratic_bezier_absolute", "cubic_bezier_relative",
	"cubic_bezier_absolute", "shorthand_cubic_bezier_relative",
	"shorthand_cubic_bezier_absolute"]


var language: String:
	set(new_value):
		language = new_value
		TranslationServer.set_locale(new_value)
		save_setting("localization", "language")

var palettes: Array[ColorPalette] = []


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

# Other
var invert_zoom := false
var wrap_mouse := false
var use_ctrl_for_zoom := true
var use_native_file_dialog := true
var handle_size := 1.0
var ui_scale := 1.0:
	set(new_value):
		ui_scale = new_value
		update_ui_scale()
var auto_ui_scale := true:
	set(new_value):
		auto_ui_scale = new_value
		update_ui_scale()

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
	update_ui_scale()
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
				for category in configurable_keybinds:
					for action in GlobalSettings.configurable_keybinds[category]:
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
	for category in configurable_keybinds:
		for action in GlobalSettings.configurable_keybinds[category]:
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


func update_ui_scale() -> void:
	await get_tree().process_frame
	var window := get_window()
	
	var usable_screen_size := Vector2(
		DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()).size
		# Subtract window decoration size.
		 - (window.get_size_with_decorations() - window.size)
		)
	
	# How much can window content size be multiplied by before it extends over the usable screen size.
	var diff :=  usable_screen_size / window.get_contents_minimum_size()
	var max_scale := floorf(minf(diff.x, diff.y)*4.0)/4.0
	
	var desired_scale: float = ui_scale * _calculate_auto_scale()
	
	if not desired_scale > max_scale:
		window.min_size = window.get_contents_minimum_size() * desired_scale
		window.content_scale_factor = desired_scale
	else:
		window.min_size = usable_screen_size
		window.content_scale_factor = max_scale


func _calculate_auto_scale() -> float:
	if not auto_ui_scale:
		return 1.0
	
	# Credit: Godots (MIT, by MakovWait and contributors)
	
	var screen := DisplayServer.window_get_current_screen()
	if DisplayServer.screen_get_size(screen) == Vector2i():
		return 1.0
	
	# Use the smallest dimension to use a correct display scale on portrait displays.
	var smallest_dimension := mini(
		DisplayServer.screen_get_size(screen).x,
		DisplayServer.screen_get_size(screen).y
	)
	
	var dpi :=  DisplayServer.screen_get_dpi(screen)
	if dpi != 72:
		if dpi < 72:
			return 0.75
		elif dpi <= 96:
			return 1.0
		elif dpi <=160:
			return 1.25
		elif dpi <= 240:
			return 1.5
		elif dpi <= 480:
			return 1.75
		elif dpi > 480:
			return 2.0
	elif smallest_dimension >= 1700:
		# Likely a hiDPI display, but we aren't certain due to the returned DPI.
		# Use an intermediate scale to handle this situation.
		return 1.5
	return 1.0
