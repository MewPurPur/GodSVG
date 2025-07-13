extends PanelContainer

const PaletteConfigWidgetScene = preload("res://src/ui_widgets/palette_config.tscn")
const ShortcutConfigWidgetScene = preload("res://src/ui_widgets/setting_shortcut.tscn")
const ShortcutShowcaseWidgetScene = preload("res://src/ui_widgets/presented_shortcut.tscn")
const SettingFrameScene = preload("res://src/ui_widgets/setting_frame.tscn")
const ProfileFrameScene = preload("res://src/ui_widgets/profile_frame.tscn")

const plus_icon = preload("res://assets/icons/Plus.svg")
const import_icon = preload("res://assets/icons/Import.svg")
const reset_icon = preload("res://assets/icons/Reload.svg")

@onready var lang_button: Button = $VBoxContainer/Language
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var content_container: MarginContainer = %ScrollContainer/ContentContainer
@onready var tabs: VBoxContainer = %Tabs
@onready var close_button: Button = $VBoxContainer/CloseButton
@onready var advice_panel: PanelContainer = $VBoxContainer/AdvicePanel
@onready var advice_label: Label = $VBoxContainer/AdvicePanel/AdviceLabel

var focused_tab := ""
var current_setup_setting := ""
var current_setup_resource: ConfigResource
var setting_container: VBoxContainer
var advice: Dictionary[String, String] = {}

func _ready() -> void:
	close_button.pressed.connect(queue_free)
	Configs.language_changed.connect(setup_everything)
	
	scroll_container.get_v_scroll_bar().visibility_changed.connect(adjust_right_margin)
	adjust_right_margin()
	
	update_language_button()
	update_close_button()
	setup_tabs()
	tabs.get_child(0).button_pressed = true
	Configs.theme_changed.connect(update_theme)
	update_theme()

func update_theme() -> void:
	var stylebox := ThemeDB.get_default_theme().get_stylebox("panel", theme_type_variation).duplicate()
	stylebox.content_margin_top += 4.0
	add_theme_stylebox_override("panel", stylebox)

func adjust_right_margin() -> void:
	var scrollbar := scroll_container.get_v_scroll_bar()
	content_container.add_theme_constant_override("margin_right",
			2 if scrollbar.visible else int(2 + scrollbar.size.x))

func setup_tabs() -> void:
	for tab in tabs.get_children():
		tab.queue_free()
	var button_group := ButtonGroup.new()
	add_tab("formatting", Translator.translate("Formatting"), button_group)
	add_tab("palettes", Translator.translate("Palettes"), button_group)
	add_tab("shortcuts", Translator.translate("Shortcuts"), button_group)
	add_tab("theming", Translator.translate("Theming"), button_group)
	add_tab("tab_bar", Translator.translate("Tab bar"), button_group)
	add_tab("other", Translator.translate("Other"), button_group)

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
	update_language_button()
	setup_tabs()
	setup_content()
	update_close_button()

func update_close_button() -> void:
	close_button.text = Translator.translate("Close")

func _on_tab_toggled(toggled_on: bool, tab_name: String) -> void:
	if toggled_on and focused_tab != tab_name:
		focused_tab = tab_name
		setup_content()

