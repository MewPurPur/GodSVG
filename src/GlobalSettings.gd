# This singleton handles session data and settings.
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
		"basic_color_valid": Color("9f9"),
		"basic_color_error": Color("f99"),
		"basic_color_warning": Color("ee5"),
		"focus_color": Color("66ccff"),
		"line_edit_focus_color": Color("3d6b99"),
		"common_panel_inner_color": Color("191926"),
		"common_panel_border_color": Color("414159"),
		"overlay_panel_inner_color": Color("060614"),
		"overlay_panel_border_color": Color("344166"),
		"common_selection_color": Color("668cff66")
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

const keybinds_dict = {
	"file": {
		"import": true,
		"export": true,
		"save": true,
		"optimize": true,
		"copy_svg_text": true,
		"clear_svg": true,
		"clear_file_path": true,
		"reset_svg": true,
	},
	"edit": {
		"undo": true,
		"redo": true,
		"select_all": true,
		"duplicate": true,
		"move_up": true,
		"move_down": true,
		"delete": true,
	},
	"view": {
		"zoom_in": true,
		"zoom_out": true,
		"zoom_reset": true,
		"debug": false,
		"view_show_grid": true,
		"view_show_handles": true,
		"view_rasterized_svg": true,
	},
	"tool": {
		"move_relative": true,
		"move_absolute": true,
		"line_relative": true,
		"line_absolute": true,
		"horizontal_line_relative": true,
		"horizontal_line_absolute": true,
		"vertical_line_relative": true,
		"vertical_line_absolute": true,
		"close_path_relative": true,
		"close_path_absolute": true,
		"elliptical_arc_relative": true,
		"elliptical_arc_absolute": true,
		"quadratic_bezier_relative": true,
		"quadratic_bezier_absolute": true,
		"shorthand_quadratic_bezier_relative": true,
		"shorthand_quadratic_bezier_absolute": true,
		"cubic_bezier_relative": true,
		"cubic_bezier_absolute": true,
		"shorthand_cubic_bezier_relative": true,
		"shorthand_cubic_bezier_absolute": true,
	},
	"help": {
		"quit": false,
		"open_settings": true,
		"about_info": true,
		"about_donate": true,
		"about_repo": true,
		"about_website": true,
		"check_updates": true,
	}
}


var language: String:
	set(new_value):
		language = new_value
		TranslationServer.set_locale(new_value)
		save_setting("localization", "language")

var palettes: Array[ColorPalette] = []


# Formatting
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
var basic_color_valid := Color("9f9")
var basic_color_error := Color("f99")
var basic_color_warning := Color("ee5")

# More theming
var focus_color = Color("66ccff")
var common_panel_inner_color = Color("191926")
var common_panel_border_color = Color("414159")
var common_caret_color = Color("ddeeffdd")
var common_selection_color = Color("668cff66")
var common_text_color = Color("ddeeff")
var common_subtle_text_color = Color("ffffff55")
var common_inner_color_disabled = Color("0e0e12")
var common_border_color_disabled = Color("1e1f24")
var common_separator_color = Color("414159", 0.6)

var common_button_inner_color_normal = Color("1c1e38")
var common_button_border_color_normal = Color("313859")
var common_button_inner_color_hover = Color("232840")
var common_button_border_color_hover = Color("43567a")
var common_button_inner_color_pressed = Color("3d5499")
var common_button_border_color_pressed = Color("608fbf")
var connected_button_inner_color_normal = Color("10101a")
var connected_button_border_color_normal = Color("272733")
var connected_button_inner_color_hover = Color("181826")
var connected_button_border_color_hover = Color("3a3a4d")
var connected_button_inner_color_pressed = Color("313559")
var connected_button_border_color_pressed = Color("54678c")

var icon_normal_color = Color("bfbfbf")
var context_icon_normal_color = Color("d9d9d9")
var icon_hover_color = Color("ffffff")
var icon_pressed_color = Color("bfdfff")
var icon_toggled_off_color = Color("808080")
var icon_toggled_on_color = Color("ddeeffdd")

var translucent_button_color_normal = Color("ddeeff11")
var translucent_button_color_hover = Color("ddeeff22")
var translucent_button_color_pressed = Color("ddeeff44")
var translucent_button_color_disabled = Color("05060755")
var flat_button_color_hover := Color("ddeeff11")
var flat_button_color_pressed := Color("ddeeff33")
var flat_button_color_disabled := Color("05060744")

var dark_panel_color := Color("11111a")
var overlay_panel_inner_color := Color("060614")
var overlay_panel_border_color := Color("344166")

var scrollbar_normal_color := Color("344166")
var scrollbar_hover_color := Color("465580")
var scrollbar_pressed_color := Color("608fbf")
var scrollbar_background_color := Color("0f0f1a99")

var line_edit_focus_color := Color("3d6b99")
var line_edit_background_color = Color("10101a")
var line_edit_normal_border_color = Color("272733")
var line_edit_hover_border_overlay_color = Color("ddeeff1b")
var mini_line_edit_normal_border_color = Color("4d4e66")

var tab_container_panel_inner_color = Color("171726")
var tab_container_panel_border_color = Color("2a2e4d")
var tabbar_background_color = Color("13131f80")
var hovered_tab_color = Color("1f2138")
var normal_tab_color = Color("17192e")
var selected_tab_color = Color("293052")
var selected_tab_border_color = Color("608fbf")

# Other
var invert_zoom := false
var wrap_mouse := false
var use_ctrl_for_zoom := true
var use_native_file_dialog := true
var handle_size := 1.0
var ui_scale := 1.0
var auto_ui_scale := true

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
	ResourceSaver.save(save_data, save_path)

func _enter_tree() -> void:
	for action in InputMap.get_actions():
		default_input_events[action] = InputMap.action_get_events(action)
	load_settings()
	load_user_data()
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
				for category in keybinds_dict:
					var category_dict: Dictionary = keybinds_dict[category]
					for action in category_dict:
						# Only save ones that are configurable.
						if category_dict[action]:
							if config.has_section_key("keybinds", action):
								modify_keybind(action, config.get_value("keybinds", action))
							else:
								save_keybind(action)
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
	for category in keybinds_dict:
		var category_dict: Dictionary = keybinds_dict[category]
		for action in category_dict:
			# Only reset the configurable ones.
			if category_dict[action]:
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
