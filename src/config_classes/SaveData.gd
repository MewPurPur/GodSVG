class_name SaveData extends ConfigResource

enum ThemePreset {DARK, LIGHT, BLACK}
enum HighlighterPreset {DEFAULT_DARK, DEFAULT_LIGHT}

const GoodColorPicker = preload("res://src/ui_widgets/good_color_picker.gd")
const ShortcutPanel = preload("res://src/ui_parts/shortcut_panel.gd")

var _palette_validities: Dictionary[String, bool] = {}
var _shortcut_validities: Dictionary[Key, bool] = {}

# Most settings don't need a default.
func get_setting_default(setting: String) -> Variant:
	match setting:
		"base_color":
			match theme_preset:
				ThemePreset.DARK: return Color("10101d")
				ThemePreset.LIGHT: return Color("e6e6ff")
				ThemePreset.BLACK: return Color("000")
		"accent_color":
			match theme_preset:
				ThemePreset.DARK: return Color("69f")
				ThemePreset.LIGHT: return Color("0031bf")
				ThemePreset.BLACK: return Color("7c8dbf")
		"highlighter_preset":
			match theme_preset:
				ThemePreset.DARK, ThemePreset.BLACK: return HighlighterPreset.DEFAULT_DARK
				ThemePreset.LIGHT: return HighlighterPreset.DEFAULT_LIGHT
		"highlighting_symbol_color":
			match highlighter_preset:
				HighlighterPreset.DEFAULT_DARK: return Color("abc9ff")
				HighlighterPreset.DEFAULT_LIGHT: return Color("23488c")
		"highlighting_element_color":
			match highlighter_preset:
				HighlighterPreset.DEFAULT_DARK: return Color("ff8ccc")
				HighlighterPreset.DEFAULT_LIGHT: return Color("8c004b")
		"highlighting_attribute_color":
			match highlighter_preset:
				HighlighterPreset.DEFAULT_DARK: return Color("bce0ff")
				HighlighterPreset.DEFAULT_LIGHT: return Color("003666")
		"highlighting_string_color":
			match highlighter_preset:
				HighlighterPreset.DEFAULT_DARK: return Color("a1ffe0")
				HighlighterPreset.DEFAULT_LIGHT: return Color("006644")
		"highlighting_comment_color":
			match highlighter_preset:
				HighlighterPreset.DEFAULT_DARK: return Color("d4d6d980")
				HighlighterPreset.DEFAULT_LIGHT: return Color("3e3e4080")
		"highlighting_text_color":
			match highlighter_preset:
				HighlighterPreset.DEFAULT_DARK: return Color("d5d7f2aa")
				HighlighterPreset.DEFAULT_LIGHT: return Color("242433aa")
		"highlighting_cdata_color":
			match highlighter_preset:
				HighlighterPreset.DEFAULT_DARK: return Color("ffeda1ac")
				HighlighterPreset.DEFAULT_LIGHT: return Color("40360dac")
		"highlighting_error_color":
			match highlighter_preset:
				HighlighterPreset.DEFAULT_DARK: return Color("f55")
				HighlighterPreset.DEFAULT_LIGHT: return Color("cc0000")
		"basic_color_valid":
			match theme_preset:
				ThemePreset.DARK, ThemePreset.BLACK: return Color("9f9")
				ThemePreset.LIGHT: return Color("2b2")
		"basic_color_error":
			match theme_preset:
				ThemePreset.DARK, ThemePreset.BLACK: return Color("f99")
				ThemePreset.LIGHT: return Color("b22")
		"basic_color_warning":
			match theme_preset:
				ThemePreset.DARK, ThemePreset.BLACK: return Color("ee6")
				ThemePreset.LIGHT: return Color("991")
		"handle_size": return 1.0 if OS.get_name() != "Android" else 2.0
		"handle_inner_color": return Color("fff")
		"handle_color": return Color("111")
		"handle_hovered_color": return Color("aaa")
		"handle_selected_color": return Color("46f")
		"handle_hovered_selected_color": return Color("f44")
		"selection_rectangle_speed": return 30.0
		"selection_rectangle_width": return 2.0
		"selection_rectangle_dash_length": return 10.0
		"selection_rectangle_color1": return Color("fffc")
		"selection_rectangle_color2": return Color("000c")
		"canvas_color":
			match theme_preset:
				ThemePreset.DARK: return Color("1f2233")
				ThemePreset.LIGHT: return Color("fff")
				ThemePreset.BLACK: return Color("000")
		"grid_color":
			match theme_preset:
				ThemePreset.DARK, ThemePreset.BLACK: return Color("808080")
				ThemePreset.LIGHT: return Color("666")
		
		# Tab bar
		"tab_mmb_close": return true
		
		# Other
		"invert_zoom": return false
		"wraparound_panning": return false
		"use_ctrl_for_zoom": return true
		"ui_scale": return ScalingApproach.AUTO
		"vsync": return true
		"max_fps": return 0
		"keep_screen_on": return false
		"use_native_file_dialog": return true
		"use_filename_for_window_title": return true
	return null

