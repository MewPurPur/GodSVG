# This singleton handles session data and settings.
extends Node

signal file_path_changed
signal highlighting_colors_changed
signal snap_changed
signal language_changed
signal ui_scale_changed
signal theme_changed
signal shortcuts_changed
signal basic_colors_changed
signal handle_visuals_changed

var DEFAULT_SAVEDATA := SaveData.new()
var savedata := SaveData.new()
const savedata_path = "user://savedata.tres"

var svg_text := "":
	set(new_value):
		if new_value != svg_text:
			svg_text = new_value
			FileAccess.open(svg_path, FileAccess.WRITE).store_string(svg_text)
const svg_path = "user://save.svg"

const reference_image_path = "user://reference.png"

var enum_text := {}

func get_enum_texts(setting: String) -> Array[String]:
	var values: Array[String] = []
	var enum_dict: Dictionary = enum_text[setting]
	for key in enum_dict:
		values.append(enum_dict[key])
	return values

func get_enum_text(setting: String) -> String:
	return enum_text[setting][get(setting)]


func get_default(setting: String) -> Variant:
	return DEFAULT_SAVEDATA.get(setting)

func get_signal(setting: String) -> Signal:
	if not setting in triggers:
		return Signal()
	var triggers_arr: Array = triggers[setting]
	return triggers_arr[0] if triggers_arr.size() > 0 else Signal()

func get_modification_method(setting: String) -> Callable:
	if not setting in triggers:
		return Callable()
	var triggers_arr: Array = triggers[setting]
	return triggers_arr[1] if triggers_arr.size() > 1 else Callable()

var triggers = {
	"language": [language_changed, change_locale],
	"editor_formatter": [Signal(), sync_elements],
	"highlighting_symbol_color": [highlighting_colors_changed],
	"highlighting_element_color": [highlighting_colors_changed],
	"highlighting_attribute_color": [highlighting_colors_changed],
	"highlighting_string_color": [highlighting_colors_changed],
	"highlighting_comment_color": [highlighting_colors_changed],
	"highlighting_text_color": [highlighting_colors_changed],
	"highlighting_cdata_color": [highlighting_colors_changed],
	"highlighting_error_color": [highlighting_colors_changed],
	"handle_inside_color": [handle_visuals_changed],
	"handle_color": [handle_visuals_changed],
	"handle_hovered_color": [handle_visuals_changed],
	"handle_selected_color": [handle_visuals_changed],
	"handle_hovered_selected_color": [handle_visuals_changed],
	"background_color": [Signal(), change_background_color],
	"basic_color_valid": [basic_colors_changed],
	"basic_color_error": [basic_colors_changed],
	"basic_color_warning": [basic_colors_changed],
	"use_filename_for_window_title": [Signal(), update_window_title],
	"handle_size": [handle_visuals_changed],
	"ui_scale": [ui_scale_changed],
	"auto_ui_scale": [ui_scale_changed],
	"snap": [snap_changed],
	"current_file_path": [file_path_changed],
}


func modify_setting(setting: String, new_value: Variant, omit_save := false) -> void:
	if savedata.get(setting) == new_value:
		return
	if omit_save:
		savedata.set(setting, new_value)
	else:
		save_setting(setting, new_value)
	var related_modification_method := get_modification_method(setting)
	if not related_modification_method.is_null():
		related_modification_method.call()
	var related_signal := get_signal(setting)
	if not related_signal.is_null():
		related_signal.emit()

func modify_keybind(action: String, new_events: Array[InputEvent]) -> void:
	InputMap.action_erase_events(action)
	for event in new_events:
		InputMap.action_add_event(action, event)
	save_keybind(action)
	shortcuts_changed.emit()


func save_keybind(action: String) -> void:
	savedata.keybinds[action] = InputMap.action_get_events(action)
	save()

func save_setting(setting: StringName, value: Variant) -> void:
	savedata.set(setting, value)
	save()

func save() -> void:
	ResourceSaver.save(savedata, savedata_path)


func _enter_tree() -> void:
	load_config()
	load_svg_text()
	ThemeGenerator.generate_and_apply_theme()
	# Connect to settings that have a global effect.
	file_path_changed.connect(update_window_title)
	update_window_title()