func setup_content(reset_scroll := true) -> void:
	if reset_scroll:
		scroll_container.scroll_vertical = 0
	
	for child in content_container.get_children():
		child.queue_free()
	
	match focused_tab:
		"formatting":
			advice_panel.hide()
			var vbox := VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox.add_theme_constant_override("separation", 6)
			content_container.add_child(vbox)
			var categories := HFlowContainer.new()
			categories.alignment = FlowContainer.ALIGNMENT_CENTER
			var button_group := ButtonGroup.new()
			for tab_idx in formatter_tab_names:
				var btn := Button.new()
				btn.toggle_mode = true
				btn.button_group = button_group
				btn.pressed.connect(show_formatter.bind(tab_idx))
				btn.text = get_translated_formatter_tab(tab_idx)
				btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				btn.focus_mode = Control.FOCUS_NONE
				btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
				categories.add_child(btn)
			vbox.add_child(categories)
			create_setting_container()
			vbox.add_child(setting_container)
			categories.get_child(0).button_pressed = true
			categories.get_child(0).pressed.emit()
		"palettes":
			advice_panel.hide()
			var vbox := VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content_container.add_child(vbox)
			rebuild_palettes()
		"shortcuts":
			advice_panel.hide()
			var vbox := VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox.add_theme_constant_override("separation", 6)
			content_container.add_child(vbox)
			var categories := HFlowContainer.new()
			var button_group := ButtonGroup.new()
			for tab_idx in shortcut_tab_names:
				var btn := Button.new()
				btn.toggle_mode = true
				btn.button_group = button_group
				btn.pressed.connect(show_shortcuts.bind(tab_idx))
				btn.text = get_translated_shortcut_tab(tab_idx)
				btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				btn.focus_mode = Control.FOCUS_NONE
				btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
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
			create_setting_container()
			content_container.add_child(setting_container)
			
			current_setup_resource = Configs.savedata
			
			current_setup_setting = "theme_preset"
			add_profile_picker(Translator.translate("Theme preset"),
					current_setup_resource.reset_theme_items_to_default,
					SaveData.ThemePreset.size(), SaveData.get_theme_preset_value_text_map(),
					current_setup_resource.is_theming_default)
			
			add_section(Translator.translate("Primary theme colors"))
			current_setup_setting = "base_color"
			add_color_edit(Translator.translate("Base color"), false)
			current_setup_setting = "accent_color"
			add_color_edit(Translator.translate("Accent color"), false)
			
			add_section(Translator.translate("SVG Text colors"))
			current_setup_setting = "highlighter_preset"
			add_profile_picker(Translator.translate("Highlighter preset"),
					current_setup_resource.reset_highlighting_items_to_default,
					SaveData.HighlighterPreset.size(),
					SaveData.get_highlighter_preset_value_text_map(),
					current_setup_resource.is_highlighting_default)
			current_setup_setting = "highlighting_symbol_color"
			add_color_edit(Translator.translate("Symbol color"))
			current_setup_setting = "highlighting_element_color"
			add_color_edit(Translator.translate("Element color"))
			current_setup_setting = "highlighting_attribute_color"
			add_color_edit(Translator.translate("Attribute color"))
			current_setup_setting = "highlighting_string_color"
			add_color_edit(Translator.translate("String color"))
			current_setup_setting = "highlighting_comment_color"
			add_color_edit(Translator.translate("Comment color"))
			current_setup_setting = "highlighting_text_color"
			add_color_edit(Translator.translate("Text color"))
			current_setup_setting = "highlighting_cdata_color"
			add_color_edit(Translator.translate("CDATA color"))
			current_setup_setting = "highlighting_error_color"
			add_color_edit(Translator.translate("Error color"))
			
			add_section(Translator.translate("Handles"))
			current_setup_setting = "handle_size"
			add_number_dropdown(Translator.translate("Size"),
					[0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0], false, false,
					SaveData.HANDLE_SIZE_MIN, SaveData.HANDLE_SIZE_MAX)
			current_setup_setting = "handle_inner_color"
			add_color_edit(Translator.translate("Inside color"), false)
			current_setup_setting = "handle_color"
			add_color_edit(Translator.translate("Normal color"), false)
			current_setup_setting = "handle_hovered_color"
			add_color_edit(Translator.translate("Hovered color"), false)
			current_setup_setting = "handle_selected_color"
			add_color_edit(Translator.translate("Selected color"), false)
			current_setup_setting = "handle_hovered_selected_color"
			add_color_edit(Translator.translate("Hovered selected color"), false)
			
			add_section(Translator.translate("Selection rectangle"))
			current_setup_setting = "selection_rectangle_speed"
			add_number_dropdown(Translator.translate("Speed"),
					[0.0, 10.0, 20.0, 30.0, 50.0, 80.0, 130.0], false, false,
					-SaveData.MAX_SELECTION_RECTANGLE_SPEED,
					SaveData.MAX_SELECTION_RECTANGLE_SPEED)
			current_setup_setting = "selection_rectangle_width"
			add_number_dropdown(Translator.translate("Width"),
					[1.0, 2.0, 3.0, 4.0], false, false, 1.0,
					SaveData.MAX_SELECTION_RECTANGLE_WIDTH)
			current_setup_setting = "selection_rectangle_dash_length"
			add_number_dropdown(Translator.translate("Dash length"),
					[5.0, 10.0, 15.0, 20.0], false, false, 1.0,
					SaveData.MAX_SELECTION_RECTANGLE_DASH_LENGTH)
			current_setup_setting = "selection_rectangle_color1"
			add_color_edit(Translator.translate("Color {index}").format({"index": "1"}))
			current_setup_setting = "selection_rectangle_color2"
			add_color_edit(Translator.translate("Color {index}").format({"index": "2"}))
			
			add_section(Translator.translate("Basic colors"))
			current_setup_setting = "canvas_color"
			add_color_edit(Translator.translate("Canvas color"), false)
			current_setup_setting = "grid_color"
			add_color_edit(Translator.translate("Grid color"), false)
			current_setup_setting = "basic_color_valid"
			add_color_edit(Translator.translate("Valid color"))
			current_setup_setting = "basic_color_error"
			add_color_edit(Translator.translate("Error color"))
			current_setup_setting = "basic_color_warning"
			add_color_edit(Translator.translate("Warning color"))
		"tab_bar":
			advice_panel.show()
			create_setting_container()
			content_container.add_child(setting_container)
			current_setup_resource = Configs.savedata
			
			add_section(Translator.translate("Input"))
			current_setup_setting = "tab_mmb_close"
			add_checkbox(Translator.translate("Close tabs with middle mouse button"))
			add_advice(Translator.translate("If turned on, clicking on a tab with the middle mouse button closes the tab. If turned off, it focuses the tab instead."))
		"other":
			advice_panel.show()
			create_setting_container()
			content_container.add_child(setting_container)
			current_setup_resource = Configs.savedata
			
			add_section(Translator.translate("Input"))
			current_setup_setting = "invert_zoom"
			add_checkbox(Translator.translate("Invert zoom direction"))
			add_advice(Translator.translate("Swaps the scroll directions for zooming in and zooming out."))
			current_setup_setting = "wraparound_panning"
			var wraparound_panning := add_checkbox(Translator.translate("Wrap-around panning"))
			add_advice(Translator.translate("Warps the cursor to the opposite side whenever it reaches a viewport boundary while panning."))
			current_setup_setting = "use_ctrl_for_zoom"
			add_checkbox(Translator.translate("Use CTRL for zooming"))
			add_advice(Translator.translate("If turned on, scrolling pans the view. To zoom, hold CTRL while scrolling."))
			
			add_section(Translator.translate("Display"))
			# Prepare parameters for the UI scale setting.
			var usable_screen_size := HandlerGUI.get_usable_rect()
			var min_ui_scale := HandlerGUI.get_min_ui_scale(usable_screen_size)
			var max_ui_scale := HandlerGUI.get_max_ui_scale(usable_screen_size)
			var dropdown_values := [SaveData.ScalingApproach.AUTO]
			if min_ui_scale <= 0.75 and 0.75 <= max_ui_scale:
				dropdown_values.append(SaveData.ScalingApproach.CONSTANT_075)
			if min_ui_scale <= 1.0 and 1.0 <= max_ui_scale:
				dropdown_values.append(SaveData.ScalingApproach.CONSTANT_100)
			if min_ui_scale <= 1.25 and 1.25 <= max_ui_scale:
				dropdown_values.append(SaveData.ScalingApproach.CONSTANT_125)
			if min_ui_scale <= 1.5 and 1.5 <= max_ui_scale:
				dropdown_values.append(SaveData.ScalingApproach.CONSTANT_150)
			if min_ui_scale <= 1.75 and 1.75 <= max_ui_scale:
				dropdown_values.append(SaveData.ScalingApproach.CONSTANT_175)
			if min_ui_scale <= 2.0 and 2.0 <= max_ui_scale:
				dropdown_values.append(SaveData.ScalingApproach.CONSTANT_200)
			if min_ui_scale <= 2.5 and 2.5 <= max_ui_scale:
				dropdown_values.append(SaveData.ScalingApproach.CONSTANT_250)
			if min_ui_scale <= 3.0 and 3.0 <= max_ui_scale:
				dropdown_values.append(SaveData.ScalingApproach.CONSTANT_300)
			if min_ui_scale <= 4.0 and 4.0 <= max_ui_scale:
				dropdown_values.append(SaveData.ScalingApproach.CONSTANT_400)
			dropdown_values.append(SaveData.ScalingApproach.MAX)
			# Dictionary[SaveData.ScalingApproach, String]
			var dropdown_map: Dictionary = {
				SaveData.ScalingApproach.AUTO: "Auto (%d%%)" % (HandlerGUI.get_auto_ui_scale() * 100),
				SaveData.ScalingApproach.CONSTANT_075: "75%",
				SaveData.ScalingApproach.CONSTANT_100: "100%",
				SaveData.ScalingApproach.CONSTANT_125: "125%",
				SaveData.ScalingApproach.CONSTANT_150: "150%",
				SaveData.ScalingApproach.CONSTANT_175: "175%",
				SaveData.ScalingApproach.CONSTANT_200: "200%",
				SaveData.ScalingApproach.CONSTANT_250: "250%",
				SaveData.ScalingApproach.CONSTANT_300: "300%",
				SaveData.ScalingApproach.CONSTANT_400: "400%",
				SaveData.ScalingApproach.MAX: "Max (%d%%)" % (max_ui_scale * 100),
			}
			
			current_setup_setting = "ui_scale"
			add_dropdown(Translator.translate("UI scale"), dropdown_values, dropdown_map)
			add_advice(Translator.translate("Determines the scale factor for the interface."))
			
			current_setup_setting = "vsync"
			add_checkbox(Translator.translate("V-Sync"))
			add_advice(Translator.translate("Synchronizes graphics rendering with display refresh rate to prevent screen tearing artifacts. May increase input lag slightly."))
			
			current_setup_setting = "uncapped_framerate"
			add_checkbox(Translator.translate("Uncapped framerate"),
					current_setup_resource.vsync)
			add_advice(Translator.translate("Determines if frames are rendered as fast as possible (may increase power consumption and heat)."))
			
			current_setup_setting = "max_fps"
			add_number_dropdown(Translator.translate("Custom maximum FPS"),
					[30, 60, 90, 120, 144, 240, 360], true, false, SaveData.MAX_FPS_MIN,
					SaveData.MAX_FPS_MAX, current_setup_resource.uncapped_framerate)
			add_advice(Translator.translate("If the framerate is capped, this value determines the maximum number of frames per second."))
			
			add_section(Translator.translate("Miscellaneous"))
			current_setup_setting = "use_native_file_dialog"
			var use_native_file_dialog := add_checkbox(Translator.translate("Use native file dialog"))
			add_advice(Translator.translate("If turned on, uses your operating system's native file dialog. If turned off, uses GodSVG's built-in file dialog."))
			current_setup_setting = "use_filename_for_window_title"
			add_checkbox(Translator.translate("Sync window title to file name"))
			add_advice(Translator.translate("If turned off, the window title remains as \"GodSVG\" without including the current file."))
			
			# Disable mouse wrap if not available.
			if not DisplayServer.has_feature(DisplayServer.FEATURE_MOUSE_WARP):
				wraparound_panning.permanent_disable_checkbox(false)
			# Disable fallback file dialog on web, and native file dialog if not available.
			if OS.has_feature("web"):
				use_native_file_dialog.permanent_disable_checkbox(true)
			elif not DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
				use_native_file_dialog.permanent_disable_checkbox(false)
	
	# Update hover.
	HandlerGUI.throw_mouse_motion_event()