## Resets all settings to their defaults.
func reset_to_default() -> void:
	for setting in _get_setting_names():
		set(setting, get_setting_default(setting))

## Resets the settings tied to theme presets to their defaults, based on the current preset.
func reset_theme_items_to_default() -> void:
	var old_highlighter_preset_value := highlighter_preset
	for setting in THEME_ITEMS:
		set(setting, get_setting_default(setting))
	if old_highlighter_preset_value != highlighter_preset:
		reset_highlighting_items_to_default()

## Resets the settings tied to highlighter presets to their defaults, based on the current preset.
func reset_highlighting_items_to_default() -> void:
	for setting in HIGHLIGHTING_ITEMS:
		set(setting, get_setting_default(setting))

func _get_setting_names() -> PackedStringArray:
	var arr := PackedStringArray()
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_STORAGE:
			if get_setting_default(p.name) != null:
				arr.append(p.name)
	return arr

const THEME_ITEMS: PackedStringArray = [
	"base_color",
	"accent_color",
	"highlighter_preset",
	"basic_color_valid",
	"basic_color_error",
	"basic_color_warning",
	"canvas_color",
	"grid_color",
]

func is_theming_default() -> bool:
	for setting in THEME_ITEMS:
		if get(setting) != get_setting_default(setting):
			return false
	return true

# TODO Typed Dictionary wonkiness Dictionary[ThemePreset, String]. This one was copied
# from an earlier similar implementation, but I didn't bother to test if it's still
# necessary because GodSVG was disheveled while I was implementing the feature.
static func get_theme_preset_value_text_map() -> Dictionary:
	return {
		ThemePreset.DARK: Translator.translate("Dark"),
		ThemePreset.LIGHT: Translator.translate("Light"),
		ThemePreset.BLACK: Translator.translate("Black (OLED)"),
	}

const HIGHLIGHTING_ITEMS: PackedStringArray = [
	"highlighting_symbol_color",
	"highlighting_element_color",
	"highlighting_attribute_color",
	"highlighting_string_color",
	"highlighting_comment_color",
	"highlighting_text_color",
	"highlighting_cdata_color",
	"highlighting_error_color",
]

func is_highlighting_default() -> bool:
	for setting in HIGHLIGHTING_ITEMS:
		if get(setting) != get_setting_default(setting):
			return false
	return true

# TODO Typed Dictionary wonkiness  Dictionary[ThemePreset, String]. This one was copied
# from an earlier similar implementation, but I didn't bother to test if it's still
# necessary because GodSVG was disheveled while I was implementing the feature.
static func get_highlighter_preset_value_text_map() -> Dictionary:
	return {
		HighlighterPreset.DEFAULT_DARK: Translator.translate("Default Dark"),
		HighlighterPreset.DEFAULT_LIGHT: Translator.translate("Default Light"),
	}


func validate() -> void:
	if not is_instance_valid(editor_formatter):
		editor_formatter = Formatter.new(Formatter.Preset.PRETTY)
	if not is_instance_valid(export_formatter):
		export_formatter = Formatter.new(Formatter.Preset.COMPACT)
	if _active_tab_index >= _tabs.size() or _active_tab_index < 0:
		_active_tab_index = _active_tab_index  # Run the setter.
	
	# End of the method, would need to be rewritten if more things need validation.
	for location in [LayoutLocation.TOP_LEFT, LayoutLocation.BOTTOM_LEFT]:
		if _layout.has(location) and not _layout[location].is_empty():
			return
	_layout = {
		LayoutLocation.TOP_LEFT: [Utils.LayoutPart.INSPECTOR, Utils.LayoutPart.CODE_EDITOR]
	}


const CURRENT_VERSION = 1
@export var version := CURRENT_VERSION:
	set(new_value):
		if version != new_value:
			version = new_value
			emit_changed()

@export var language := "":
	set(new_value):
		if language != new_value:
			language = new_value
			emit_changed()
			external_call(Configs.sync_locale)
			external_call(Configs.language_changed.emit)


# Theming

@export var theme_preset := ThemePreset.DARK:
	set(new_value):
		if theme_preset != new_value:
			# Validation
			if not (new_value >= 0 and new_value < ThemePreset.size()):
				new_value = ThemePreset.DARK
			theme_preset = new_value
			emit_changed()

@export var base_color := Color("10101d"):
	set(new_value):
		if base_color != new_value:
			base_color = new_value
			emit_changed()
			external_call(Configs.sync_theme)

@export var accent_color := Color("69f"):
	set(new_value):
		if accent_color != new_value:
			accent_color = new_value
			emit_changed()
			external_call(Configs.sync_theme)


