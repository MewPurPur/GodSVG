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
@onready var preview_panel: PanelContainer = $VBoxContainer/PreviewPanel

var focused_tab := ""
var current_setup_setting := ""
var current_setup_resource: ConfigResource
var setting_container: VBoxContainer

class SettingTextPreview:
	enum WarningType {NONE, NO_EFFECT_IN_CURRENT_CONFIGURATION, NOT_AVAILABLE_ON_PLATFORM}
	var text: String
	var warning: WarningType
	func _init(new_text: String, new_warning := WarningType.NONE) -> void:
		text = new_text
		warning = new_warning
	
	static func get_platform_availability_warning(bad_platforms_check: bool) -> WarningType:
		return WarningType.NOT_AVAILABLE_ON_PLATFORM if bad_platforms_check else WarningType.NONE
	
	static func get_no_effect_in_configuration_warning(configuration_check: bool) -> WarningType:
		return WarningType.NO_EFFECT_IN_CURRENT_CONFIGURATION if configuration_check else WarningType.NONE

class SettingCodePreview:
	var text: String
	func _init(new_text: String) -> void:
		text = new_text

class SettingFormatterPreview:
	var setting_bind: String
	var resource_bind: Formatter
	var root_element: ElementRoot
	var show_only_children: bool
	func _init(new_setting_bind: String, new_resource_bind: ConfigResource,
	new_root_element: ElementRoot, new_show_only_children := false) -> void:
		setting_bind = new_setting_bind
		resource_bind = new_resource_bind
		root_element = new_root_element
		show_only_children = new_show_only_children

