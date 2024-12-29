class_name SaveData extends Resource

const GoodColorPicker = preload("res://src/ui_widgets/good_color_picker.gd")

var _save_pending := false
var _svg_sync_pending := false

var _palette_validities := {}
var _shortcut_validities := {}

func get_setting_default(setting: String) -> Variant:
	match setting:
		"language": return "en"
		"_recent_dirs": return PackedStringArray()
		"_shortcuts": return {}
		"_palettes": return [ColorPalette.new("Pure", ColorPalette.Preset.PURE)]
		"editor_formatter": return Formatter.new(Formatter.Preset.PRETTY)
		"export_formatter": return Formatter.new(Formatter.Preset.COMPACT)
		
		"highlighting_symbol_color": return Color("abc9ff")
		"highlighting_element_color": return Color("ff8ccc")
		"highlighting_attribute_color": return Color("bce0ff")
		"highlighting_string_color": return Color("a1ffe0")
		"highlighting_comment_color": return Color("cdcfd280")
		"highlighting_text_color": return Color("cdcfeaac")
		"highlighting_cdata_color": return Color("ffeda1ac")
		"highlighting_error_color": return Color("ff866b")
		"handle_inner_color": return Color("fff")
		"handle_color": return Color("111")
		"handle_hovered_color": return Color("aaa")
		"handle_selected_color": return Color("46f")
		"handle_hovered_selected_color": return Color("f44")
		"background_color": return Color(0.12, 0.132, 0.2, 1)
		"basic_color_valid": return Color("9f9")
		"basic_color_error": return Color("f99")
		"basic_color_warning": return Color("ee5")
		
		"invert_zoom": return false
		"wrap_mouse": return false
		"use_ctrl_for_zoom": return true
		"use_native_file_dialog": return true
		"use_filename_for_window_title": return true
		"handle_size": return 1.0 if OS.get_name() != "Android" else 2.0
		"ui_scale": return 1.0
		"auto_ui_scale": return true
		
		"snap": return -0.5
		"color_picker_slider_mode": return GoodColorPicker.SliderMode.RGB
		"path_command_relative": return false
		"file_dialog_show_hidden": return false
		"current_file_path": return ""
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property in _get_setting_names() and get(property) != value:
		queue_save()
		if property == &"editor_formatter" or property == &"export_formatter":
			if value != null:
				value.changed.connect(queue_save)
		if property == &"export_formatter":
			if value != null:
				value.formatting_setting_changed.connect(queue_svg_sync)
	return true

func _get_setting_names() -> PackedStringArray:
	var arr := PackedStringArray()
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_STORAGE:
			arr.append(p.name)
	return arr


const CURRENT_VERSION = 1
@export var version := CURRENT_VERSION

@export var language := ""

# Theming
@export var highlighting_symbol_color := Color("abc9ff")
@export var highlighting_element_color := Color("ff8ccc")
@export var highlighting_attribute_color := Color("bce0ff")
@export var highlighting_string_color := Color("a1ffe0")
@export var highlighting_comment_color := Color("cdcfd280")
@export var highlighting_text_color := Color("cdcfeaac")
@export var highlighting_cdata_color := Color("ffeda1ac")
@export var highlighting_error_color := Color("ff866b")
@export var handle_inner_color := Color("fff")
@export var handle_color := Color("111")
@export var handle_hovered_color := Color("aaa")
@export var handle_selected_color := Color("46f")
@export var handle_hovered_selected_color := Color("f44")
@export var background_color := Color(0.12, 0.132, 0.2, 1)
@export var basic_color_valid := Color("9f9")
@export var basic_color_error := Color("f99")
@export var basic_color_warning := Color("ee5")

# Other
@export var invert_zoom := false
@export var wrap_mouse := false
@export var use_ctrl_for_zoom := true
@export var use_native_file_dialog := true
@export var use_filename_for_window_title := true
@export var handle_size := 1.0
@export var ui_scale := 1.0
@export var auto_ui_scale := true

# Session
@export var snap := -0.5  # Negative when disabled.
@export var color_picker_slider_mode := GoodColorPicker.SliderMode.RGB
@export var path_command_relative := false
@export var file_dialog_show_hidden := false
@export var current_file_path := ""


const MAX_RECENT_DIRS = 5
@export var _recent_dirs := PackedStringArray()

func _cleanup_recent_dirs() -> void:
	var unique_dirs := PackedStringArray()
	# Remove duplicate dirs.
	for dir in _recent_dirs:
		if not dir in unique_dirs:
			unique_dirs.append(dir)
	# Remove non-existent dirs.
	for i in range(unique_dirs.size() - 1, -1, -1):
		if not DirAccess.dir_exists_absolute(unique_dirs[i]):
			_recent_dirs.remove_at(i)
	# Remove dirs above the maximum.
	unique_dirs.resize(MAX_RECENT_DIRS)
	_recent_dirs = unique_dirs