@export var highlighter_preset := HighlighterPreset.DEFAULT_DARK:
	set(new_value):
		if highlighter_preset != new_value:
			# Validation
			if not (new_value >= 0 and new_value < HighlighterPreset.size()):
				new_value = HighlighterPreset.DEFAULT_DARK
			highlighter_preset = new_value
			emit_changed()

@export var highlighting_symbol_color := Color("abc9ff"):
	set(new_value):
		if highlighting_symbol_color != new_value:
			highlighting_symbol_color = new_value
			emit_changed()
			Configs.highlighting_colors_changed.emit()

@export var highlighting_element_color := Color("ff8ccc"):
	set(new_value):
		if highlighting_element_color != new_value:
			highlighting_element_color = new_value
			emit_changed()
			Configs.highlighting_colors_changed.emit()

@export var highlighting_attribute_color := Color("bce0ff"):
	set(new_value):
		if highlighting_attribute_color != new_value:
			highlighting_attribute_color = new_value
			emit_changed()
			Configs.highlighting_colors_changed.emit()

@export var highlighting_string_color := Color("a1ffe0"):
	set(new_value):
		if highlighting_string_color != new_value:
			highlighting_string_color = new_value
			emit_changed()
			Configs.highlighting_colors_changed.emit()

@export var highlighting_comment_color := Color("d4d6d980"):
	set(new_value):
		if highlighting_comment_color != new_value:
			highlighting_comment_color = new_value
			emit_changed()
			Configs.highlighting_colors_changed.emit()

@export var highlighting_text_color := Color("d5d7f2aa"):
	set(new_value):
		if highlighting_text_color != new_value:
			highlighting_text_color = new_value
			emit_changed()
			Configs.highlighting_colors_changed.emit()

@export var highlighting_cdata_color := Color("ffeda1ac"):
	set(new_value):
		if highlighting_cdata_color != new_value:
			highlighting_cdata_color = new_value
			emit_changed()
			Configs.highlighting_colors_changed.emit()

@export var highlighting_error_color := Color("f55"):
	set(new_value):
		if highlighting_error_color != new_value:
			highlighting_error_color = new_value
			emit_changed()
			Configs.highlighting_colors_changed.emit()


@export var basic_color_valid := Color("9f9"):
	set(new_value):
		if basic_color_valid != new_value:
			basic_color_valid = new_value
			emit_changed()
			Configs.basic_colors_changed.emit()

@export var basic_color_error := Color("f99"):
	set(new_value):
		if basic_color_error != new_value:
			basic_color_error = new_value
			emit_changed()
			Configs.basic_colors_changed.emit()

@export var basic_color_warning := Color("ee6"):
	set(new_value):
		if basic_color_warning != new_value:
			basic_color_warning = new_value
			emit_changed()
			Configs.basic_colors_changed.emit()


const HANDLE_SIZE_MIN = 0.5
const HANDLE_SIZE_MAX = 4.0
@export var handle_size := 1.0:
	set(new_value):
		# Validation
		if is_nan(new_value):
			new_value = get_setting_default("handle_size")
		else:
			new_value = clampf(new_value, HANDLE_SIZE_MIN, HANDLE_SIZE_MAX)
		# Main part
		if handle_size != new_value:
			handle_size = new_value
			emit_changed()
			Configs.handle_visuals_changed.emit()

@export var handle_inner_color := Color("fff"):
	set(new_value):
		if handle_inner_color != new_value:
			handle_inner_color = new_value
			emit_changed()
			Configs.handle_visuals_changed.emit()

@export var handle_color := Color("111"):
	set(new_value):
		if handle_color != new_value:
			handle_color = new_value
			emit_changed()
			Configs.handle_visuals_changed.emit()

@export var handle_hovered_color := Color("aaa"):
	set(new_value):
		if handle_hovered_color != new_value:
			handle_hovered_color = new_value
			emit_changed()
			Configs.handle_visuals_changed.emit()

@export var handle_selected_color := Color("46f"):
	set(new_value):
		if handle_selected_color != new_value:
			handle_selected_color = new_value
			emit_changed()
			Configs.handle_visuals_changed.emit()

@export var handle_hovered_selected_color := Color("f44"):
	set(new_value):
		if handle_hovered_selected_color != new_value:
			handle_hovered_selected_color = new_value
			emit_changed()
			Configs.handle_visuals_changed.emit()

const MAX_SELECTION_RECTANGLE_SPEED = 600.0
@export var selection_rectangle_speed := 30.0:
	set(new_value):
		# Validation
		if is_nan(new_value):
			new_value = get_setting_default("selection_rectangle_speed")
		else:
			new_value = clampf(new_value, -MAX_SELECTION_RECTANGLE_SPEED,
					MAX_SELECTION_RECTANGLE_SPEED)
		# Main part
		if selection_rectangle_speed != new_value:
			selection_rectangle_speed = new_value
			emit_changed()
			Configs.selection_rectangle_visuals_changed.emit()

