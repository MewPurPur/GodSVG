# This singleton handles session data and settings.
extends Node

var _save_queued := false

signal file_path_changed
signal highlighting_colors_changed
signal snap_changed
signal language_changed
signal ui_scale_changed
signal theme_changed
signal shortcuts_changed
signal basic_colors_changed
signal handle_visuals_changed

var savedata := SaveData.new()
const savedata_path = "user://savedata.tres"

var svg_text := "":
	set(new_value):
		if new_value != svg_text:
			svg_text = new_value
			FileAccess.open(svg_path, FileAccess.WRITE).store_string(svg_text)

const svg_path = "user://save.svg"

var shortcut_validities := {}
var palette_validities := {}


func get_signal(setting: String) -> Signal:
	if not setting in triggers:
		return Signal()
	var triggers_arr: Array = triggers[setting]
	return triggers_arr[0] if triggers_arr.size() > 0 else Signal()

func get_modification_callback(setting: String) -> Callable:
	if not setting in triggers:
		return Callable()
	var triggers_arr: Array = triggers[setting]
	return triggers_arr[1] if triggers_arr.size() > 1 else Callable()

var triggers = {
	"language": [language_changed, change_locale],
	"highlighting_symbol_color": [highlighting_colors_changed],
	"highlighting_element_color": [highlighting_colors_changed],
	"highlighting_attribute_color": [highlighting_colors_changed],
	"highlighting_string_color": [highlighting_colors_changed],
	"highlighting_comment_color": [highlighting_colors_changed],
	"highlighting_text_color": [highlighting_colors_changed],
	"highlighting_cdata_color": [highlighting_colors_changed],
	"highlighting_error_color": [highlighting_colors_changed],
	"handle_inner_color": [handle_visuals_changed],
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


func queue_save() -> void:
	_save_queued = true
	_save.call_deferred()

func _save() -> void:
	if _save_queued:
		_save_queued = false
		ResourceSaver.save(savedata, savedata_path)


var default_shortcuts := {}

func _enter_tree() -> void:
	for action in InputMap.get_actions():
		if action in ShortcutUtils.get_all_shortcuts():
			default_shortcuts[action] = InputMap.action_get_events(action)
	load_config()
	load_svg_text()
	ThemeUtils.generate_and_apply_theme()
	# Connect to settings that have a global effect.
	file_path_changed.connect(update_window_title)
	update_window_title()
	shortcuts_changed.connect(update_shortcut_validities)


func load_config() -> void:
	if not FileAccess.file_exists(savedata_path):
		reset_settings()
		return
	
	savedata = ResourceLoader.load(savedata_path)
	if not is_instance_valid(savedata):
		reset_settings()
		return
	
	update_window_title()
	change_background_color()
	change_locale()

func reset_settings() -> void:
	savedata = SaveData.new()
	savedata.reset_to_default()
	queue_save()


func load_svg_text() -> void:
	var fa := FileAccess.open(svg_path, FileAccess.READ)
	if fa != null:
		svg_text = fa.get_as_text()


func generate_highlighter() -> SVGHighlighter:
	var new_highlighter := SVGHighlighter.new()
	new_highlighter.symbol_color = Configs.savedata.highlighting_symbol_color
	new_highlighter.element_color = Configs.savedata.highlighting_element_color
	new_highlighter.attribute_color = Configs.savedata.highlighting_attribute_color
	new_highlighter.string_color = Configs.savedata.highlighting_string_color
	new_highlighter.comment_color = Configs.savedata.highlighting_comment_color
	new_highlighter.text_color = Configs.savedata.highlighting_text_color
	new_highlighter.cdata_color = Configs.savedata.highlighting_cdata_color
	new_highlighter.error_color = Configs.savedata.highlighting_error_color
	return new_highlighter


func update_shortcut_validities() -> void:
	shortcut_validities.clear()
	for action in ShortcutUtils.get_all_shortcuts():
		for shortcut: InputEventKey in InputMap.action_get_events(action):
			var shortcut_id := shortcut.get_keycode_with_modifiers()
			# If the key already exists, set validity to false, otherwise set to true.
			shortcut_validities[shortcut_id] = not shortcut_id in shortcut_validities

func is_shortcut_valid(shortcut: InputEvent) -> bool:
	var shortcut_id = shortcut.get_keycode_with_modifiers()
	if not shortcut_id in shortcut_validities:
		return true
	return shortcut_validities[shortcut_id]

func get_actions_with_shortcut(shortcut: InputEvent) -> PackedStringArray:
	var shortcut_id = shortcut.get_keycode_with_modifiers()
	if not shortcut_id in shortcut_validities:
		return PackedStringArray()
	elif shortcut_validities[shortcut_id]:
		return PackedStringArray()
	
	var actions_with_shortcut := PackedStringArray()
	for action in ShortcutUtils.get_all_shortcuts():
		for action_shortcut: InputEventKey in InputMap.action_get_events(action):
			if action_shortcut.get_keycode_with_modifiers() == shortcut_id:
				actions_with_shortcut.append(action)
				break
	return actions_with_shortcut


# Global effects from settings. Some of them should also be used on launch.

func update_window_title() -> void:
	if savedata.use_filename_for_window_title and !savedata.current_file_path.is_empty():
		get_window().title = savedata.current_file_path.get_file() + " - GodSVG"
	else:
		get_window().title = "GodSVG"

func change_background_color() -> void:
	RenderingServer.set_default_clear_color(savedata.background_color)

func change_locale() -> void:
	TranslationServer.set_locale(savedata.language)