func get_recent_dirs() -> PackedStringArray:
	_cleanup_recent_dirs()
	return _recent_dirs

func get_last_dir() -> String:
	_cleanup_recent_dirs()
	if _recent_dirs.is_empty():
		return OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	else:
		return _recent_dirs[0]

func add_recent_dir(dir: String) -> void:
	_cleanup_recent_dirs()
	# Remove occurrences of this dir in the array.
	for i in range(_recent_dirs.size() - 1, -1, -1):
		if _recent_dirs[i] == dir:
			_recent_dirs.remove_at(i)
	# Add the new dir at the start of the array.
	_recent_dirs.resize(MAX_RECENT_DIRS - 1)
	_recent_dirs = PackedStringArray([dir]) + _recent_dirs


@export var _shortcuts := {}

func action_has_shortcuts(action: String) -> bool:
	return _shortcuts.has(action)

func action_modify_shortcuts(action: String, new_events: Array[InputEvent]) -> void:
	_shortcuts[action] = new_events
	_action_sync_inputmap(action)
	emit_changed()
	Configs.shortcuts_changed.emit()

func _action_sync_inputmap(action: String) -> void:
	InputMap.action_erase_events(action)
	for event in _shortcuts[action]:
		InputMap.action_add_event(action, event)

func update_shortcut_validities() -> void:
	_shortcut_validities.clear()
	for action in ShortcutUtils.get_all_shortcuts():
		for shortcut: InputEventKey in InputMap.action_get_events(action):
			var shortcut_id := shortcut.get_keycode_with_modifiers()
			# If the key already exists, set validity to false, otherwise set to true.
			_shortcut_validities[shortcut_id] = not shortcut_id in _shortcut_validities

func is_shortcut_valid(shortcut: InputEvent) -> bool:
	var shortcut_id = shortcut.get_keycode_with_modifiers()
	if not shortcut_id in _shortcut_validities:
		return true
	return _shortcut_validities[shortcut_id]


@export var _palettes: Array[ColorPalette] = []

func update_palette_validities() -> void:
	_palette_validities.clear()
	for palette in _palettes:
		if not palette.title.is_empty():
			_palette_validities[palette.title] = not palette.title in _palette_validities

func is_palette_valid(checked_palette: ColorPalette) -> bool:
	if checked_palette.title.is_empty():
		return false
	if not checked_palette.title in _palette_validities:
		return true
	return _palette_validities[checked_palette.title]

func is_palette_title_unused(checked_title: String) -> bool:
	for palette in _palettes:
		if palette.title == checked_title:
			return false
	return true

func add_new_palette(new_palette: ColorPalette) -> void:
	_palettes.append(new_palette)
	update_palette_validities()
	emit_changed()

func delete_palette(idx: int) -> void:
	if _palettes.size() <= idx:
		return
	_palettes.remove_at(idx)
	update_palette_validities()
	emit_changed()

func rename_palette(idx: int, new_name: String) -> void:
	if _palettes.size() <= idx:
		return
	_palettes[idx].title = new_name
	update_palette_validities()
	emit_changed()

func replace_palette(idx: int, new_palette: ColorPalette) -> void:
	if _palettes.size() <= idx:
		return
	_palettes[idx] = new_palette
	update_palette_validities()
	emit_changed()

func move_palette_up(idx: int) -> void:
	var palette: ColorPalette = _palettes.pop_at(idx)
	_palettes.insert(idx - 1, palette)
	emit_changed()

func move_palette_down(idx: int) -> void:
	var palette: ColorPalette = _palettes.pop_at(idx)
	_palettes.insert(idx + 1, palette)
	emit_changed()

func palette_apply_preset(idx: int, preset: ColorPalette.Preset) -> void:
	_palettes[idx].apply_preset(preset)
	emit_changed()

func get_palettes() -> Array[ColorPalette]:
	return _palettes

func get_palette_count() -> int:
	return _palettes.size()

func get_palette(idx: int) -> ColorPalette:
	return _palettes[idx]

func set_palettes(new_palettes: Array[ColorPalette]) -> void:
	_palettes = new_palettes
	emit_changed()


@export var editor_formatter: Formatter = null
@export var export_formatter: Formatter = null


func queue_svg_sync() -> void:
	_svg_sync.call_deferred()
	_svg_sync_pending = true

func _svg_sync() -> void:
	if _svg_sync_pending:
		_svg_sync_pending = false
		SVG.sync_elements()

func queue_save() -> void:
	_save.call_deferred()
	_save_pending = true

func _save() -> void:
	if _save_pending:
		_save_pending = false
		Configs.save()
