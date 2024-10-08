extends PanelContainer

const FormatterConfigWidget = preload("res://src/ui_widgets/formatter_config.tscn")
const PaletteConfigWidget = preload("res://src/ui_widgets/palette_config.tscn")
const ShortcutConfigWidget = preload("res://src/ui_widgets/setting_shortcut.tscn")
const ShortcutShowcaseWidget = preload("res://src/ui_widgets/presented_shortcut.tscn")
const SettingFrame = preload("res://src/ui_widgets/setting_frame.tscn")
const ProfileFrame = preload("res://src/ui_widgets/profile_frame.tscn")

const plus_icon = preload("res://visual/icons/Plus.svg")

@onready var lang_button: Button = $VBoxContainer/Language
@onready var content_container: ScrollContainer = %ContentContainer
@onready var tabs: VBoxContainer = %Tabs
@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var advice_panel: PanelContainer = $VBoxContainer/AdvicePanel
@onready var advice_label: Label = $VBoxContainer/AdvicePanel/AdviceLabel

var focused_tab := ""
var current_setup_setting := ""
var advice := {}  # String: String

func _ready() -> void:
	close_button.pressed.connect(queue_free)
	GlobalSettings.language_changed.connect(setup_everything)
	update_language_button()
	update_close_button()
	setup_tabs()
	tabs.get_child(0).button_pressed = true
	GlobalSettings.theme_changed.connect(setup_theming)
	setup_theming()

func setup_theming() -> void:
	var stylebox := get_theme_stylebox("panel").duplicate()
	stylebox.content_margin_top += 4.0
	add_theme_stylebox_override("panel", stylebox)

func setup_tabs() -> void:
	for tab in tabs.get_children():
		tab.queue_free()
	var button_group := ButtonGroup.new()
	add_tab("formatting", TranslationServer.translate("Formatting"), button_group)
	add_tab("palettes", TranslationServer.translate("Palettes"), button_group)
	add_tab("shortcuts", TranslationServer.translate("Shortcuts"), button_group)
	add_tab("theming", TranslationServer.translate("Theming"), button_group)
	add_tab("other", TranslationServer.translate("Other"), button_group)

func add_tab(tab_name: String, tab_text: String, button_group: ButtonGroup) -> void:
	var tab := Button.new()
	tab.text = tab_text
	tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
	tab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tab.toggle_mode = true
	tab.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	tab.focus_mode = Control.FOCUS_NONE
	tab.theme_type_variation = "SideTab"
	tab.toggled.connect(_on_tab_toggled.bind(tab_name))
	tab.button_group = button_group
	tab.button_pressed = (tab_name == focused_tab)
	tabs.add_child(tab)

func setup_everything() -> void:
	setup_tabs()
	setup_content()
	update_close_button()

func update_close_button() -> void:
	close_button.text = TranslationServer.translate("Close")

func _on_tab_toggled(toggled_on: bool, tab_name: String) -> void:
	if toggled_on:
		focused_tab = tab_name
		setup_content()