const MAX_SELECTION_RECTANGLE_WIDTH = 8.0
@export var selection_rectangle_width := 2.0:
	set(new_value):
		# Validation
		if is_nan(new_value):
			new_value = get_setting_default("selection_rectangle_width")
		else:
			new_value = clampf(new_value, 1.0, MAX_SELECTION_RECTANGLE_WIDTH)
		# Main part
		if selection_rectangle_width != new_value:
			selection_rectangle_width = new_value
			emit_changed()
			Configs.selection_rectangle_visuals_changed.emit()

const MAX_SELECTION_RECTANGLE_DASH_LENGTH = 600.0
@export var selection_rectangle_dash_length := 10.0:
	set(new_value):
		# Validation
		if is_nan(new_value):
			new_value = get_setting_default("selection_rectangle_dash_length")
		else:
			new_value = clampf(new_value, 1.0, MAX_SELECTION_RECTANGLE_DASH_LENGTH)
		# Main part
		if selection_rectangle_dash_length != new_value:
			selection_rectangle_dash_length = new_value
			emit_changed()
			Configs.selection_rectangle_visuals_changed.emit()

@export var selection_rectangle_color1 := Color("fffc"):
	set(new_value):
		if selection_rectangle_color1 != new_value:
			selection_rectangle_color1 = new_value
			emit_changed()
			Configs.selection_rectangle_visuals_changed.emit()

@export var selection_rectangle_color2 := Color("000c"):
	set(new_value):
		if selection_rectangle_color2 != new_value:
			selection_rectangle_color2 = new_value
			emit_changed()
			Configs.selection_rectangle_visuals_changed.emit()

@export var canvas_color := Color("1f2233"):
	set(new_value):
		if canvas_color != new_value:
			canvas_color = new_value
			emit_changed()
			external_call(Configs.sync_canvas_color)

@export var grid_color := Color("808080"):
	set(new_value):
		if grid_color != new_value:
			grid_color = new_value
			emit_changed()
			Configs.grid_color_changed.emit()


# Tab bar

@export var tab_mmb_close := true:
	set(new_value):
		if tab_mmb_close != new_value:
			tab_mmb_close = new_value
			emit_changed()


# Other

@export var invert_zoom := false:
	set(new_value):
		if invert_zoom != new_value:
			invert_zoom = new_value
			emit_changed()

@export var wraparound_panning := false:
	set(new_value):
		if wraparound_panning != new_value:
			wraparound_panning = new_value
			emit_changed()

@export var use_ctrl_for_zoom := true:
	set(new_value):
		if use_ctrl_for_zoom != new_value:
			use_ctrl_for_zoom = new_value
			emit_changed()

enum ScalingApproach {AUTO, CONSTANT_075, CONSTANT_100, CONSTANT_125, CONSTANT_150,
		CONSTANT_175, CONSTANT_200, CONSTANT_250, CONSTANT_300, CONSTANT_400, MAX}
@export var ui_scale := ScalingApproach.AUTO:
	set(new_value):
		# Validation
		if not (new_value >= 0 and new_value < ScalingApproach.size()):
			new_value = ScalingApproach.AUTO
		# Main part
		if ui_scale != new_value:
			ui_scale = new_value
			emit_changed()
			Configs.ui_scale_changed.emit()

@export var vsync := true:
	set(new_value):
		if vsync != new_value:
			vsync = new_value
			emit_changed()
			external_call(Configs.sync_vsync)

const MAX_FPS_MIN = 12
const MAX_FPS_MAX = 600
@export var max_fps := 0:
	set(new_value):
		# Clamp unless it's 0 (unlimited).
		if is_nan(new_value):
			new_value = get_setting_default("max_fps")
		elif new_value != 0:
			new_value = clampi(new_value, MAX_FPS_MIN, MAX_FPS_MAX)
		
		if max_fps != new_value:
			max_fps = new_value
			emit_changed()
			external_call(Configs.sync_max_fps)

@export var keep_screen_on := false:
	set(new_value):
		if keep_screen_on != new_value:
			keep_screen_on = new_value
			emit_changed()
			external_call(Configs.sync_keep_screen_on)

@export var use_native_file_dialog := true:
	set(new_value):
		if use_native_file_dialog != new_value:
			use_native_file_dialog = new_value
			emit_changed()

@export var use_filename_for_window_title := true:
	set(new_value):
		if use_filename_for_window_title != new_value:
			use_filename_for_window_title = new_value
			emit_changed()
			external_call(HandlerGUI.update_window_title)


# Session

const MAX_SNAP = 16384
@export var snap := -0.5:  # Negative when disabled.
	set(new_value):
		# Validation
		if is_nan(new_value):
			new_value = -0.5
		else:
			new_value = clampf(new_value, -MAX_SNAP, MAX_SNAP)
		# Main part
		if snap != new_value:
			snap = new_value
			emit_changed()
			Configs.snap_changed.emit()

