# This singleton handles session data and settings.
extends Node

const GoodColorPicker = preload("res://src/ui_widgets/good_color_picker.gd")

enum ShorthandTags {ALWAYS, ALL_EXCEPT_CONTAINERS, NEVER}
enum NamedColorUse {ALWAYS, WHEN_SHORTER_OR_EQUAL, WHEN_SHORTER, NEVER}
enum PrimaryColorSyntax {THREE_OR_SIX_DIGIT_HEX, SIX_DIGIT_HEX, RGB}

signal file_path_changed
signal snapping_changed
signal language_changed
signal ui_scale_changed
signal theme_changed
signal shortcuts_changed
signal number_precision_changed
signal attribute_formatting_changed
signal highlight_colors_changed
signal basic_colors_changed
signal handle_visuals_changed


var config := ConfigFile.new()
const config_path = "user://config.cfg"

var palettes: Array[ColorPalette] = []
const palettes_path = "user://palettes.xml"

var svg_text := "":
	set(new_value):
		if new_value != svg_text:
			svg_text = new_value
			FileAccess.open(svg_path, FileAccess.WRITE).store_string(svg_text)
const svg_path = "user://save.svg"

const reference_image_path = "user://reference.png"

# TODO investigate why this can't be const. 
var enum_text = {
	"xml_shorthand_tags": {
		ShorthandTags.ALWAYS: TranslationServer.translate("Always"),
		ShorthandTags.ALL_EXCEPT_CONTAINERS: TranslationServer.translate("All except containers"),
		ShorthandTags.NEVER: TranslationServer.translate("Never"),
	},
	"color_use_named_colors": {
		NamedColorUse.ALWAYS: TranslationServer.translate("Always"),
		NamedColorUse.WHEN_SHORTER_OR_EQUAL: TranslationServer.translate("When shorter or equal"),
		NamedColorUse.WHEN_SHORTER: TranslationServer.translate("When shorter"),
		NamedColorUse.NEVER: TranslationServer.translate("Never"),
	},
	"color_primary_syntax": {
		PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX: TranslationServer.translate("3- or 6-digit hex"),
		PrimaryColorSyntax.SIX_DIGIT_HEX: TranslationServer.translate("6-digit hex"),
		PrimaryColorSyntax.RGB: "RGB",
	},
}

func get_enum_texts(setting: String) -> Array[String]:
	var values: Array[String] = []
	var enum_dict: Dictionary = enum_text[setting]
	for key in enum_dict:
		values.append(enum_dict[key])
	return values

func get_enum_text(setting: String) -> String:
	return enum_text[setting][get(setting)]

func get_default(section: String, setting: String) -> Variant:
	return defaults[section][setting][0]

func get_signal(section: String, setting: String) -> Signal:
	return defaults[section][setting][1]