func setup_content() -> void:
	for child in content_container.get_children():
		child.queue_free()
	match focused_tab:
		"formatting":
			advice_panel.hide()
			var vbox := VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content_container.add_child(vbox)
			rebuild_formatters()
		"palettes":
			advice_panel.hide()
			var vbox := VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content_container.add_child(vbox)
			rebuild_color_palettes()
		"shortcuts":
			advice_panel.hide()
			var vbox := VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content_container.add_child(vbox)
			var categories := HFlowContainer.new()
			var button_group := ButtonGroup.new()
			for tab_idx in shortcut_tab_names:
				var btn := Button.new()
				btn.toggle_mode = true
				btn.button_group = button_group
				btn.pressed.connect(show_keybinds.bind(tab_idx))
				btn.text = get_translated_shortcut_tab(tab_idx)
				btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				btn.focus_mode = Control.FOCUS_NONE
				categories.add_child(btn)
			vbox.add_child(categories)
			var shortcuts := VBoxContainer.new()
			shortcuts.add_theme_constant_override("separation", 3)
			shortcuts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			shortcuts.size_flags_vertical = Control.SIZE_EXPAND_FILL
			vbox.add_child(shortcuts)
			categories.get_child(0).button_pressed = true
			categories.get_child(0).pressed.emit()
		"theming":
			advice_panel.hide()
			var vbox := VBoxContainer.new()
			vbox.add_theme_constant_override("separation", 6)
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content_container.add_child(vbox)
			
			add_section(TranslationServer.translate("SVG Text colors"))
			current_setup_setting = "highlighting_symbol_color"
			add_color_edit(TranslationServer.translate("Symbol color"))
			current_setup_setting = "highlighting_element_color"
			add_color_edit(TranslationServer.translate("Element color"))
			current_setup_setting = "highlighting_attribute_color"
			add_color_edit(TranslationServer.translate("Attribute color"))
			current_setup_setting = "highlighting_string_color"
			add_color_edit(TranslationServer.translate("String color"))
			current_setup_setting = "highlighting_comment_color"
			add_color_edit(TranslationServer.translate("Comment color"))
			current_setup_setting = "highlighting_text_color"
			add_color_edit(TranslationServer.translate("Text color"))
			current_setup_setting = "highlighting_cdata_color"
			add_color_edit(TranslationServer.translate("CDATA color"))
			current_setup_setting = "highlighting_error_color"
			add_color_edit(TranslationServer.translate("Error color"))
			
			add_section(TranslationServer.translate("Handle colors"))
			current_setup_setting = "handle_inside_color"
			add_color_edit(TranslationServer.translate("Inside color"), false)
			current_setup_setting = "handle_color"
			add_color_edit(TranslationServer.translate("Normal color"), false)
			current_setup_setting = "handle_hovered_color"
			add_color_edit(TranslationServer.translate("Hovered color"), false)
			current_setup_setting = "handle_selected_color"
			add_color_edit(TranslationServer.translate("Selected color"), false)
			current_setup_setting = "handle_hovered_selected_color"
			add_color_edit(TranslationServer.translate("Hovered selected color"), false)
			
			add_section(TranslationServer.translate("Basic colors"))
			current_setup_setting = "background_color"
			add_color_edit(TranslationServer.translate("Background color"), false)
			current_setup_setting = "basic_color_valid"
			add_color_edit(TranslationServer.translate("Valid color"))
			current_setup_setting = "basic_color_error"
			add_color_edit(TranslationServer.translate("Error color"))
			current_setup_setting = "basic_color_warning"
			add_color_edit(TranslationServer.translate("Warning color"))
		"other":
			advice_panel.show()
			var vbox := VBoxContainer.new()
			vbox.add_theme_constant_override("separation", 6)
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content_container.add_child(vbox)
			add_section(TranslationServer.translate("Input"))
			current_setup_setting = "invert_zoom"
			add_checkbox(TranslationServer.translate("Invert zoom direction"))
			add_advice(TranslationServer.translate(
					"Swaps zoom in and zoom out with the mouse wheel."))
			current_setup_setting = "wrap_mouse"
			var wrap_mouse := add_checkbox(TranslationServer.translate("Wrap mouse"))
			add_advice(TranslationServer.translate(
					"Wraps the mouse cursor around when panning the viewport."))
			current_setup_setting = "use_ctrl_for_zoom"
			add_checkbox(TranslationServer.translate("Use CTRL for zooming"))
			add_advice(TranslationServer.translate(
					"If turned on, scrolling will pan the view. To zoom, hold CTRL while scrolling."))
			
			add_section(TranslationServer.translate("Miscellaneous"))
			current_setup_setting = "use_native_file_dialog"
			var use_native_file_dialog := add_checkbox(
					TranslationServer.translate("Use native file dialog"))
			add_advice(TranslationServer.translate(
					"If turned on, uses your operating system's native file dialog. If turned off, uses GodSVG's built-in file dialog."))
			current_setup_setting = "use_filename_for_window_title"
			add_checkbox(TranslationServer.translate("Sync window title to file name"))
			add_advice(TranslationServer.translate(
					"If turned off, the window title will remain simply \"GodSVG\" regardless of the current file."))
			current_setup_setting = "handle_size"
			add_number_dropdown(TranslationServer.translate("Handle size"),
					[0.75, 1.0, 1.25, 1.5, 1.75, 2.0], false, false, 0.5, 2.5)
			add_advice(TranslationServer.translate(
					"Increases the visual size and grabbing area of handles."))
			current_setup_setting = "ui_scale"
			add_number_dropdown(TranslationServer.translate("UI scale"),
					[0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0], false, false, 0.5, 5.0)
			add_advice(TranslationServer.translate(
					"Changes the scale of the visual user interface."))
			current_setup_setting = "auto_ui_scale"
			add_checkbox(TranslationServer.translate("Auto UI scale"))
			add_advice(TranslationServer.translate(
					"Scales the user interface based on the screen size."))
			
			# Disable mouse wrap if not available.
			if not DisplayServer.has_feature(DisplayServer.FEATURE_MOUSE_WARP):
				wrap_mouse.disabled = true
				wrap_mouse.checkbox.set_pressed_no_signal(false)
			# Disable fallback file dialog on web, and native file dialog if not available.
			if OS.has_feature("web"):
				use_native_file_dialog.disabled = true
				use_native_file_dialog.checkbox.set_pressed_no_signal(true)
			elif not DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
				use_native_file_dialog.disabled = true
				use_native_file_dialog.checkbox.set_pressed_no_signal(false)