@export var color_picker_slider_mode := GoodColorPicker.SliderMode.RGB:
	set(new_value):
		# Validation
		if not (new_value >= 0 and new_value < GoodColorPicker.SliderMode.size()):
			new_value = GoodColorPicker.SliderMode.RGB
		# Main part
		if color_picker_slider_mode != new_value:
			color_picker_slider_mode = new_value
			emit_changed()

@export var path_command_relative := false:
	set(new_value):
		if path_command_relative != new_value:
			path_command_relative = new_value
			emit_changed()

@export var file_dialog_show_hidden := false:
	set(new_value):
		if file_dialog_show_hidden != new_value:
			file_dialog_show_hidden = new_value
			emit_changed()


const MAX_RECENT_DIRS = 5
@export var _recent_dirs := PackedStringArray():
	set(new_value):
		if _recent_dirs != new_value:
			_recent_dirs = new_value
			_validate_recent_dirs()
			emit_changed()

func _validate_recent_dirs() -> void:
	var unique_dirs := PackedStringArray()
	# Remove duplicate dirs.
	for dir in _recent_dirs:
		if not dir in unique_dirs:
			unique_dirs.append(dir)
	# Remove non-existent dirs.
	for i in range(unique_dirs.size() - 1, -1, -1):
		if not DirAccess.dir_exists_absolute(unique_dirs[i]):
			unique_dirs.remove_at(i)
	# Remove dirs above the maximum.
	if unique_dirs.size() > MAX_RECENT_DIRS:
		unique_dirs.resize(MAX_RECENT_DIRS)
	_recent_dirs = unique_dirs

func get_recent_dirs() -> PackedStringArray:
	_validate_recent_dirs()
	return _recent_dirs

func add_recent_dir(dir: String) -> void:
	_validate_recent_dirs()
	# Remove occurrences of this dir in the array.
	for i in range(_recent_dirs.size() - 1, -1, -1):
		if _recent_dirs[i] == dir:
			_recent_dirs.remove_at(i)
	# Add the new dir at the start of the array.
	_recent_dirs.resize(MAX_RECENT_DIRS - 1)
	_recent_dirs = PackedStringArray([dir]) + _recent_dirs


@export var _shortcuts: Dictionary[String, Array] = {}:
	set(new_value):
		if _shortcuts != new_value:
			_shortcuts = new_value
			for action in _shortcuts:
				if InputMap.has_action(action):
					_action_sync_inputmap(action)
				else:
					_shortcuts.erase(action)
			update_shortcut_validities()
			emit_changed()
			Configs.shortcuts_changed.emit()

func action_has_shortcuts(action: String) -> bool:
	return _shortcuts.has(action)

func action_get_shortcuts(action: String) -> Array[InputEvent]:
	if action_has_shortcuts(action):
		return _shortcuts[action]
	else:
		return Configs.default_shortcuts[action]

func action_modify_shortcuts(action: String, new_events: Array[InputEvent]) -> void:
	var are_new_events_default := true
	if new_events.size() != Configs.default_shortcuts[action].size():
		are_new_events_default = false
	else:
		for i in new_events.size():
			if not new_events[i].is_match(Configs.default_shortcuts[action][i]):
				are_new_events_default = false
				break
	
	if are_new_events_default:
		_shortcuts.erase(action)
	else:
		_shortcuts[action] = new_events
	
	_action_sync_inputmap(action)
	update_shortcut_validities()
	emit_changed()
	Configs.shortcuts_changed.emit()

func _action_sync_inputmap(action: String) -> void:
	InputMap.action_erase_events(action)
	for event in action_get_shortcuts(action):
		InputMap.action_add_event(action, event)

func update_shortcut_validities() -> void:
	_shortcut_validities.clear()
	for action in ShortcutUtils.get_all_actions():
		for shortcut: InputEventKey in InputMap.action_get_events(action):
			var shortcut_id := shortcut.get_keycode_with_modifiers()
			# If the key already exists, set validity to false, otherwise set to true.
			_shortcut_validities[shortcut_id] = not shortcut_id in _shortcut_validities

func is_shortcut_valid(shortcut: InputEventKey) -> bool:
	var shortcut_id := shortcut.get_keycode_with_modifiers()
	if not shortcut_id in _shortcut_validities:
		return true
	return _shortcut_validities[shortcut_id]

func get_actions_with_shortcut(shortcut: InputEventKey) -> PackedStringArray:
	var shortcut_id := shortcut.get_keycode_with_modifiers()
	if not shortcut_id in _shortcut_validities:
		return PackedStringArray()
	elif _shortcut_validities[shortcut_id]:
		return PackedStringArray()
	
	var actions_with_shortcut := PackedStringArray()
	for action in ShortcutUtils.get_all_actions():
		for action_shortcut: InputEventKey in InputMap.action_get_events(action):
			if action_shortcut.get_keycode_with_modifiers() == shortcut_id:
				actions_with_shortcut.append(action)
				break
	return actions_with_shortcut