var defaults = {
	"localization": {
		"language": ["en", Signal()],
	},
	"session": {
		"snap": [-0.5, snapping_changed],
		"color_picker_slider_mode": [GoodColorPicker.SliderMode.RGB, Signal()],
		"path_command_relative": [false, Signal()],
		"last_used_dir": ["", Signal()],
		"file_dialog_show_hidden": [false, Signal()],
		"current_file_path": ["", file_path_changed],
	},
	"formatting": {
		"general_number_precision": [3, number_precision_changed],
		"general_angle_precision": [1, number_precision_changed],
		"xml_add_trailing_newline": [false, attribute_formatting_changed],
		"xml_shorthand_tags": [ShorthandTags.ALL_EXCEPT_CONTAINERS, attribute_formatting_changed],
		"xml_shorthand_tags_space_out_slash": [false, attribute_formatting_changed],
		"xml_pretty_formatting": [false, attribute_formatting_changed],
		"xml_indentation_use_spaces": [false, attribute_formatting_changed],
		"xml_indentation_spaces": [2, attribute_formatting_changed],
		"number_remove_leading_zero": [true, attribute_formatting_changed],
		"number_use_exponential_when_shorter": [true, attribute_formatting_changed],
		"color_autoformat_raw_text": [false, attribute_formatting_changed],
		"color_use_named_colors": [NamedColorUse.WHEN_SHORTER, attribute_formatting_changed],
		"color_primary_syntax": [PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX, attribute_formatting_changed],
		"color_capital_hex": [false, attribute_formatting_changed],
		"pathdata_autoformat_raw_text": [true, attribute_formatting_changed],
		"pathdata_compress_numbers": [true, attribute_formatting_changed],
		"pathdata_minimize_spacing": [true, attribute_formatting_changed],
		"pathdata_remove_spacing_after_flags": [false, attribute_formatting_changed],
		"pathdata_remove_consecutive_commands": [true, attribute_formatting_changed],
		"transform_list_autoformat_raw_text": [true, attribute_formatting_changed],
		"transform_list_compress_numbers": [true, attribute_formatting_changed],
		"transform_list_minimize_spacing": [true, attribute_formatting_changed],
		"transform_list_remove_unnecessary_params": [true, attribute_formatting_changed],
	},
	"theming": {
		"highlighting_symbol_color": [Color("abc9ff"), highlight_colors_changed],
		"highlighting_element_color": [Color("ff8ccc"), highlight_colors_changed],
		"highlighting_attribute_color": [Color("bce0ff"), highlight_colors_changed],
		"highlighting_string_color": [Color("a1ffe0"), highlight_colors_changed],
		"highlighting_comment_color": [Color("cdcfd280"), highlight_colors_changed],
		"highlighting_text_color": [Color("cdcfeaac"), highlight_colors_changed],
		"highlighting_cdata_color": [Color("ffeda1ac"), highlight_colors_changed],
		"highlighting_error_color": [Color("ff866b"), highlight_colors_changed],
		"handle_inside_color": [Color("fff"), handle_visuals_changed],
		"handle_color": [Color("#111"), handle_visuals_changed],
		"handle_hovered_color": [Color("#aaa"), handle_visuals_changed],
		"handle_selected_color": [Color("#46f"), handle_visuals_changed],
		"handle_hovered_selected_color": [Color("#f44"), handle_visuals_changed],
		"background_color": [Color("1f2233"), Signal()],
		"basic_color_valid": [Color("9f9"), basic_colors_changed],
		"basic_color_error": [Color("f99"), basic_colors_changed],
		"basic_color_warning": [Color("ee5"), basic_colors_changed],
	},
	"other": {
		"invert_zoom": [false, Signal()],
		"wrap_mouse": [false, Signal()],
		"use_ctrl_for_zoom": [true, Signal()],
		"use_native_file_dialog": [true, Signal()],
		"use_filename_for_window_title": [true, Signal()],
		"handle_size": [1.0, handle_visuals_changed],
		"ui_scale": [1.0, ui_scale_changed],
		"auto_ui_scale": [true, ui_scale_changed],
	},
}

# No way to fetch defaults otherwise.
var default_input_events := {}  # Dictionary{String: Array[InputEvent]}