func add_section(section_name: String) -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 15)
	label.theme_type_variation = "TitleLabel"
	label.text = section_name
	vbox.add_child(label)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 2
	vbox.add_child(spacer)
	setting_container.add_child(vbox)

func add_profile_picker(text: String, application_callback: Callable, profile_count: int,
value_text_map: Dictionary, disabled_check_callback: Callable) -> void:
	var bind := current_setup_setting
	var frame := ProfileFrameScene.instantiate()
	frame.setup_dropdown(range(profile_count), value_text_map)
	frame.getter = current_setup_resource.get.bind(bind)
	var resource_permanent_ref := current_setup_resource
	frame.setter = func(p: Variant) -> void:
			resource_permanent_ref.set(bind, p)
	frame.text = text
	frame.disabled_check_callback = disabled_check_callback
	frame.value_changed.connect.call_deferred(setup_content.bind(false))
	frame.defaults_applied.connect(application_callback)
	frame.defaults_applied.connect(setup_content.bind(false))
	add_frame(frame)
	
	resource_permanent_ref.changed_deferred.connect(frame.button_update_disabled)
	frame.tree_exited.connect(resource_permanent_ref.changed_deferred.disconnect.bind(
			frame.button_update_disabled), CONNECT_ONE_SHOT)
	

func add_checkbox(text: String, dim_text := false) -> Control:
	var frame := SettingFrameScene.instantiate()
	frame.dim_text = dim_text
	frame.text = text
	setup_frame(frame)
	frame.setup_checkbox()
	add_frame(frame)
	# Some checkboxes need to update the dimness of the text of other settings.
	# There's nothing persistent in checkboxes, so it's safe to just rebuild the content
	# for them, specifically.
	frame.value_changed.connect(setup_content.bind(false))
	return frame