@export var _palettes: Array[Palette] = []:
	set(new_value):
		if _palettes != new_value:
			_palettes = new_value
			_update_palette_validities()
			emit_changed()
			for palette in _palettes:
				palette.changed.connect(emit_changed)

# Mark invalid palettes, rather than removing them.
func _update_palette_validities() -> void:
	_palette_validities.clear()
	for palette in _palettes:
		if not palette.title.is_empty():
			_palette_validities[palette.title] = not palette.title in _palette_validities

func is_palette_valid(checked_palette: Palette) -> bool:
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

func add_palette(new_palette: Palette) -> void:
	_palettes.append(new_palette)
	new_palette.changed.connect(emit_changed)
	_update_palette_validities()
	emit_changed()

func delete_palette(idx: int) -> void:
	if _palettes.size() <= idx:
		return
	_palettes.remove_at(idx)
	_update_palette_validities()
	emit_changed()

func rename_palette(idx: int, new_name: String) -> void:
	if _palettes.size() <= idx:
		return
	_palettes[idx].title = new_name
	_update_palette_validities()
	emit_changed()

func replace_palette(idx: int, new_palette: Palette) -> void:
	if _palettes.size() <= idx:
		return
	_palettes[idx] = new_palette
	new_palette.changed.connect(emit_changed)
	_update_palette_validities()
	emit_changed()

func move_palette_up(idx: int) -> void:
	var palette: Palette = _palettes.pop_at(idx)
	_palettes.insert(idx - 1, palette)
	emit_changed()

func move_palette_down(idx: int) -> void:
	var palette: Palette = _palettes.pop_at(idx)
	_palettes.insert(idx + 1, palette)
	emit_changed()

func get_palettes() -> Array[Palette]:
	return _palettes

func get_palette_count() -> int:
	return _palettes.size()

func get_palette(idx: int) -> Palette:
	return _palettes[idx]

func set_palettes(new_palettes: Array[Palette]) -> void:
	_palettes = new_palettes
	emit_changed()


@export var editor_formatter: Formatter = null:
	set(new_value):
		if editor_formatter != new_value and is_instance_valid(new_value):
			editor_formatter = new_value
			emit_changed()
			editor_formatter.changed.connect(emit_changed)
			editor_formatter.changed_deferred.connect(State.sync_to_editor_formatter)

@export var export_formatter: Formatter = null:
	set(new_value):
		if export_formatter != new_value and is_instance_valid(new_value):
			export_formatter = new_value
			emit_changed()
			export_formatter.changed.connect(emit_changed)


@export var shortcut_panel_layout := ShortcutPanel.Layout.HORIZONTAL_STRIP:
	set(new_value):
		# Validation
		if not (new_value >= 0 and new_value < ShortcutPanel.Layout.size()):
			new_value = ShortcutPanel.Layout.HORIZONTAL_STRIP
		# Main part
		if shortcut_panel_layout != new_value:
			shortcut_panel_layout = new_value
			emit_changed()
			Configs.shortcut_panel_changed.emit()

const SHORTCUT_PANEL_MAX_SLOTS = 6
@export var _shortcut_panel_slots: Dictionary[int, String] = {}:
	set(new_value):
		# Validation
		for key in new_value:
			if key < 0 or key >= SHORTCUT_PANEL_MAX_SLOTS or not new_value[key] in ShortcutUtils.get_all_actions():
				new_value.erase(key)
		# Main part
		if _shortcut_panel_slots != new_value:
			_shortcut_panel_slots = new_value
			emit_changed()

func get_shortcut_panel_slots() -> Dictionary:
	return _shortcut_panel_slots

func get_shortcut_panel_slot(idx: int) -> String:
	return _shortcut_panel_slots.get(idx, "")

func set_shortcut_panel_slot(slot: int, shortcut: String) -> void:
	if _shortcut_panel_slots.has(slot) and _shortcut_panel_slots[slot] == shortcut:
		return
	_shortcut_panel_slots[slot] = shortcut
	emit_changed()
	Configs.shortcut_panel_changed.emit()

func set_shortcut_panel_slots(slots: Dictionary[int, String]) -> void:
	_shortcut_panel_slots = slots
	emit_changed()
	Configs.shortcut_panel_changed.emit()

func erase_shortcut_panel_slot(slot: int) -> void:
	if not _shortcut_panel_slots.has(slot):
		return
	_shortcut_panel_slots.erase(slot)
	emit_changed()
	Configs.shortcut_panel_changed.emit()