var previews: Dictionary[String, RefCounted] = {}

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
	setup_content(false)
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
			preview_panel.show()
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
			var category_button: Button = categories.get_child(
					1 if current_setup_resource == Configs.savedata.export_formatter else 0)
			category_button.button_pressed = true
			category_button.pressed.emit()
		"palettes":
			preview_panel.hide()
			var vbox := VBoxContainer.new()
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content_container.add_child(vbox)
			rebuild_palettes()
		"shortcuts":
			preview_panel.hide()
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
			preview_panel.show()
			create_setting_container()
			content_container.add_child(setting_container)
			
			current_setup_resource = Configs.savedata
			
			current_setup_setting = "theme_preset"
			add_profile_picker(Translator.translate("Theme preset"),
					current_setup_resource.reset_theme_items_to_default,
					SaveData.ThemePreset.size(), SaveData.get_theme_preset_value_text_map(),
					current_setup_resource.is_theming_default)
			add_preview(SettingTextPreview.new(
					Translator.translate("Determines the default values of theming-related settings, including the highlighter preset.")))
			
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
			add_preview(SettingTextPreview.new(
					Translator.translate("Determines the default values of SVG highlighter settings.")))
			current_setup_setting = "highlighting_symbol_color"
			add_color_edit(Translator.translate("Symbol color"))
			add_preview(SettingCodePreview.new(
					"""<circle cx="6" cy="8" r="4" fill="gold" />"""))
			current_setup_setting = "highlighting_element_color"
			add_color_edit(Translator.translate("Element color"))
			add_preview(SettingCodePreview.new(
					"""<circle cx="6" cy="8" r="4" fill="gold" />"""))
			current_setup_setting = "highlighting_attribute_color"
			add_color_edit(Translator.translate("Attribute color"))
			add_preview(SettingCodePreview.new(
					"""<circle cx="6" cy="8" r="4" fill="gold" />"""))
			current_setup_setting = "highlighting_string_color"
			add_color_edit(Translator.translate("String color"))
			add_preview(SettingCodePreview.new(
					"""<circle cx="6" cy="8" r="4" fill="gold" />"""))
			current_setup_setting = "highlighting_comment_color"
			add_color_edit(Translator.translate("Comment color"))
			add_preview(SettingCodePreview.new(
					"""<!-- Comment --> <text> Basic text <![CDATA[ < > & " ' ]]> </text>"""))
			current_setup_setting = "highlighting_text_color"
			add_color_edit(Translator.translate("Text color"))
			add_preview(SettingCodePreview.new(
					"""<!-- Comment --> <text> Basic text <![CDATA[ < > & " ' ]]> </text>"""))
			current_setup_setting = "highlighting_cdata_color"
			add_color_edit(Translator.translate("CDATA color"))
			add_preview(SettingCodePreview.new(
					"""<!-- Comment --> <text> Basic text <![CDATA[ < > & " ' ]]> </text>"""))
			current_setup_setting = "highlighting_error_color"
			add_color_edit(Translator.translate("Error color"))
			add_preview(SettingCodePreview.new(
					"""<circle cx="6" cy="8" ==syntax error"""))
			
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
			preview_panel.show()
			create_setting_container()
			content_container.add_child(setting_container)
			current_setup_resource = Configs.savedata
			
			add_section(Translator.translate("Input"))
			current_setup_setting = "tab_mmb_close"
			add_checkbox(Translator.translate("Close tabs with middle mouse button"))
			add_preview(SettingTextPreview.new(
					Translator.translate("When enabled, clicking on a tab with the middle mouse button closes it instead of simply focusing it.")))
		"other":
			preview_panel.show()
			create_setting_container()
			content_container.add_child(setting_container)
			current_setup_resource = Configs.savedata
			
			add_section(Translator.translate("Input"))
			current_setup_setting = "invert_zoom"
			add_checkbox(Translator.translate("Invert zoom direction"))
			add_preview(SettingTextPreview.new(
					Translator.translate("Swaps the scroll directions for zooming in and zooming out.")))
			current_setup_setting = "wraparound_panning"
			var wraparound_panning := add_checkbox(Translator.translate("Wrap-around panning"))
			var wraparound_panning_forced_off := not DisplayServer.has_feature(DisplayServer.FEATURE_MOUSE_WARP)
			add_preview(SettingTextPreview.new(Translator.translate(
					"Warps the cursor to the opposite side whenever it reaches a viewport boundary while panning."),
					SettingTextPreview.get_platform_availability_warning(wraparound_panning_forced_off)))
			# Disable mouse wrap if not available.
			if wraparound_panning_forced_off:
				wraparound_panning.permanent_disable_checkbox(false)
			
			current_setup_setting = "use_ctrl_for_zoom"
			add_checkbox(Translator.translate("Use CTRL for zooming"))
			add_preview(SettingTextPreview.new(
					Translator.translate("When enabled, scrolling pans the view instead of zooming in. To zoom, hold CTRL while scrolling.")))
			
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
			add_preview(SettingTextPreview.new(
					Translator.translate("Determines the scale factor for the interface.")))
			
			current_setup_setting = "vsync"
			add_checkbox(Translator.translate("V-Sync"))
			add_preview(SettingTextPreview.new(
					Translator.translate("Synchronizes graphics rendering with display refresh rate to prevent screen tearing artifacts. May increase input lag slightly.")))
			
			current_setup_setting = "max_fps"
			add_fps_limit_dropdown(Translator.translate("Maximum FPS"))
			add_preview(SettingTextPreview.new(
					Translator.translate("Determines the maximum number of frames per second.")))
			
			current_setup_setting = "keep_screen_on"
			add_checkbox(Translator.translate("Keep Screen On"))
			add_preview(SettingTextPreview.new(
					Translator.translate("Keeps the screen on even after inactivity, so the screensaver does not take over.")))
			
			add_section(Translator.translate("Miscellaneous"))
			current_setup_setting = "use_native_file_dialog"
			var use_native_file_dialog := add_checkbox(Translator.translate("Use native file dialog"))
			var use_native_file_dialog_forced_on := OS.has_feature("web")
			var use_native_file_dialog_forced_off :=\
					(not DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE))
			add_preview(SettingTextPreview.new(Translator.translate(
					"When enabled, uses your operating system's native file dialog instead of GodSVG's built-in one."),
					SettingTextPreview.get_platform_availability_warning(
					use_native_file_dialog_forced_on or use_native_file_dialog_forced_off)))
			# Disable fallback file dialog on web, and native file dialog if not available.
			if use_native_file_dialog_forced_on:
				use_native_file_dialog.permanent_disable_checkbox(true)
			elif use_native_file_dialog_forced_off:
				use_native_file_dialog.permanent_disable_checkbox(false)
			
			
			current_setup_setting = "use_filename_for_window_title"
			add_checkbox(Translator.translate("Sync window title to file name"))
			add_preview(SettingTextPreview.new(
					Translator.translate("When enabled, adds the current file name after the \"GodSVG\" window title.")))
	
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
	frame.mouse_entered.connect(show_preview.bind(current_setup_setting))
	frame.mouse_exited.connect(hide_preview.bind(current_setup_setting))
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
	# There's no continuous editing with checkboxes, so it's safe to just rebuild
	# the content for them.
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
	# Some checkboxes need to update the dimness of the text of other settings.
	# There's no continuous editing with checkboxes, so it's safe to just rebuild
	# the content for them.
	frame.value_changed.connect(setup_content.bind(false))
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

