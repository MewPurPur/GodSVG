class_name SaveData extends Resource

const GoodColorPicker = preload("res://src/ui_widgets/good_color_picker.gd")
const GlobalActions = preload("res://src/ui_parts/global_actions.gd")

var _palette_validities := {}
var _shortcut_validities := {}

static func get_setting_default(setting: String) -> Variant:
	match setting:
		"version": return CURRENT_VERSION
		"language": return "en"
		"invert_zoom": return false
		"wrap_mouse": return false
		"use_ctrl_for_zoom": return true
		"use_native_file_dialog": return true
		"use_filename_for_window_title": return true
		"handle_size": return 2.0 if DisplayServer.get_name() == "Android" else 1.0
		"ui_scale": return 1.0
		"auto_ui_scale": return true
		"snap": return -0.5
		"color_picker_slider_mode": return GoodColorPicker.SliderMode.RGB
		"path_command_relative": return false
		"file_dialog_show_hidden": return false
		"layout": return GlobalActions.Layout.CODE_EDITOR_TOP_INSPECTOR_BOTTOM
		"last_used_dir": return ""
	return null

func _set(property: StringName, value: Variant) -> bool:
	print("!")
	if get(property) == value:
		return true
	emit_changed()
	# Special actions for certain properties.
	match property:
		&"language":
			TranslationServer.set_locale.call_deferred(value)
			Configs.language_changed.emit.call_deferred()
		&"use_filename_for_window_title": Configs.sync_window_title.call_deferred()
		&"handle_size": Configs.handle_visuals_changed.emit.call_deferred()
		&"ui_scale": Configs.ui_scale_changed.emit.call_deferred()
		&"auto_ui_scale": Configs.ui_scale_changed.emit.call_deferred()
		&"snap": Configs.snap_changed.emit.call_deferred()
		&"layout": Configs.layout_changed.emit.call_deferred()
		&"editor_formatter":
			SVG.sync_elements.call_deferred()
			value.config_settings_changed.connect(SVG.sync_elements)
		&"_shortcuts":
			for action in value:
				_action_sync_inputmap.call_deferred(action)
			Configs.shortcuts_changed.emit.call_deferred()
	return true

const CURRENT_VERSION = 1
@export var version := CURRENT_VERSION

@export var language := ""

# Other
@export var invert_zoom := false
@export var wrap_mouse := false
@export var use_ctrl_for_zoom := true

@export var use_native_file_dialog := true
@export var use_filename_for_window_title := true
@export var handle_size := 1.0
@export var ui_scale := 1.0
@export var auto_ui_scale := true:
	set(new_value):
		print("?")

# Session
@export var snap := -0.5  # Negative when disabled.
@export var color_picker_slider_mode := GoodColorPicker.SliderMode.RGB
@export var path_command_relative := false
@export var file_dialog_show_hidden := false
@export var layout := GlobalActions.Layout.CODE_EDITOR_TOP_INSPECTOR_BOTTOM
@export var last_used_dir := ""

@export var editor_formatter: Formatter = null
@export var export_formatter: Formatter = null

@export var theme_config: ThemeConfig = null

@export var _tabs: Array[TabData] = []
@export var _active_tab_index := 0

@export var _palettes: Array[ColorPalette] = []

# The setter activates on load.
@export var _shortcuts := {}


func has_tabs() -> bool:
	return not _tabs.is_empty()

func get_tabs() -> Array[TabData]:
	return _tabs

func get_tab_count() -> int:
	return _tabs.size()

func get_current_tab() -> TabData:
	if _active_tab_index >= _tabs.size():
		return null
	return _tabs[_active_tab_index]

func add_empty_tab() -> void:
	_tabs.append(TabData.new())

func remove_tab(idx: int) -> void:
	_tabs.remove_at(idx)
	if _tabs.is_empty():
		add_empty_tab()

func set_active_tab(idx: int) -> void:
	if idx < 0 or idx >= _tabs.size():
		_active_tab_index = 0
	_active_tab_index = idx


#region Palette interaction methods

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

#endregion


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