const MAX_TABS = 4096
@export var _tabs: Array[TabData] = []:
	set(new_value):
		# Validation
		var used_ids := PackedInt32Array()
		for idx in range(new_value.size() - 1, -1, -1):
			var tab := new_value[idx]
			if not is_instance_valid(tab) or tab.id in used_ids:
				new_value.remove_at(idx)
			else:
				used_ids.append(tab.id)
		
		if new_value.size() > MAX_TABS:
			new_value.resize(MAX_TABS)
		# Main part
		if _tabs != new_value:
			_tabs = new_value
			if _active_tab_index >= _tabs.size():
				set_active_tab_index(0)
			
			for tab in _tabs:
				tab.changed.connect(emit_changed)
				tab.status_changed.connect(_on_tab_status_changed.bind(tab.id))
			emit_changed()
			if _tabs.is_empty():
				_add_new_tab()

@export var _active_tab_index := 0:
	set(new_value):
		# Validation
		if _tabs.is_empty():
			_add_new_tab()
		
		if is_nan(new_value):
			new_value = 0
		else:
			new_value = clampi(new_value, 0, _tabs.size() - 1)
		# Main part
		if _active_tab_index != new_value:
			_active_tab_index = new_value
			emit_changed()

func _on_tab_status_changed(id: int) -> void:
	if id == _tabs[_active_tab_index].id:
		Configs.active_tab_status_changed.emit()
	Configs.tabs_changed.emit()

func has_tabs() -> bool:
	return not _tabs.is_empty()

func get_tab_count() -> int:
	return _tabs.size()

func get_tab(idx: int) -> TabData:
	return _tabs[idx] if (idx < _tabs.size() and idx >= 0) else null

func get_active_tab() -> TabData:
	return get_tab(_active_tab_index)

func get_tabs() -> Array[TabData]:
	return _tabs


func get_active_tab_index() -> int:
	return _active_tab_index

func set_active_tab_index(new_index: int) -> void:
	if _active_tab_index == new_index:
		return
	
	if new_index >= _tabs.size() or new_index < 0:
		return
	
	if _active_tab_index >= 0 and _active_tab_index < _tabs.size():
		_tabs[_active_tab_index].deactivate()
	var old_id := _tabs[_active_tab_index].id
	_active_tab_index = new_index
	_tabs[_active_tab_index].activate()
	if old_id != _tabs[_active_tab_index].id:
		Configs.active_tab_changed.emit()

# Basic operation that all tab adding methods call.
func _add_new_tab() -> void:
	if _tabs.size() >= MAX_TABS:
		return
	
	var used_ids := PackedInt32Array()
	for tab in _tabs:
		used_ids.append(tab.id)
	var new_id := 1
	while true:
		if not new_id in used_ids:
			break
		new_id += 1
	
	var new_tab := TabData.new(new_id)
	new_tab.fully_loaded = false
	new_tab.changed.connect(emit_changed)
	new_tab.status_changed.connect(_on_tab_status_changed.bind(new_id))
	
	# Clear file path for the new tab.
	var new_tab_path := new_tab.get_edited_file_path()
	if FileAccess.file_exists(new_tab_path):
		DirAccess.remove_absolute(new_tab_path)
	
	_tabs.append(new_tab)

func add_empty_tab() -> void:
	_add_new_tab()
	emit_changed()
	Configs.tabs_changed.emit()
	set_active_tab_index(_tabs.size() - 1)

# Adds a new path with the given path.
# If a tab with the path already exists, it's set as the active tab instead.
func add_tab_with_path(new_file_path: String) -> void:
	for idx in _tabs.size():
		if _tabs[idx].svg_file_path == new_file_path:
			set_active_tab_index(idx)
			return
	_add_new_tab()
	_tabs[-1].svg_file_path = new_file_path
	emit_changed()
	Configs.tabs_changed.emit()
	set_active_tab_index(_tabs.size() - 1)

# Note that a method for removing multiple tabs at once isn't straightforward,
# since removed tabs can show dialogs asking the user if they should be saved.
func remove_tab(idx: int) -> void:
	if idx < 0 or idx >= _tabs.size():
		return
	
	var new_active_tab_index := _active_tab_index
	# If there are no tabs in the end, add one.
	_tabs.remove_at(idx)
	if idx < _active_tab_index:
		new_active_tab_index -= 1
	
	# Clear unnecessary files. This will clear the removed tab too.
	var used_file_paths := PackedStringArray()
	for tab in _tabs:
		used_file_paths.append(tab.get_edited_file_path())
	
	if DirAccess.dir_exists_absolute(TabData.EDITED_FILES_DIR):
		for file_name in DirAccess.get_files_at(TabData.EDITED_FILES_DIR):
			var full_path := TabData.EDITED_FILES_DIR.path_join(file_name)
			if not full_path in used_file_paths:
				DirAccess.remove_absolute(full_path)
	
	if _tabs.is_empty():
		_add_new_tab()
	
	emit_changed()
	Configs.tabs_changed.emit()
	var has_tab_changed := (_active_tab_index == idx)
	_active_tab_index = clampi(new_active_tab_index, 0, _tabs.size() - 1)
	_tabs[_active_tab_index].activate()
	if has_tab_changed:
		Configs.active_tab_changed.emit()