func add_section(section_name: String) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	var label := Label.new()
	label.text = section_name
	vbox.add_child(label)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 2
	vbox.add_child(spacer)
	content_container.get_child(-1).add_child(vbox)

func add_checkbox(text: String) -> Control:
	var frame := SettingFrame.instantiate()
	frame.text = text
	setup_frame(frame)
	frame.setup_checkbox()
	add_frame(frame)
	return frame

func add_dropdown(text: String) -> Control:
	var frame := SettingFrame.instantiate()
	frame.text = text
	setup_frame(frame)
	frame.setup_dropdown(GlobalSettings.get_enum_texts(current_setup_setting))
	add_frame(frame)
	return frame

func add_number_dropdown(text: String, values: Array[float], is_integer := false,
restricted := true, min_value := -INF, max_value := INF) -> Control:
	var frame := SettingFrame.instantiate()
	frame.text = text
	setup_frame(frame)
	frame.setup_number_dropdown(values, is_integer, restricted, min_value, max_value)
	add_frame(frame)
	return frame

func add_color_edit(text: String, enable_alpha := true) -> Control:
	var frame := SettingFrame.instantiate()
	frame.text = text
	setup_frame(frame)
	frame.setup_color(enable_alpha)
	add_frame(frame)
	return frame

func setup_frame(frame: Control) -> void:
	frame.getter = GlobalSettings.savedata.get.bind(current_setup_setting)
	var bind := current_setup_setting
	frame.setter = func(p): GlobalSettings.modify_setting(bind, p)
	frame.default = GlobalSettings.get_default(current_setup_setting)
	frame.mouse_entered.connect(show_advice.bind(current_setup_setting))
	frame.mouse_exited.connect(hide_advice.bind(current_setup_setting))

func add_frame(frame: Control) -> void:
	content_container.get_child(-1).get_child(-1).add_child(frame)

func add_advice(text: String) -> void:
	advice[current_setup_setting] = text


func show_advice(setting: String) -> void:
	if advice.has(setting):
		advice_label.text = advice[setting]

func hide_advice(setting: String) -> void:
	if advice.has(setting) and advice_label.text == advice[setting]:
		advice_label.text = ""


