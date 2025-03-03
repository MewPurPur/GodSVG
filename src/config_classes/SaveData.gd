class_name SaveData extends ConfigResource

const GoodColorPicker = preload("res://src/ui_widgets/good_color_picker.gd")
const ShortcutPanel = preload("res://src/ui_parts/shortcut_panel.gd")

var _palette_validities: Dictionary[String, bool] = {}
var _shortcut_validities: Dictionary[Key, bool] = {}

# Most settings don't need a default.
func get_setting_default(setting: String) -> Variant:
	match setting:
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
		"wraparound_panning": return false
		"use_ctrl_for_zoom": return true
		"use_native_file_dialog": return true
		"use_filename_for_window_title": return true
		"handle_size": return 1.0 if OS.get_name() != "Android" else 2.0
		"ui_scale": return ScalingApproach.AUTO
		"custom_ui_scale": return true
	return null

func reset_to_default() -> void:
	for setting in _get_setting_names():
		set(setting, get_setting_default(setting))

func _get_setting_names() -> PackedStringArray:
	var arr := PackedStringArray()
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_STORAGE:
			if get_setting_default(p.name) != null:
				arr.append(p.name)
	return arr

func validate() -> void:
	if not is_instance_valid(editor_formatter):
		editor_formatter = Formatter.new(Formatter.Preset.PRETTY)
	if not is_instance_valid(export_formatter):
		export_formatter = Formatter.new(Formatter.Preset.COMPACT)
	if _active_tab_index >= _tabs.size() or _active_tab_index < 0:
		_active_tab_index = _active_tab_index  # Run the setter.


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
			Configs.change_locale.call_deferred()
			Configs.language_changed.emit.call_deferred()

# Theming
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

@export var highlighting_comment_color := Color("cdcfd280"):
	set(new_value):
		if highlighting_comment_color != new_value:
			highlighting_comment_color = new_value
			emit_changed()
			Configs.highlighting_colors_changed.emit()

@export var highlighting_text_color := Color("cdcfeaac"):
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

@export var highlighting_error_color := Color("ff866b"):
	set(new_value):
		if highlighting_error_color != new_value:
			highlighting_error_color = new_value
			emit_changed()
			Configs.highlighting_colors_changed.emit()

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

@export var background_color := Color(0.12, 0.132, 0.2, 1):
	set(new_value):
		if background_color != new_value:
			background_color = new_value
			emit_changed()
			Configs.change_background_color.call_deferred()

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

@export var basic_color_warning := Color("ee5"):
	set(new_value):
		if basic_color_warning != new_value:
			basic_color_warning = new_value
			emit_changed()
			Configs.basic_colors_changed.emit()


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
			HandlerGUI.update_window_title.call_deferred()

const HANDLE_SIZE_MIN = 0.5
const HANDLE_SIZE_MAX = 4.0
@export var handle_size := 1.0:
	set(new_value):
		# Validation
		new_value = clampf(new_value, HANDLE_SIZE_MIN, HANDLE_SIZE_MAX)
		if is_nan(new_value):
			new_value = get_setting_default("handle_size")
		# Main part
		if handle_size != new_value:
			handle_size = new_value
			emit_changed()
			Configs.handle_visuals_changed.emit()

enum ScalingApproach {AUTO, CONSTANT_075, CONSTANT_100, CONSTANT_125, CONSTANT_150,
		CONSTANT_175, CONSTANT_200, CONSTANT_300, CONSTANT_400, MAX}
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


# Session
const MAX_SNAP = 16384
@export var snap := -0.5:  # Negative when disabled.
	set(new_value):
		# Validation
		new_value = clampf(new_value, -MAX_SNAP, MAX_SNAP)
		if is_nan(new_value):
			new_value = -0.5
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
	if new_events != Configs.default_shortcuts[action]:
		_shortcuts[action] = new_events
	else:
		_shortcuts.erase(action)
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
	for action in ShortcutUtils.get_all_shortcuts():
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
	for action in ShortcutUtils.get_all_shortcuts():
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
			editor_formatter.changed_deferred.connect(State.sync_elements)

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
			if key < 0 or key >= SHORTCUT_PANEL_MAX_SLOTS or\
			not new_value[key] in ShortcutUtils.get_all_shortcuts():
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


const MAX_TABS = 50
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
		
		new_value = clampi(new_value, 0, _tabs.size() - 1)
		if is_nan(new_value):
			new_value = 0
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
	_tabs.append(new_tab)

func add_empty_tab() -> void:
	_add_new_tab()
	emit_changed()
	Configs.tabs_changed.emit()
	set_active_tab_index(_tabs.size() - 1)

# Adds a new path with the given path, unless something with the path already exists.
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

func remove_tab(idx: int) -> void:
	if idx < 0 or idx >= _tabs.size():
		return
	
	var new_active_tab_index := _active_tab_index
	# If there are no tabs in the end, add one.
	_tabs.remove_at(idx)
	if idx < _active_tab_index:
		new_active_tab_index -= 1
	
	# Clear unnecessary files.
	var used_file_paths := PackedStringArray()
	for tab in _tabs:
		used_file_paths.append(tab.get_edited_file_path())
	
	for file_name in DirAccess.get_files_at(TabData.EDITED_FILES_DIR):
		var full_path := TabData.EDITED_FILES_DIR.path_join(file_name)
		if not full_path in used_file_paths:
			DirAccess.remove_absolute(TabData.EDITED_FILES_DIR.path_join(file_name))
	
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
	if old_idx == new_idx or old_idx < 0 or old_idx > get_tab_count() or\
	new_idx < 0 or new_idx > get_tab_count():
		return
	
	var tab: TabData = _tabs.pop_at(old_idx)
	var adjusted_index := (new_idx - 1) if (old_idx < new_idx) else new_idx
	_tabs.insert(adjusted_index, tab)
	emit_changed()
	set_active_tab_index(adjusted_index)
	Configs.tabs_changed.emit()


# Utility

func get_validity_color(error_condition: bool, warning_condition := false) -> Color:
	return basic_color_error if error_condition else\
			basic_color_warning if warning_condition else basic_color_valid

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