func load_config() -> void:
	if not FileAccess.file_exists(savedata_path):
		reset_settings()
	else:
		savedata = ResourceLoader.load(savedata_path)
		if not is_instance_valid(savedata) or not savedata is SaveData:
			reset_settings()
		else:
			update_window_title()
			change_background_color()
			change_locale()

func load_svg_text() -> void:
	var fa := FileAccess.open(svg_path, FileAccess.READ)
	if fa != null:
		svg_text = fa.get_as_text()


func reset_settings() -> void:
	savedata = SaveData.new()
	modify_setting("language", "en", true)
	
	InputMap.load_from_project_settings()
	for action in ShortcutUtils.get_all_keybinds():
		if ShortcutUtils.is_keybind_modifiable(action):
			save_keybind(action)
	shortcuts_changed.emit()
	
	# The array needs to be typed.
	var palettes_array: Array[ColorPalette] = [ColorPalette.new("Pure", PackedStringArray(
			["#fff", "#000", "#f00", "#0f0", "#00f", "#ff0", "#f0f", "#0ff"]), PackedStringArray(
			["White", "Black", "Red", "Green", "Blue", "Yellow", "Magenta", "Cyan"]))]
	modify_setting("palettes", palettes_array, true)
	
	var compact_formatter := Formatter.new("Compact")
	var pretty_formatter := Formatter.new("Pretty")
	pretty_formatter.xml_shorthand_tags = Formatter.ShorthandTags.ALL_EXCEPT_CONTAINERS
	pretty_formatter.xml_shorthand_tags_space_out_slash = true
	pretty_formatter.xml_pretty_formatting = true
	pretty_formatter.number_remove_leading_zero = false
	pretty_formatter.number_use_exponent_if_shorter = false
	pretty_formatter.color_use_named_colors = Formatter.NamedColorUse.ALWAYS
	pretty_formatter.color_primary_syntax = Formatter.PrimaryColorSyntax.THREE_OR_SIX_DIGIT_HEX
	pretty_formatter.color_capital_hex = false
	pretty_formatter.pathdata_remove_spacing_after_flags = false
	pretty_formatter.transform_list_compress_numbers = false
	pretty_formatter.transform_list_minimize_spacing = false
	pretty_formatter.transform_list_remove_unnecessary_params = false
	# The array needs to be typed.
	var formatters_array: Array[Formatter] = [pretty_formatter, compact_formatter]
	modify_setting("formatters", formatters_array, true)
	modify_setting("editor_formatter", pretty_formatter, true)
	modify_setting("export_formatter", compact_formatter, true)
	save()


# Just some helpers.
func get_validity_color(error_condition: bool, warning_condition := false) -> Color:
	return savedata.basic_color_error if error_condition else\
			savedata.basic_color_warning if warning_condition else savedata.basic_color_valid

func generate_highlighter() -> SVGHighlighter:
	var new_highlighter := SVGHighlighter.new()
	new_highlighter.symbol_color = GlobalSettings.savedata.highlighting_symbol_color
	new_highlighter.element_color = GlobalSettings.savedata.highlighting_element_color
	new_highlighter.attribute_color = GlobalSettings.savedata.highlighting_attribute_color
	new_highlighter.string_color = GlobalSettings.savedata.highlighting_string_color
	new_highlighter.comment_color = GlobalSettings.savedata.highlighting_comment_color
	new_highlighter.text_color = GlobalSettings.savedata.highlighting_text_color
	new_highlighter.cdata_color = GlobalSettings.savedata.highlighting_cdata_color
	new_highlighter.error_color = GlobalSettings.savedata.highlighting_error_color
	return new_highlighter


# Global effects from settings. Some of them should also be used on launch.

func update_window_title() -> void:
	if savedata.use_filename_for_window_title and !savedata.current_file_path.is_empty():
		get_window().title = savedata.current_file_path.get_file() + " - GodSVG"
	else:
		get_window().title = "GodSVG"

func change_background_color() -> void:
	RenderingServer.set_default_clear_color(savedata.background_color)

func sync_elements() -> void:
	SVG.sync_elements()

func change_locale() -> void:
	TranslationServer.set_locale(savedata.language)