func add_fps_limit_dropdown(text: String, dim_text := false) -> Control:
	var frame := SettingFrameScene.instantiate()
	frame.dim_text = dim_text
	frame.text = text
	setup_frame(frame)
	frame.setup_fps_limit_dropdown()
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
	frame.mouse_entered.connect(show_preview.bind(current_setup_setting))
	frame.mouse_exited.connect(hide_preview.bind(current_setup_setting))

func add_frame(frame: Control) -> void:
	if setting_container.get_child_count() > 0:
		setting_container.get_child(-1).add_child(frame)
	else:
		setting_container.add_child(frame)


func add_preview(preview: RefCounted) -> void:
	previews[current_setup_setting] = preview

func show_preview(setting: String) -> void:
	if previews.has(setting):
		var preview := previews[setting]
		if preview is SettingTextPreview:
			var has_warning: bool = (preview.warning != preview.WarningType.NONE)
			var margin_container := MarginContainer.new()
			margin_container.add_theme_constant_override("margin_left", 6)
			margin_container.add_theme_constant_override("margin_right", 6)
			margin_container.add_theme_constant_override("margin_top", 2)
			margin_container.add_theme_constant_override("margin_bottom", 4)
			var label := Label.new()
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			label.add_theme_constant_override("line_spacing", 2)
			label.text = preview.text
			var preview_font_size := get_theme_font_size("font_size", "Label")
			while label.get_line_count() >= (2 if has_warning else 3):
				preview_font_size -= 1
				label.add_theme_font_size_override("font_size", preview_font_size)
			if has_warning:
				var vbox := VBoxContainer.new()
				vbox.add_theme_constant_override("separation", 2)
				var no_effect_warning_label := Label.new()
				no_effect_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				no_effect_warning_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
				no_effect_warning_label.add_theme_constant_override("line_spacing", 2)
				no_effect_warning_label.add_theme_color_override("font_color",
						Configs.savedata.basic_color_warning)
				match preview.warning:
					preview.WarningType.NO_EFFECT_IN_CURRENT_CONFIGURATION:
						no_effect_warning_label.text = Translator.translate(
								"The setting has no effect in the current configuration.")
					preview.WarningType.NOT_AVAILABLE_ON_PLATFORM:
						no_effect_warning_label.text = Translator.translate(
								"The setting can't be changed on this platform.")
					_:
						no_effect_warning_label.text = ""
				while no_effect_warning_label.get_line_count() >= 2:
					preview_font_size -= 1
					no_effect_warning_label.add_theme_font_size_override("font_size",
							preview_font_size)
					label.add_theme_font_size_override("font_size", preview_font_size)
				if not preview.text.is_empty():
					vbox.add_child(label)
				vbox.add_child(no_effect_warning_label)
				margin_container.add_child(vbox)
			else:
				margin_container.add_child(label)
			preview_panel.add_child(margin_container)
		elif preview is SettingCodePreview:
			var code_preview := BetterTextEdit.new()
			code_preview.editable = false
			var update_highlighter := func() -> void:
					code_preview.syntax_highlighter = SVGHighlighter.new()
			code_preview.add_theme_color_override("font_readonly_color", Color.WHITE)
			
			var text_edit_default_stylebox := code_preview.get_theme_stylebox("normal")
			var empty_stylebox := StyleBoxEmpty.new()
			empty_stylebox.content_margin_left = text_edit_default_stylebox.content_margin_left
			empty_stylebox.content_margin_right = text_edit_default_stylebox.content_margin_right
			empty_stylebox.content_margin_top = text_edit_default_stylebox.content_margin_top
			empty_stylebox.content_margin_bottom = text_edit_default_stylebox.content_margin_bottom
			code_preview.add_theme_stylebox_override("normal", empty_stylebox)
			code_preview.add_theme_stylebox_override("read_only", empty_stylebox)
			code_preview.text = preview.text
			Configs.highlighting_colors_changed.connect(update_highlighter)
			code_preview.tree_exiting.connect(Configs.highlighting_colors_changed.disconnect.bind(
					update_highlighter), CONNECT_ONE_SHOT)
			update_highlighter.call()
			preview_panel.add_child(code_preview)
		elif preview is SettingFormatterPreview:
			var code_preview := BetterTextEdit.new()
			code_preview.editable = false
			
			var update_highlighter := func() -> void:
					code_preview.syntax_highlighter = SVGHighlighter.new()
			
			var update_text := func() -> void:
					if preview.show_only_children:
						code_preview.text = SVGParser.root_children_to_text(
								preview.root_element, preview.resource_bind)
					else:
						code_preview.text = SVGParser.root_to_text(
								preview.root_element, preview.resource_bind)
			
			code_preview.add_theme_color_override("font_readonly_color", Color.WHITE)
			var text_edit_default_stylebox := code_preview.get_theme_stylebox("normal")
			var empty_stylebox := StyleBoxEmpty.new()
			empty_stylebox.content_margin_left = text_edit_default_stylebox.content_margin_left
			empty_stylebox.content_margin_right = text_edit_default_stylebox.content_margin_right
			empty_stylebox.content_margin_top = text_edit_default_stylebox.content_margin_top
			empty_stylebox.content_margin_bottom = text_edit_default_stylebox.content_margin_bottom
			code_preview.add_theme_stylebox_override("normal", empty_stylebox)
			code_preview.add_theme_stylebox_override("read_only", empty_stylebox)
			Configs.highlighting_colors_changed.connect(update_highlighter)
			code_preview.tree_exiting.connect(Configs.highlighting_colors_changed.disconnect.bind(
					update_highlighter), CONNECT_ONE_SHOT)
			update_highlighter.call()
			preview.resource_bind.changed_deferred.connect(update_text)
			code_preview.tree_exiting.connect(preview.resource_bind.changed_deferred.disconnect.bind(
					update_text), CONNECT_ONE_SHOT)
			update_text.call()
			preview_panel.add_child(code_preview)
			# TODO Impressively, all this is necessary for scrollbars to work.
			# TextEdit is so damn janky.
			code_preview.hide()
			code_preview.show()
			await get_tree().process_frame
			await get_tree().process_frame
			if is_instance_valid(code_preview) and\
			not is_zero_approx(code_preview.get_v_scroll_bar().max_value):
				var tw := code_preview.create_tween().set_loops()
				tw.tween_interval(1.75)
				tw.tween_property(code_preview.get_v_scroll_bar(), ^"value",
						floorf(code_preview.get_v_scroll_bar().max_value -\
						code_preview.get_visible_line_count()), 0.5)
				tw.tween_interval(1.75)
				tw.tween_property(code_preview.get_v_scroll_bar(), ^"value", 0.0, 0.5)