# TODO Typed Dictionary wonkiness
func add_dropdown(text: String, values: Array[Variant],
value_text_map: Dictionary) -> Control:  # Dictionary[Variant, String]
	var frame := SettingFrameScene.instantiate()
	frame.text = text
	setup_frame(frame)
	frame.setup_dropdown(values, value_text_map)
	add_frame(frame)
	return frame

func add_number_dropdown(text: String, values: Array[float], is_integer := false,
restricted := true, min_value := -INF, max_value := INF, dim_text := false) -> Control:
	var frame := SettingFrameScene.instantiate()
	frame.dim_text = dim_text
	frame.text = text
	setup_frame(frame)
	frame.setup_number_dropdown(values, is_integer, restricted, min_value, max_value)
	add_frame(frame)
	return frame

func add_color_edit(text: String, enable_alpha := true) -> Control:
	var frame := SettingFrameScene.instantiate()
	frame.text = text
	setup_frame(frame)
	frame.setup_color(enable_alpha)
	add_frame(frame)
	return frame

func setup_frame(frame: Control) -> void:
	var bind := current_setup_setting
	frame.getter = current_setup_resource.get.bind(bind)
	frame.setter = func(p: Variant) -> void: current_setup_resource.set(bind, p)
	frame.default = current_setup_resource.get_setting_default(current_setup_setting)
	frame.mouse_entered.connect(show_advice.bind(current_setup_setting))
	frame.mouse_exited.connect(hide_advice.bind(current_setup_setting))