# Stores whether the keybinds should be modifiable.
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
		"find": true,
	},
	"view": {
		"zoom_in": true,
		"zoom_out": true,
		"zoom_reset": true,
		"debug": false,
		"view_show_grid": true,
		"view_show_handles": true,
		"view_rasterized_svg": true,
		"load_reference": true,
		"view_show_reference": true,
		"view_overlay_reference": true,
	},
	"tool": {
		"move_relative": false,
		"move_absolute": false,
		"line_relative": false,
		"line_absolute": false,
		"horizontal_line_relative": false,
		"horizontal_line_absolute": false,
		"vertical_line_relative": false,
		"vertical_line_absolute": false,
		"close_path_relative": false,
		"close_path_absolute": false,
		"elliptical_arc_relative": false,
		"elliptical_arc_absolute": false,
		"quadratic_bezier_relative": false,
		"quadratic_bezier_absolute": false,
		"shorthand_quadratic_bezier_relative": false,
		"shorthand_quadratic_bezier_absolute": false,
		"cubic_bezier_relative": false,
		"cubic_bezier_absolute": false,
		"shorthand_cubic_bezier_relative": false,
		"shorthand_cubic_bezier_absolute": false,
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

var language := "":
	set(new_value):
		if new_value != language:
			language = new_value
			TranslationServer.set_locale(new_value)
			language_changed.emit()

var snap := -0.5  # Negative when disabled.
var color_picker_slider_mode := GoodColorPicker.SliderMode.RGB
var path_command_relative := false
var last_used_dir := ""
var file_dialog_show_hidden := false
var current_file_path := ""

# Formatting
var general_number_precision := 3
var general_angle_precision := 1
var xml_add_trailing_newline := false
var xml_shorthand_tags := ShorthandTags.ALL_EXCEPT_CONTAINERS
var xml_shorthand_tags_space_out_slash := false
var xml_pretty_formatting := false
var xml_indentation_use_spaces := false
var xml_indentation_spaces := 2
var number_remove_leading_zero := true
var number_use_exponential_when_shorter := true
var color_autoformat_raw_text := false
var color_use_named_colors := NamedColorUse.WHEN_SHORTER
var color_primary_syntax := PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX
var color_capital_hex := false
var pathdata_autoformat_raw_text := true
var pathdata_compress_numbers := true
var pathdata_minimize_spacing := true
var pathdata_remove_spacing_after_flags := false
var pathdata_remove_consecutive_commands := true
var transform_list_autoformat_raw_text := true
var transform_list_compress_numbers := true
var transform_list_minimize_spacing := true
var transform_list_remove_unnecessary_params := true

# Theming
var highlighting_symbol_color := Color("abc9ff")
var highlighting_element_color := Color("ff8ccc")
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
var background_color := Color(0.12, 0.132, 0.2, 1):
	set(new_value):
		if new_value != background_color:
			background_color = new_value
			RenderingServer.set_default_clear_color(new_value)
var basic_color_valid := Color("9f9")
var basic_color_error := Color("f99")
var basic_color_warning := Color("ee5")

# Other
var invert_zoom := false
var wrap_mouse := false
var use_ctrl_for_zoom := true
var use_native_file_dialog := true
var use_filename_for_window_title := true:
	set(new_value):
		if new_value != use_filename_for_window_title:
			use_filename_for_window_title = new_value
			update_window_title()
var handle_size := 1.0
var ui_scale := 1.0
var auto_ui_scale := true


func reset_setting(section: String, setting: String) -> void:
	modify_setting(section, setting, get_default(section, setting))

func modify_setting(section: String, setting: String, new_value: Variant) -> void:
	if get(setting) == new_value:
		return
	set(setting, new_value)
	save_setting(section, setting)
	var related_signal := get_signal(section, setting)
	if not related_signal.is_null():
		related_signal.emit()


func modify_keybind(action: String, new_events: Array[InputEvent]) -> void:
	InputMap.action_erase_events(action)
	for event in new_events:
		InputMap.action_add_event(action, event)
	save_keybind(action)
	shortcuts_changed.emit()

func reset_keybinds() -> void:
	InputMap.load_from_project_settings()
	for category in keybinds_dict:
		var category_dict: Dictionary = keybinds_dict[category]
		for action in category_dict:
			# Only reset the configurable ones.
			if category_dict[action]:
				save_keybind(action)
	shortcuts_changed.emit()


func save_setting(section: String, setting: String) -> void:
	config.set_value(section, setting, get(setting))
	config.save(config_path)

func save_palettes() -> void:
	var palette_strings := PackedStringArray()
	for palette in palettes:
		palette_strings.append(palette.to_text())
	var palettes_xml := "\n".join(palette_strings)
	FileAccess.open(palettes_path, FileAccess.WRITE).store_string(palettes_xml)

func save_keybind(action: String) -> void:
	config.set_value("keybinds", action, InputMap.action_get_events(action))
	config.save(config_path)


func _enter_tree() -> void:
	for action in InputMap.get_actions():
		default_input_events[action] = InputMap.action_get_events(action)
	load_config()
	load_palettes()
	load_svg_text()
	ThemeGenerator.generate_and_apply_theme()
	# Connect to settings that have a global effect.
	number_precision_changed.connect(_on_number_precision_changed)
	file_path_changed.connect(update_window_title)
	update_window_title()


func load_config() -> void:
	var error := config.load(config_path)
	if error:
		# File wasn't found or maybe something broke, setup defaults again.
		reset_settings()
		reset_keybinds()
		return
	
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

func load_palettes() -> void:
	var fa := FileAccess.open(palettes_path, FileAccess.READ)
	if fa == null:
		reset_palettes()
		return
	palettes = ColorPalette.text_to_palettes(fa.get_as_text())

func load_svg_text() -> void:
	var fa := FileAccess.open(svg_path, FileAccess.READ)
	if fa != null:
		svg_text = fa.get_as_text()


func reset_settings() -> void:
	for section in defaults.keys():
		for setting in defaults[section].keys():
			set(setting, get_default(section, setting))
			save_setting(section, setting)

func reset_palettes() -> void:
	palettes = [ColorPalette.new("Pure",
			PackedStringArray(["#fff", "#000", "#f00", "#0f0", "#00f", "#ff0", "#f0f", "#0ff"]),
			PackedStringArray(["White", "Black", "Red", "Green", "Blue", "Yellow", "Magenta", "Cyan"]))]
	save_palettes()

# Just some helpers.
func get_validity_color(error_condition: bool, warning_condition := false) -> Color:
	return basic_color_error if error_condition else\
			basic_color_warning if warning_condition else basic_color_valid

func get_quanta() -> float:
	return 0.1 ** general_number_precision


# Global effects from settings.

func _on_number_precision_changed() -> void:
	# Update snap to fit the new precision.
	var snapping_on := snap > 0
	var quanta := get_quanta()
	var new_snap := snappedf(snap, quanta)
	if absf(new_snap) < quanta:
		new_snap = quanta
		if not snapping_on:
			new_snap *= -1
	modify_setting("session", "snap", new_snap)

func update_window_title() -> void:
	if use_filename_for_window_title and not current_file_path.is_empty():
		get_window().title = current_file_path.get_file() + " - GodSVG"
	else:
		get_window().title = "GodSVG"