func hide_preview(setting: String) -> void:
	if previews.has(setting):
		for child in preview_panel.get_children():
			child.queue_free()


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
		setting_container.remove_child(child)
		child.queue_free()
	
	match category:
		"editor": current_setup_resource = Configs.savedata.editor_formatter
		"export": current_setup_resource = Configs.savedata.export_formatter
	
	current_setup_setting = "preset"
	add_profile_picker(Translator.translate("Preset"),
			current_setup_resource.reset_to_default, Formatter.Preset.size(),
			Formatter.get_preset_value_text_map(), current_setup_resource.is_everything_default)
	add_preview(SettingTextPreview.new(
			Translator.translate("Determines the default values of the formatter configs.")))
	
	add_section("XML")
	current_setup_setting = "xml_keep_comments"
	add_checkbox(Translator.translate("Keep comments"))
	var xml_keep_comments_root_element := ElementRoot.new()
	xml_keep_comments_root_element.insert_child(0,
			BasicXNode.new(BasicXNode.NodeType.COMMENT, " Comment "))
	var xml_keep_comments_circle_element := ElementCircle.new()
	xml_keep_comments_circle_element.set_attribute("cx", 6)
	xml_keep_comments_circle_element.set_attribute("cy", 8)
	xml_keep_comments_circle_element.set_attribute("r", 4)
	xml_keep_comments_circle_element.set_attribute("fill", "gold")
	xml_keep_comments_root_element.insert_child(1, xml_keep_comments_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			xml_keep_comments_root_element, true))
	
	current_setup_setting = "xml_add_trailing_newline"
	add_checkbox(Translator.translate("Add trailing newline"))
	var xml_add_trailing_newline_root_element := ElementRoot.new()
	xml_add_trailing_newline_root_element.set_attribute("xmlns", "http://www.w3.org/2000/svg")
	xml_add_trailing_newline_root_element.set_attribute("width", "16")
	xml_add_trailing_newline_root_element.set_attribute("height", "16")
	var xml_add_trailing_newline_circle_element := ElementCircle.new()
	xml_add_trailing_newline_circle_element.set_attribute("cx", 6)
	xml_add_trailing_newline_circle_element.set_attribute("cy", 8)
	xml_add_trailing_newline_circle_element.set_attribute("r", 4)
	xml_add_trailing_newline_circle_element.set_attribute("fill", "gold")
	xml_add_trailing_newline_root_element.insert_child(0,
			xml_add_trailing_newline_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			xml_add_trailing_newline_root_element))
	
	current_setup_setting = "xml_shorthand_tags"
	add_dropdown(Translator.translate("Use shorthand tag syntax"),
			range(Formatter.ShorthandTags.size()),
			Formatter.get_shorthand_tags_value_text_map())
	var xml_shorthand_tags_root_element := ElementRoot.new()
	var xml_shorthand_tags_linear_gradient_element := ElementLinearGradient.new()
	xml_shorthand_tags_linear_gradient_element.set_attribute("id", "a")
	xml_shorthand_tags_linear_gradient_element.set_attribute("x1", 6)
	xml_shorthand_tags_linear_gradient_element.set_attribute("y1", 4)
	xml_shorthand_tags_linear_gradient_element.set_attribute("x2", 8)
	xml_shorthand_tags_linear_gradient_element.set_attribute("y2", 2)
	var xml_shorthand_tags_circle_element := ElementCircle.new()
	xml_shorthand_tags_circle_element.set_attribute("cx", 6)
	xml_shorthand_tags_circle_element.set_attribute("cy", 8)
	xml_shorthand_tags_circle_element.set_attribute("r", 4)
	xml_shorthand_tags_circle_element.set_attribute("fill", "url(#a)")
	xml_shorthand_tags_root_element.insert_child(0, xml_shorthand_tags_linear_gradient_element)
	xml_shorthand_tags_root_element.insert_child(1, xml_shorthand_tags_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			xml_shorthand_tags_root_element, true))
	
	current_setup_setting = "xml_shorthand_tags_space_out_slash"
	add_checkbox(Translator.translate("Space out the slash of shorthand tags"))
	var xml_shorthand_tags_space_out_slash_root_element := ElementRoot.new()
	var xml_shorthand_tags_space_out_slash_circle_element := ElementCircle.new()
	xml_shorthand_tags_space_out_slash_circle_element.set_attribute("cx", 6)
	xml_shorthand_tags_space_out_slash_circle_element.set_attribute("cy", 8)
	xml_shorthand_tags_space_out_slash_circle_element.set_attribute("r", 4)
	xml_shorthand_tags_space_out_slash_root_element.insert_child(0,
			xml_shorthand_tags_space_out_slash_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			xml_shorthand_tags_space_out_slash_root_element, true))
	
	current_setup_setting = "xml_pretty_formatting"
	add_checkbox(Translator.translate("Use pretty formatting"))
	var xml_pretty_formatting_root_element := ElementRoot.new()
	var xml_pretty_formatting_linear_gradient_element := ElementLinearGradient.new()
	xml_pretty_formatting_linear_gradient_element.set_attribute("id", "a")
	xml_pretty_formatting_linear_gradient_element.set_attribute("x1", 6)
	xml_pretty_formatting_linear_gradient_element.set_attribute("y1", 4)
	xml_pretty_formatting_linear_gradient_element.set_attribute("x2", 8)
	xml_pretty_formatting_linear_gradient_element.set_attribute("y2", 2)
	var xml_pretty_formatting_stop_1 := ElementStop.new()
	xml_pretty_formatting_stop_1.set_attribute("stop-color", "silver")
	xml_pretty_formatting_stop_1.set_attribute("offset", "0")
	var xml_pretty_formatting_stop_2 := ElementStop.new()
	xml_pretty_formatting_stop_2.set_attribute("stop-color", "gold")
	xml_pretty_formatting_stop_2.set_attribute("offset", "1")
	xml_pretty_formatting_linear_gradient_element.insert_child(0, xml_pretty_formatting_stop_1)
	xml_pretty_formatting_linear_gradient_element.insert_child(0, xml_pretty_formatting_stop_2)
	var xml_pretty_formatting_circle_element := ElementCircle.new()
	xml_pretty_formatting_circle_element.set_attribute("cx", 6)
	xml_pretty_formatting_circle_element.set_attribute("cy", 8)
	xml_pretty_formatting_circle_element.set_attribute("r", 4)
	xml_pretty_formatting_circle_element.set_attribute("fill", "url(#a)")
	xml_pretty_formatting_root_element.insert_child(0, xml_pretty_formatting_linear_gradient_element)
	xml_pretty_formatting_root_element.insert_child(1, xml_pretty_formatting_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			xml_pretty_formatting_root_element))
	
	current_setup_setting = "xml_indentation_use_spaces"
	add_checkbox(Translator.translate("Use spaces instead of tabs"),
			not current_setup_resource.xml_pretty_formatting)
	add_preview(SettingTextPreview.new(Translator.translate(
			"When enabled, uses several spaces instead of a single tab for indentation."),
			SettingTextPreview.get_no_effect_in_configuration_warning(
			current_setup_resource.xml_pretty_formatting)))
	
	current_setup_setting = "xml_indentation_spaces"
	add_number_dropdown(Translator.translate("Number of indentation spaces"),
			[2, 3, 4, 6, 8], true, false, Formatter.INDENTS_MIN, Formatter.INDENTS_MAX,
			not (current_setup_resource.xml_pretty_formatting and\
			current_setup_resource.xml_indentation_use_spaces))
	if current_setup_resource.xml_pretty_formatting and\
	current_setup_resource.xml_indentation_use_spaces:
		var xml_indentation_spaces_root_element := ElementRoot.new()
		var xml_indentation_spaces_circle_element := ElementCircle.new()
		xml_indentation_spaces_circle_element.set_attribute("cx", 6)
		xml_indentation_spaces_circle_element.set_attribute("cy", 8)
		xml_indentation_spaces_circle_element.set_attribute("r", 4)
		xml_indentation_spaces_circle_element.set_attribute("fill", "gold")
		xml_indentation_spaces_root_element.insert_child(0,
				xml_indentation_spaces_circle_element)
		add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
				xml_indentation_spaces_root_element, false))
	else:
		add_preview(SettingTextPreview.new("",
				SettingTextPreview.WarningType.NO_EFFECT_IN_CURRENT_CONFIGURATION))
	
	add_section(Translator.translate("Numbers"))
	current_setup_setting = "number_remove_leading_zero"
	add_checkbox(Translator.translate("Remove leading zero"))
	var number_remove_leading_zero_root_element := ElementRoot.new()
	var number_remove_leading_zero_circle_element := ElementCircle.new()
	number_remove_leading_zero_circle_element.set_attribute("cx", 0.36)
	number_remove_leading_zero_circle_element.set_attribute("cy", -0.8)
	number_remove_leading_zero_circle_element.set_attribute("r", 1.6)
	number_remove_leading_zero_circle_element.set_attribute("fill", "gold")
	number_remove_leading_zero_root_element.insert_child(0,
			number_remove_leading_zero_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			number_remove_leading_zero_root_element, true))
	
	current_setup_setting = "number_use_exponent_if_shorter"
	add_checkbox(Translator.translate("Use exponential when shorter"))
	var number_use_exponent_if_shorter_root_element := ElementRoot.new()
	var number_use_exponent_if_shorter_circle_element := ElementCircle.new()
	number_use_exponent_if_shorter_circle_element.set_attribute("cx", 800)
	number_use_exponent_if_shorter_circle_element.set_attribute("cy", -0.005)
	number_use_exponent_if_shorter_circle_element.set_attribute("r", 2000)
	number_use_exponent_if_shorter_circle_element.set_attribute("fill", "gold")
	number_use_exponent_if_shorter_root_element.insert_child(0,
			number_use_exponent_if_shorter_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			number_use_exponent_if_shorter_root_element, true))
	
	add_section(Translator.translate("Colors"))
	current_setup_setting = "color_use_named_colors"
	add_dropdown(Translator.translate("Use named colors"),
			range(Formatter.NamedColorUse.size()),
			Formatter.get_named_color_use_value_text_map())
	var color_use_named_colors_root_element := ElementRoot.new()
	var color_use_named_colors_circle_1 := ElementCircle.new()
	color_use_named_colors_circle_1.set_attribute("cx", 6)
	color_use_named_colors_circle_1.set_attribute("cy", 8)
	color_use_named_colors_circle_1.set_attribute("r", 4)
	color_use_named_colors_circle_1.set_attribute("fill", "gold")
	color_use_named_colors_circle_1.set_attribute("stroke", "crimson")
	color_use_named_colors_root_element.insert_child(0, color_use_named_colors_circle_1)
	var color_use_named_colors_circle_2 := ElementCircle.new()
	color_use_named_colors_circle_2.set_attribute("cx", 3)
	color_use_named_colors_circle_2.set_attribute("cy", 5)
	color_use_named_colors_circle_2.set_attribute("r", 2)
	color_use_named_colors_circle_2.set_attribute("fill", "turquoise")
	color_use_named_colors_root_element.insert_child(1, color_use_named_colors_circle_2)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			color_use_named_colors_root_element, true))
	
	current_setup_setting = "color_primary_syntax"
	add_dropdown(Translator.translate("Primary syntax"),
			range(Formatter.PrimaryColorSyntax.size()),
			Formatter.get_primary_color_syntax_value_text_map())
	var color_primary_syntax_root_element := ElementRoot.new()
	var color_primary_syntax_circle_element := ElementCircle.new()
	color_primary_syntax_circle_element.set_attribute("cx", 6)
	color_primary_syntax_circle_element.set_attribute("cy", 8)
	color_primary_syntax_circle_element.set_attribute("r", 4)
	color_primary_syntax_circle_element.set_attribute("fill", "#d4b")
	color_primary_syntax_circle_element.set_attribute("stroke", "#f4c4d3")
	color_primary_syntax_root_element.insert_child(0, color_primary_syntax_circle_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			color_primary_syntax_root_element, true))
	
	current_setup_setting = "color_capital_hex"
	add_checkbox(Translator.translate("Capitalize hexadecimal letters"),
			current_setup_resource.color_primary_syntax == Formatter.PrimaryColorSyntax.RGB)
	if current_setup_resource.color_primary_syntax != Formatter.PrimaryColorSyntax.RGB:
		var color_capital_hex_root_element := ElementRoot.new()
		var color_capital_hex_circle_element := ElementCircle.new()
		color_capital_hex_circle_element.set_attribute("cx", 6)
		color_capital_hex_circle_element.set_attribute("cy", 8)
		color_capital_hex_circle_element.set_attribute("r", 4)
		color_capital_hex_circle_element.set_attribute("fill", "#decade")
		color_capital_hex_root_element.insert_child(0, color_capital_hex_circle_element)
		add_preview(SettingFormatterPreview.new(current_setup_setting,
				current_setup_resource, color_capital_hex_root_element, true))
	else:
		add_preview(SettingTextPreview.new("",
				SettingTextPreview.WarningType.NO_EFFECT_IN_CURRENT_CONFIGURATION))
	
	add_section(Translator.translate("Pathdata"))
	current_setup_setting = "pathdata_compress_numbers"
	add_checkbox(Translator.translate("Compress numbers"))
	var pathdata_compress_numbers_root_element := ElementRoot.new()
	var pathdata_compress_numbers_path_element := ElementPath.new()
	pathdata_compress_numbers_path_element.set_attribute("d", "m 4 6.5 l 0.5 -0.8 v 2 z")
	pathdata_compress_numbers_path_element.set_attribute("fill", "gold")
	pathdata_compress_numbers_root_element.insert_child(0, pathdata_compress_numbers_path_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			pathdata_compress_numbers_root_element, true))
	
	current_setup_setting = "pathdata_minimize_spacing"
	add_checkbox(Translator.translate("Minimize spacing"))
	var pathdata_minimize_spacing_root_element := ElementRoot.new()
	var pathdata_minimize_spacing_path_element := ElementPath.new()
	pathdata_minimize_spacing_path_element.set_attribute("d", "m 4 6.5 l 0.5 -0.8 v 2 z")
	pathdata_minimize_spacing_path_element.set_attribute("fill", "gold")
	pathdata_minimize_spacing_root_element.insert_child(0, pathdata_minimize_spacing_path_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			pathdata_minimize_spacing_root_element, true))
	
	current_setup_setting = "pathdata_remove_spacing_after_flags"
	add_checkbox(Translator.translate("Remove spacing after flags"))
	var pathdata_remove_spacing_after_flags_root_element := ElementRoot.new()
	var pathdata_remove_spacing_after_flags_path_element := ElementPath.new()
	pathdata_remove_spacing_after_flags_path_element.set_attribute("d", "m 1 3.5 a 2 3 0 1 0 4 2 z")
	pathdata_remove_spacing_after_flags_path_element.set_attribute("fill", "gold")
	pathdata_remove_spacing_after_flags_root_element.insert_child(0, pathdata_remove_spacing_after_flags_path_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			pathdata_remove_spacing_after_flags_root_element, true))
	
	current_setup_setting = "pathdata_remove_consecutive_commands"
	add_checkbox(Translator.translate("Remove consecutive commands"))
	var pathdata_remove_consecutive_commands_root_element := ElementRoot.new()
	var pathdata_remove_consecutive_commands_path_element := ElementPath.new()
	pathdata_remove_consecutive_commands_path_element.set_attribute("d",
			"m 4 6.5 l -1 2 l 2.5 1 q 3.5 -1 2 -2 q -1.5 0.5 -1 -2 z")
	pathdata_remove_consecutive_commands_path_element.set_attribute("fill", "gold")
	pathdata_remove_consecutive_commands_root_element.insert_child(0, pathdata_remove_consecutive_commands_path_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			pathdata_remove_consecutive_commands_root_element, true))
	
	add_section(Translator.translate("Transform lists"))
	current_setup_setting = "transform_list_compress_numbers"
	add_checkbox(Translator.translate("Compress numbers"))
	var transform_list_compress_numbers_root_element := ElementRoot.new()
	var transform_list_compress_numbers_polygon_element := ElementPolygon.new()
	transform_list_compress_numbers_polygon_element.set_attribute("points", "2 4 5 8 9 1")
	transform_list_compress_numbers_polygon_element.set_attribute("fill", "gold")
	transform_list_compress_numbers_polygon_element.set_attribute("transform",
			"rotate(7.5 -0.5 0.8)")
	transform_list_compress_numbers_root_element.insert_child(0, transform_list_compress_numbers_polygon_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			transform_list_compress_numbers_root_element, true))
	
	current_setup_setting = "transform_list_minimize_spacing"
	add_checkbox(Translator.translate("Minimize spacing"))
	var transform_list_minimize_spacing_root_element := ElementRoot.new()
	var transform_list_minimize_spacing_polygon_element := ElementPolygon.new()
	transform_list_minimize_spacing_polygon_element.set_attribute("points", "2 4 5 8 9 1")
	transform_list_minimize_spacing_polygon_element.set_attribute("fill", "gold")
	transform_list_minimize_spacing_polygon_element.set_attribute("transform",
			"rotate(7.5 -0.5 0.8)")
	transform_list_minimize_spacing_root_element.insert_child(0, transform_list_minimize_spacing_polygon_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			transform_list_minimize_spacing_root_element, true))
	
	current_setup_setting = "transform_list_remove_unnecessary_params"
	add_checkbox(Translator.translate("Remove unnecessary parameters"))
	var transform_list_remove_unnecessary_params_root_element := ElementRoot.new()
	var transform_list_remove_unnecessary_params_polygon_element := ElementPolygon.new()
	transform_list_remove_unnecessary_params_polygon_element.set_attribute("points", "2 4 5 8 9 1")
	transform_list_remove_unnecessary_params_polygon_element.set_attribute("fill", "gold")
	transform_list_remove_unnecessary_params_polygon_element.set_attribute("transform",
			"scale(2 2) translate(4 0) rotate(30 0 0)")
	transform_list_remove_unnecessary_params_root_element.insert_child(0, transform_list_remove_unnecessary_params_polygon_element)
	add_preview(SettingFormatterPreview.new(current_setup_setting, current_setup_resource,
			transform_list_remove_unnecessary_params_root_element, true))


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