func add_frame(frame: Control) -> void:
	if setting_container.get_child_count() > 0:
		setting_container.get_child(-1).add_child(frame)
	else:
		setting_container.add_child(frame)

func add_advice(text: String) -> void:
	advice[current_setup_setting] = text


func show_advice(setting: String) -> void:
	if advice.has(setting):
		advice_label.text = advice[setting]
		advice_label.remove_theme_font_size_override("font_size")
		var advice_font_size := get_theme_font_size("font_size", "Label")
		while advice_label.get_line_count() > 2:
			advice_font_size -= 1
			advice_label.add_theme_font_size_override("font_size", advice_font_size)

func hide_advice(setting: String) -> void:
	if advice.has(setting) and advice_label.text == advice[setting]:
		advice_label.text = ""


func _on_language_pressed() -> void:
	var strings_count := TranslationServer.get_translation_object("en").get_message_count()
	
	var btn_arr: Array[Button] = []
	for locale in TranslationServer.get_loaded_locales():
		var is_current_locale := (locale == TranslationServer.get_locale())
		
		# Translation percentages.
		if locale != "en":
			var translation_obj := TranslationServer.get_translation_object(locale)
			var translated_count := translation_obj.get_message_count() -\
					translation_obj.get_translated_message_list().count("")
			
			btn_arr.append(ContextPopup.create_button(
					TranslationUtils.get_locale_display(locale),
					_on_language_chosen.bind(locale), is_current_locale,
					null, Utils.num_simple(translated_count * 100.0 / strings_count, 1) + "%"))
		else:
			btn_arr.append(ContextPopup.create_button(
					TranslationUtils.get_locale_display(locale),
					_on_language_chosen.bind(locale), is_current_locale))
	
	var lang_popup := ContextPopup.new()
	lang_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(lang_popup, lang_button.get_global_rect(),
			get_viewport())