func remove_active_tab() -> void:
	remove_tab(_active_tab_index)

func move_tab(old_idx: int, new_idx: int) -> void:
	if old_idx == new_idx or old_idx < 0 or old_idx > get_tab_count() or new_idx < 0 or new_idx > get_tab_count():
		return
	
	var tab: TabData = _tabs.pop_at(old_idx)
	var adjusted_index := (new_idx - 1) if (old_idx < new_idx) else new_idx
	_tabs.insert(adjusted_index, tab)
	emit_changed()
	set_active_tab_index(adjusted_index)
	Configs.tabs_changed.emit()


enum LayoutLocation {NONE, EXCLUDED, TOP_LEFT, BOTTOM_LEFT}

@export var _layout: Dictionary[LayoutLocation, Array]:  # Array[Utils.LayoutPart]
	set(new_value):
		# Validation
		for key in new_value:
			# Ensure keys correspond to layout locations.
			if key < 0 or key >= LayoutLocation.size() or key == LayoutLocation.NONE:
				new_value.erase(key)
			else:
				# Ensure arrays correspond to layout parts.
				var arr := new_value[key]
				for i in range(arr.size() - 1, -1, -1):
					if not arr[i] is Utils.LayoutPart or arr[i] < 0 or arr[i] >= Utils.LayoutPart.size():
						arr.remove_at(i)
		# Ensure non-duplicate layout parts and no empty arrays.
		var used_layout_parts: Array[Utils.LayoutPart] = []
		for location in LayoutLocation.size():
			if new_value.has(location):
				var arr := new_value[location]
				for i in range(arr.size() - 1, -1, -1):
					if arr[i] in used_layout_parts:
						arr.remove_at(i)
					else:
						used_layout_parts.append(arr[i])
				if arr.is_empty():
					new_value.erase(location)
		# Put all layout parts that aren't listed in excluded.
		used_layout_parts += [Utils.LayoutPart.NONE, Utils.LayoutPart.VIEWPORT]
		for part in Utils.LayoutPart.size():
			if not part in used_layout_parts:
				if not new_value.has(LayoutLocation.EXCLUDED):
					new_value[LayoutLocation.EXCLUDED] = []
				new_value[LayoutLocation.EXCLUDED].append(part)
		# Main part
		if _layout != new_value:
			_layout = new_value
			emit_changed()

func set_layout_parts(location: LayoutLocation, parts: Array[Utils.LayoutPart],
notify_layout_changed := true) -> void:
	if (_layout.has(location) and parts == _layout[location]) or (not _layout.has(location) and parts.is_empty()):
		return
	
	if parts.is_empty():
		_layout.erase(location)
	else:
		_layout[location] = parts
	emit_changed()
	if notify_layout_changed:
		Configs.layout_changed.emit()

func get_layout_parts(location: LayoutLocation) -> Array[Utils.LayoutPart]:
	if _layout.has(location):
		var output: Array[Utils.LayoutPart] = []
		output.assign(_layout[location])
		return output
	else:
		return []

func get_layout_part_location(part: Utils.LayoutPart) -> LayoutLocation:
	for location in _layout:
		if _layout[location].has(part):
			return location
	return LayoutLocation.NONE

func get_layout_part_index(part: Utils.LayoutPart) -> int:
	for location in _layout:
		if _layout[location].has(part):
			return _layout[location].find(part)
	return -1


@export var horizontal_splitter_offset := -180:
	set(new_value):
		# Validation
		if is_nan(new_value):
			new_value = 0
		# Main part
		if horizontal_splitter_offset != new_value:
			horizontal_splitter_offset = new_value
			emit_changed()

@export var left_vertical_splitter_offset := -240:
	set(new_value):
		# Validation
		if is_nan(new_value):
			new_value = 0
		# Main part
		if left_vertical_splitter_offset != new_value:
			left_vertical_splitter_offset = new_value
			emit_changed()

@export var icon_view_sizes: PackedInt64Array = [16, 24, 32, 48, 64]:
	set(new_value):
		if icon_view_sizes != new_value:
			icon_view_sizes = new_value
			emit_changed()


# Utility

func get_validity_color(error_condition: bool, warning_condition := false) -> Color:
	return basic_color_error if error_condition else basic_color_warning if warning_condition else basic_color_valid

func get_active_tab_dir() -> String:
	var tab := get_active_tab()
	if tab.svg_file_path.is_empty():
		return get_last_dir()
	else:
		return tab.svg_file_path.get_base_dir()

func get_last_dir() -> String:
	_validate_recent_dirs()
	if _recent_dirs.is_empty() or not DirAccess.dir_exists_absolute(_recent_dirs[0]):
		return OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	else:
		return _recent_dirs[0]