func _on_language_pressed() -> void:
	var btn_arr: Array[Button] = []
	for lang in TranslationServer.get_loaded_locales():
		# Translation percentages.
		if lang != "en":
			var translation_obj := TranslationServer.get_translation_object(lang)
			var translated_count := 0
			for msg in translation_obj.get_translated_message_list():
				if not msg.is_empty():
					translated_count += 1
			var percentage := String.num(translated_count * 100.0 /\
					translation_obj.get_message_count(), 1) + "%"
			
			var is_current_locale := lang == TranslationServer.get_locale()
			var new_btn := ContextPopup.create_button(
					TranslationServer.get_locale_name(lang) + " (" + lang.to_upper() + ")",
					Callable(), is_current_locale)
			
			var ret_button := Button.new()
			ret_button.theme_type_variation = "ContextButton"
			ret_button.focus_mode = Control.FOCUS_NONE
			if is_current_locale:
				new_btn.disabled = true
				ret_button.disabled = true
			else:
				ret_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			for theme_item in ["normal", "hover", "pressed", "disabled"]:
				new_btn.add_theme_stylebox_override(theme_item,
						new_btn.get_theme_stylebox("normal", "ContextButton"))
			var internal_hbox := HBoxContainer.new()
			new_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Unpressable.
			internal_hbox.add_theme_constant_override("separation", 6)
			new_btn.add_theme_color_override("icon_normal_color",
					ret_button.get_theme_color("icon_normal_color", "ContextButton"))
			var label_margin := MarginContainer.new()
			label_margin.add_theme_constant_override("margin_right",
					int(ret_button.get_theme_stylebox("normal").content_margin_right))
			var label := Label.new()
			label.text = percentage
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			var shortcut_text_color := ThemeUtils.common_subtle_text_color
			if is_current_locale:
				shortcut_text_color.a *= 0.75
			label.add_theme_color_override("font_color", shortcut_text_color)
			label.add_theme_font_size_override("font_size",
					new_btn.get_theme_font_size("font_size"))
			
			ret_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			internal_hbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
			label_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.size_flags_horizontal = Control.SIZE_FILL
			internal_hbox.add_child(new_btn)
			label_margin.add_child(label)
			internal_hbox.add_child(label_margin)
			ret_button.add_child(internal_hbox)
			ret_button.pressed.connect(_on_language_chosen.bind(lang))
			ret_button.pressed.connect(HandlerGUI.remove_popup_overlay)
			
			btn_arr.append(ret_button)
		else:
			var new_btn := ContextPopup.create_button(
					TranslationServer.get_locale_name(lang) + " (" + lang.to_upper() + ")",
					_on_language_chosen.bind(lang), lang == TranslationServer.get_locale())
			btn_arr.append(new_btn)
	
	var lang_popup := ContextPopup.new()
	lang_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(lang_popup, lang_button.get_global_rect(), get_viewport())

func _on_language_chosen(locale: String) -> void:
	GlobalSettings.modify_setting("language", locale)
	update_language_button()

func update_language_button() -> void:
	lang_button.text = TranslationServer.translate("Language") + ": " +\
			TranslationServer.get_locale().to_upper()


# Palette tab helpers.

func add_palette() -> void:
	for palette in GlobalSettings.savedata.palettes:
		# If there's an unnamed pallete, don't add a new one (there'll be a name clash).
		if palette.title.is_empty():
			return
	
	GlobalSettings.savedata.palettes.append(ColorPalette.new())
	GlobalSettings.save()
	rebuild_color_palettes()

func rebuild_color_palettes() -> void:
	var palette_container := content_container.get_child(-1)
	for palette_config in palette_container.get_children():
		palette_config.queue_free()
	for palette in GlobalSettings.savedata.palettes:
		var palette_config := PaletteConfigWidget.instantiate()
		palette_container.add_child(palette_config)
		palette_config.assign_palette(palette)
		palette_config.layout_changed.connect(rebuild_color_palettes)
	# Add the button for adding a new palette.
	var add_palette_button := Button.new()
	add_palette_button.theme_type_variation = "TranslucentButton"
	add_palette_button.icon = plus_icon
	add_palette_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_palette_button.focus_mode = Control.FOCUS_NONE
	add_palette_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	palette_container.add_child(add_palette_button)
	add_palette_button.pressed.connect(add_palette)