func _on_language_chosen(locale: String) -> void:
	Configs.savedata.language = locale

func update_language_button() -> void:
	lang_button.text = Translator.translate("Language") + ": " +\
			TranslationUtils.get_locale_string(TranslationServer.get_locale())


# Palette tab helpers.

func _popup_xml_palette_options(palette_xml_button: Button) -> void:
	var btn_arr: Array[Button] = []
	btn_arr.append(ContextPopup.create_button(Translator.translate("Import XML"),
			add_imported_palette, false, load("res://assets/icons/Import.svg")))
	btn_arr.append(ContextPopup.create_button(Translator.translate("Paste XML"),
			add_pasted_palette, !Palette.is_valid_palette(Utils.get_clipboard_web_safe()),
			load("res://assets/icons/Paste.svg")))
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect_center(context_popup, palette_xml_button.get_global_rect(),
			get_viewport())


func add_empty_palette() -> void:
	_shared_add_palette_logic(Palette.new())

func add_pasted_palette() -> void:
	_shared_add_palettes_logic(Palette.text_to_palettes(Utils.get_clipboard_web_safe()))

func add_imported_palette() -> void:
	FileUtils.open_xml_import_dialog(_on_import_palette_finished)

func _on_import_palette_finished(file_text: String) -> void:
	_shared_add_palettes_logic(Palette.text_to_palettes(file_text))

func _shared_add_palettes_logic(palettes: Array[Palette]) -> void:
	if not palettes.is_empty():
		_shared_add_palette_logic(palettes[0])

func _shared_add_palette_logic(palette: Palette) -> void:
	Configs.savedata.add_palette(palette)
	rebuild_palettes()


func rebuild_palettes() -> void:
	var palette_container := content_container.get_child(-1)
	for palette_config in palette_container.get_children():
		palette_config.queue_free()
	for palette in Configs.savedata.get_palettes():
		var palette_config := PaletteConfigWidgetScene.instantiate()
		palette_container.add_child(palette_config)
		palette_config.assign_palette(palette)
		palette_config.layout_changed.connect(rebuild_palettes)
	
	# Add the buttons for adding a new palette.
	var spacer := Control.new()
	palette_container.add_child(spacer)
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	palette_container.add_child(hbox)
	
	var add_palette_button := Button.new()
	add_palette_button.theme_type_variation = "TranslucentButton"
	add_palette_button.icon = plus_icon
	add_palette_button.text = Translator.translate("New palette")
	add_palette_button.focus_mode = Control.FOCUS_NONE
	add_palette_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_palette_button.pressed.connect(add_empty_palette)
	hbox.add_child(add_palette_button)
	
	var xml_palette_button := Button.new()
	xml_palette_button.theme_type_variation = "TranslucentButton"
	xml_palette_button.icon = import_icon
	xml_palette_button.text = Translator.translate("New palette from XML")
	xml_palette_button.focus_mode = Control.FOCUS_NONE
	xml_palette_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hbox.add_child(xml_palette_button)
	xml_palette_button.pressed.connect(_popup_xml_palette_options.bind(xml_palette_button))


var shortcut_tab_names := PackedStringArray(["file", "edit", "view", "tool", "help"])
var formatter_tab_names := PackedStringArray(["editor", "export"])

func get_translated_formatter_tab(tab_idx: String) -> String:
	match tab_idx:
		"editor": return Translator.translate("Editor formatter")
		"export": return Translator.translate("Export formatter")
	return ""

func get_translated_shortcut_tab(tab_idx: String) -> String:
	match tab_idx:
		"file": return Translator.translate("File")
		"edit": return Translator.translate("Edit")
		"view": return Translator.translate("View")
		"tool": return Translator.translate("Tool")
		"help": return Translator.translate("Help")
	return ""