func add_formatter() -> void:
	for formatter in GlobalSettings.savedata.formatters:
		# If there's an unnamed formatter, don't add a new one (there'll be a name clash).
		if formatter.title.is_empty():
			return
	
	GlobalSettings.savedata.formatters.append(Formatter.new())
	GlobalSettings.save()
	rebuild_formatters()

func rebuild_formatters() -> void:
	var formatter_container := content_container.get_child(-1)
	for formatter_config in formatter_container.get_children():
		formatter_config.queue_free()
	
	var formatters: Dictionary
	for formatter in GlobalSettings.savedata.formatters:
		formatters[formatter.title] = formatter
		if not formatter.changed.is_connected(rebuild_formatters):
			formatter.changed.connect(rebuild_formatters)
	# TODO Do I need to do this...
	var formatter_names := PackedStringArray()
	for formatter_name in formatters.keys():
		formatter_names.append(formatter_name)
	
	for context in [["editor_formatter", TranslationServer.translate("Editor formatter")],
	["export_formatter", TranslationServer.translate("Export formatter")]]:
		var frame := ProfileFrame.instantiate()
		frame.text = context[1]
		frame.getter = func(): return GlobalSettings.savedata.get(context[0]).title
		frame.setter = func(p): GlobalSettings.modify_setting(context[0], formatters[p] if\
				formatters.has(p) else formatters[formatters.keys()[0]])
		frame.mouse_entered.connect(show_advice.bind(current_setup_setting))
		frame.mouse_exited.connect(hide_advice.bind(current_setup_setting))
		formatter_container.add_child(frame)
		frame.dropdown.values = formatter_names
	
	for formatter in GlobalSettings.savedata.formatters:
		var formatter_config := FormatterConfigWidget.instantiate()
		formatter_config.current_formatter = formatter
		formatter_container.add_child(formatter_config)
		formatter_config.layout_changed.connect(rebuild_formatters)
	# Add the button for adding a new formatter.
	var add_formatter_button := Button.new()
	add_formatter_button.theme_type_variation = "TranslucentButton"
	add_formatter_button.icon = plus_icon
	add_formatter_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_formatter_button.focus_mode = Control.FOCUS_NONE
	add_formatter_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	formatter_container.add_child(add_formatter_button)
	add_formatter_button.pressed.connect(add_formatter)

func set_formatter(formatter_purpose: String, formatter_name: String) -> void:
	var new_formatter: Formatter
	for formatter in GlobalSettings.savedata.formatters:
		if formatter.title == formatter_name:
			new_formatter = formatter
			break
	if is_instance_valid(new_formatter):
		GlobalSettings.modify_setting(formatter_purpose, new_formatter)


var shortcut_tab_names := ["file", "edit", "view", "tool", "help"]

func get_translated_shortcut_tab(tab_idx: String) -> String:
	match tab_idx:
		"file": return TranslationServer.translate("File")
		"edit": return TranslationServer.translate("Edit")
		"view": return TranslationServer.translate("View")
		"tool": return TranslationServer.translate("Tool")
		"help": return TranslationServer.translate("Help")
		_: return ""


func show_keybinds(category: String):
	var keybinds_container := content_container.get_child(-1).get_child(-1)
	for child in keybinds_container.get_children():
		child.queue_free()
	
	for action in ShortcutUtils.get_keybinds(category):
		var keybind_config := ShortcutConfigWidget.instantiate() if\
				ShortcutUtils.is_keybind_modifiable(action) else\
				ShortcutShowcaseWidget.instantiate()
		
		keybinds_container.add_child(keybind_config)
		keybind_config.label.text = TranslationUtils.get_shortcut_description(action)
		keybind_config.setup(action)