func show_formatter(category: String) -> void:
	for child in setting_container.get_children():
		child.queue_free()
	
	match category:
		"editor": current_setup_resource = Configs.savedata.editor_formatter
		"export": current_setup_resource = Configs.savedata.export_formatter
	
	current_setup_setting = "preset"
	add_profile_picker(Translator.translate("Preset"),
			current_setup_resource.reset_to_default, Formatter.Preset.size(),
			Formatter.get_preset_value_text_map(), current_setup_resource.is_everything_default)
	
	add_section("XML")
	current_setup_setting = "xml_keep_comments"
	add_checkbox(Translator.translate("Keep comments"))
	current_setup_setting = "xml_keep_unrecognized"
	add_checkbox(Translator.translate("Keep unrecognized XML structures"))
	current_setup_setting = "xml_add_trailing_newline"
	add_checkbox(Translator.translate("Add trailing newline"))
	current_setup_setting = "xml_shorthand_tags"
	add_dropdown(Translator.translate("Use shorthand tag syntax"),
			range(Formatter.ShorthandTags.size()),
			Formatter.get_shorthand_tags_value_text_map())
	current_setup_setting = "xml_shorthand_tags_space_out_slash"
	add_checkbox(Translator.translate("Space out the slash of shorthand tags"))
	current_setup_setting = "xml_pretty_formatting"
	add_checkbox(Translator.translate("Use pretty formatting"))
	current_setup_setting = "xml_indentation_use_spaces"
	add_checkbox(Translator.translate("Use spaces instead of tabs"),
			not current_setup_resource.xml_pretty_formatting)
	current_setup_setting = "xml_indentation_spaces"
	add_number_dropdown(Translator.translate("Number of indentation spaces"),
			[2, 3, 4, 6, 8], true, false, Formatter.INDENTS_MIN, Formatter.INDENTS_MAX,
			not (current_setup_resource.xml_pretty_formatting and\
			current_setup_resource.xml_indentation_use_spaces))
	
	add_section(Translator.translate("Numbers"))
	current_setup_setting = "number_remove_leading_zero"
	add_checkbox(Translator.translate("Remove leading zero"))
	current_setup_setting = "number_use_exponent_if_shorter"
	add_checkbox(Translator.translate("Use exponential when shorter"))
	
	add_section(Translator.translate("Colors"))
	current_setup_setting = "color_use_named_colors"
	add_dropdown(Translator.translate("Use named colors"),
			range(Formatter.NamedColorUse.size()),
			Formatter.get_named_color_use_value_text_map())
	current_setup_setting = "color_primary_syntax"
	add_dropdown(Translator.translate("Primary syntax"),
			range(Formatter.PrimaryColorSyntax.size()),
			Formatter.get_primary_color_syntax_value_text_map())
	current_setup_setting = "color_capital_hex"
	add_checkbox(Translator.translate("Capitalize hexadecimal letters"),
			current_setup_resource.color_primary_syntax == Formatter.PrimaryColorSyntax.RGB)
	
	add_section(Translator.translate("Pathdata"))
	current_setup_setting = "pathdata_compress_numbers"
	add_checkbox(Translator.translate("Compress numbers"))
	current_setup_setting = "pathdata_minimize_spacing"
	add_checkbox(Translator.translate("Minimize spacing"))
	current_setup_setting = "pathdata_remove_spacing_after_flags"
	add_checkbox(Translator.translate("Remove spacing after flags"))
	current_setup_setting = "pathdata_remove_consecutive_commands"
	add_checkbox(Translator.translate("Remove consecutive commands"))
	
	add_section(Translator.translate("Transform lists"))
	current_setup_setting = "transform_list_compress_numbers"
	add_checkbox(Translator.translate("Compress numbers"))
	current_setup_setting = "transform_list_minimize_spacing"
	add_checkbox(Translator.translate("Minimize spacing"))
	current_setup_setting = "transform_list_remove_unnecessary_params"
	add_checkbox(Translator.translate("Remove unnecessary parameters"))


func show_shortcuts(category: String) -> void:
	var shortcuts_container := content_container.get_child(-1).get_child(-1)
	for child in shortcuts_container.get_children():
		child.queue_free()
	
	for action in ShortcutUtils.get_actions(category):
		var shortcut_config := ShortcutConfigWidgetScene.instantiate() if\
				ShortcutUtils.is_action_modifiable(action) else\
				ShortcutShowcaseWidgetScene.instantiate()
		
		shortcuts_container.add_child(shortcut_config)
		shortcut_config.label.text = TranslationUtils.get_action_description(action)
		shortcut_config.setup(action)

func create_setting_container() -> void:
	setting_container = VBoxContainer.new()
	setting_container.add_theme_constant_override("separation", 6)
	setting_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
