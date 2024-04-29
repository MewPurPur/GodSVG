extends PanelContainer

const PaletteConfigWidget = preload("res://src/ui_elements/palette_config.tscn")
const ShortcutConfigWidget = preload("res://src/ui_elements/setting_shortcut.tscn")
const ShortcutShowcaseWidget = preload("res://src/ui_elements/presented_shortcut.tscn")
const plus_icon = preload("res://visual/icons/Plus.svg")

const SettingCheckBox = preload("res://src/ui_elements/setting_check_box.gd")
const SettingColor = preload("res://src/ui_elements/setting_color.gd")

@onready var lang_button: Button = %Language
@onready var palette_container: VBoxContainer = %PaletteContainer
@onready var content_container: MarginContainer = %ContentContainer
@onready var tabs: VBoxContainer = %Tabs
@onready var close_button: Button = $VBoxContainer/CloseButton

@onready var wrap_mouse: HBoxContainer = %WrapMouse
@onready var use_native_file_dialog: HBoxContainer = %UseNativeFileDialog

@onready var shortcut_categories: HFlowContainer = %Categories
@onready var shortcut_container: VBoxContainer = %Shortcuts

var focused_content := 0

func _ready() -> void:
	update_language_button()
	setup_setting_labels()
	for i in tabs.get_child_count():
		tabs.get_child(i).pressed.connect(update_focused_content.bind(i))
	update_focused_content(0)
	setup_theming()
	close_button.pressed.connect(queue_free)

func update_focused_content(idx: int) -> void:
	focused_content = idx
	for i in content_container.get_child_count():
		content_container.get_child(i).visible = (focused_content == i)
	tabs.get_child(focused_content).button_pressed = true

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.LANGUAGE_CHANGED:
		setup_setting_labels()
	elif what == Utils.CustomNotification.THEME_CHANGED:
		setup_theming()

func setup_theming() -> void:
	var stylebox := get_theme_stylebox("panel").duplicate()
	stylebox.content_margin_top += 4.0
	add_theme_stylebox_override("panel", stylebox)

# Sets the text for all the labels.
func setup_setting_labels() -> void:
	tabs.get_node(^"AutoformattingTab").text = tr("Autoformatting")
	tabs.get_node(^"PalettesTab").text = tr("Palettes")
	tabs.get_node(^"ShortcutsTab").text = tr("Shortcuts")
	tabs.get_node(^"ThemeTab").text = tr("Theme")
	tabs.get_node(^"OtherTab").text = tr("Other")
	
	var invert_zoom := %ContentContainer/Other/OtherSettings/Input/InvertZoom
	invert_zoom.label.text = tr("Invert zoom direction")
	invert_zoom.tooltip_text = tr("Swaps zoom in and zoom out with the mouse wheel.")
	
	wrap_mouse.label.text = tr("Wrap mouse")
	wrap_mouse.tooltip_text = tr("Wraps the mouse cursor around when panning the viewport.")
	
	var ctrl_for_zoom := %ContentContainer/Other/OtherSettings/Input/UseCtrlForZoom
	ctrl_for_zoom.label.text = tr("Use CTRL for zooming")
	ctrl_for_zoom.tooltip_text = tr("If turned on, scrolling will pan the view. To zoom, hold CTRL while scrolling.")
	
	use_native_file_dialog.label.text = tr("Use native file dialog")
	use_native_file_dialog.tooltip_text = tr("If turned on, uses your operating system's native file dialog. If turned off, uses GodSVG's built-in file dialog.")
	
	var handles_size := %Misc/HandleSize
	handles_size.label.text = tr("Handles size")
	handles_size.tooltip_text = tr("Increases the visual size and grabbing area of handles.")
	
	var ui_scale := %Misc/UIScale
	ui_scale.label.text = tr("UI scale")
	ui_scale.tooltip_text = tr("Changes the scale of the visual user interface.")
	
	var auto_ui_scale := %Misc/AutoUIScale
	auto_ui_scale.label.text = tr("Auto UI scale")
	auto_ui_scale.tooltip_text = tr("Scales the user interface based on the screen size.")
	
	%GeneralVBox/NumberPrecision.label.text = tr("Number precision digits")
	%GeneralVBox/AnglePrecision.label.text = tr("Angle precision digits")
	%XMLVBox/AddTrailingNewline.label.text = tr("Add trailing newline")
	%XMLVBox/UseShorthandTagSyntax.label.text = tr("Use shorthand tag syntax")
	%NumberVBox/NumberEnable.label.text = tr("Enable autoformatting")
	%NumberVBox/RemoveZeroPadding.label.text = tr("Remove zero padding")
	%NumberVBox/RemoveLeadingZero.label.text = tr("Remove leading zero")
	%ColorVBox/ColorEnable.label.text = tr("Enable autoformatting")
	%ColorVBox/ConvertRGBToHex.label.text = tr("Convert rgb format to hex")
	%ColorVBox/ConvertNamedToHex.label.text = tr("Convert named colors to hex")
	%ColorVBox/UseShorthandHex.label.text = tr("Use shorthand hex code")
	%ColorVBox/UseNamedColors.label.text = tr("Use short named colors")
	%PathVBox/CompressNumbers.label.text = tr("Compress numbers")
	%PathVBox/MinimizeSpacing.label.text = tr("Minimize spacing")
	%PathVBox/RemoveSpacingAfterFlags.label.text = tr("Remove spacing after flags")
	%PathVBox/RemoveConsecutiveCommands.label.text = tr("Remove consecutive commands")
	%TransformVBox/CompressNumbers.label.text = tr("Compress numbers")
	%TransformVBox/MinimizeSpacing.label.text = tr("Minimize spacing")
	%TransformVBox/RemoveUnnecessaryParams.label.text = tr("Remove unnecessary parameters")
	%HighlighterVBox/SymbolColor.label.text = tr("Symbol color")
	%HighlighterVBox/TagColor.label.text = tr("Tag color")
	%HighlighterVBox/AttributeColor.label.text = tr("Attribute color")
	%HighlighterVBox/StringColor.label.text = tr("String color")
	%HighlighterVBox/CommentColor.label.text = tr("Comment color")
	%HighlighterVBox/TextColor.label.text = tr("Text color")
	%HighlighterVBox/CDATAColor.label.text = tr("CDATA color")
	%HighlighterVBox/ErrorColor.label.text = tr("Error color")
	%HandleColors/InsideColor.label.text = tr("Inside color")
	%HandleColors/NormalColor.label.text = tr("Normal color")
	%HandleColors/HoveredColor.label.text = tr("Hovered color")
	%HandleColors/SelectedColor.label.text = tr("Selected color")
	%HandleColors/HoveredSelectedColor.label.text = tr("Hovered selected color")
	%BasicColorsVBox/ValidColor.label.text = tr("Valid color")
	%BasicColorsVBox/ErrorColor.label.text = tr("Error color")
	%BasicColorsVBox/WarningColor.label.text = tr("Warning color")


func _on_language_pressed() -> void:
	var btn_arr: Array[Button] = []
	for lang in TranslationServer.get_loaded_locales():
		btn_arr.append(Utils.create_btn(
				TranslationServer.get_locale_name(lang) + " (" + lang + ")",
				_on_language_chosen.bind(lang), lang == TranslationServer.get_locale()))
	var lang_popup := ContextPopup.new()
	lang_popup.setup(btn_arr, true, lang_button.size.x)
	HandlerGUI.popup_under_rect(lang_popup, lang_button.get_global_rect(), get_viewport())

func _on_language_chosen(locale: String) -> void:
	GlobalSettings.language = locale
	custom_notify(Utils.CustomNotification.LANGUAGE_CHANGED)
	update_language_button()

func update_language_button() -> void:
	lang_button.text = tr("Language") + ": " + TranslationServer.get_locale().to_upper()


# Palette tab helpers.

func add_palette() -> void:
	for palette in GlobalSettings.palettes:
		# If there's an unnamed pallete, don't add a new one (there'll be a name clash).
		if palette.title.is_empty():
			return
	
	GlobalSettings.palettes.append(ColorPalette.new())
	GlobalSettings.save_palettes()
	rebuild_color_palettes()

func rebuild_color_palettes() -> void:
	for palette_config in palette_container.get_children():
		palette_config.queue_free()
	for palette in GlobalSettings.palettes:
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


# Autoformatting tab helpers.

@onready var xml_vbox: VBoxContainer = %XMLVBox
@onready var number_vbox: VBoxContainer = %NumberVBox
@onready var color_vbox: VBoxContainer = %ColorVBox
@onready var path_vbox: VBoxContainer = %PathVBox
@onready var transform_vbox: VBoxContainer = %TransformVBox

func setup_autoformat_tab() -> void:
	disable_autoformat_checkboxes()
	for vbox in [xml_vbox, number_vbox, color_vbox, path_vbox, transform_vbox]:
		for child in vbox.get_children():
			if child is SettingCheckBox:
				child.pressed.connect(_on_autoformat_settings_changed)
	%GeneralVBox/NumberPrecision.value_changed.connect(_on_number_precision_changed)
	%GeneralVBox/AnglePrecision.value_changed.connect(SVG.refresh)

func _on_autoformat_settings_changed() -> void:
	SVG.refresh()
	disable_autoformat_checkboxes()

func _on_number_precision_changed() -> void:
	SVG.refresh()
	# Update snap to fit the new precision.
	var snapping_on := GlobalSettings.save_data.snap > 0
	var quanta := 0.1 ** GlobalSettings.general_number_precision
	GlobalSettings.save_data.snap = snappedf(GlobalSettings.save_data.snap, quanta)
	if absf(GlobalSettings.save_data.snap) < quanta:
		GlobalSettings.save_data.snap = quanta
		if not snapping_on:
			GlobalSettings.save_data.snap *= -1
	custom_notify(Utils.CustomNotification.NUMBER_PRECISION_CHANGED)

func disable_autoformat_checkboxes() -> void:
	var is_autoformatting_numbers := GlobalSettings.number_enable_autoformatting
	var is_autoformatting_colors := GlobalSettings.color_enable_autoformatting
	%NumberVBox/RemoveZeroPadding.set_checkbox_enabled(is_autoformatting_numbers)
	%NumberVBox/RemoveLeadingZero.set_checkbox_enabled(is_autoformatting_numbers)
	%ColorVBox/ConvertRGBToHex.set_checkbox_enabled(is_autoformatting_colors)
	%ColorVBox/ConvertNamedToHex.set_checkbox_enabled(is_autoformatting_colors)
	%ColorVBox/UseShorthandHex.set_checkbox_enabled(is_autoformatting_colors)
	%ColorVBox/UseNamedColors.set_checkbox_enabled(is_autoformatting_colors)


func setup_shortcuts_tab() -> void:
	shortcut_categories.add_child(Utils.create_btn(tr("File"), show_keybinds.bind("file")))
	shortcut_categories.add_child(Utils.create_btn(tr("Edit"), show_keybinds.bind("edit")))
	shortcut_categories.add_child(Utils.create_btn(tr("View"), show_keybinds.bind("view")))
	shortcut_categories.add_child(Utils.create_btn(tr("Tool"), show_tool_keybinds))
	# Add them all to a button group.
	var button_group := ButtonGroup.new()
	for btn: Button in shortcut_categories.get_children():
		btn.toggle_mode = true
		btn.button_group = button_group
	shortcut_categories.get_child(0).button_pressed = true
	show_keybinds("file")

func show_keybinds(category: String):
	for child in shortcut_container.get_children():
		child.queue_free()
	
	var translation_utils := TranslationUtils.new()
	for action in GlobalSettings.configurable_keybinds[category]:
		var keybind_config := ShortcutConfigWidget.instantiate()
		shortcut_container.add_child(keybind_config)
		keybind_config.label.text = translation_utils.get_shortcut_description(action)
		keybind_config.setup(action)

func show_tool_keybinds() -> void:
	for child in shortcut_container.get_children():
		child.queue_free()
	
	var translation_utils := TranslationUtils.new()
	for action in GlobalSettings.unconfigurable_keybinds:
		var keybind_config := ShortcutShowcaseWidget.instantiate()
		shortcut_container.add_child(keybind_config)
		keybind_config.label.text = translation_utils.get_shortcut_description(action)
		keybind_config.setup(action)


func setup_theming_tab() -> void:
	for child in %HighlighterVBox.get_children():
		if child is SettingColor:
			child.value_changed.connect(custom_notify.bind(
					Utils.CustomNotification.HIGHLIGHT_COLORS_CHANGED))
	for child in %HandleColors.get_children():
		if child is SettingColor:
			child.value_changed.connect(custom_notify.bind(
					Utils.CustomNotification.HANDLE_VISUALS_CHANGED))
	for child in %BasicColorsVBox.get_children():
		if child is SettingColor:
			child.value_changed.connect(custom_notify.bind(
					Utils.CustomNotification.BASIC_COLORS_CHANGED))

func _on_theme_settings_changed() -> void:
	ThemeGenerator.generate_theme()

func custom_notify(notif: Utils.CustomNotification) -> void:
	get_tree().get_root().propagate_notification(notif)


# Optimize by only generating content on demand.

var generated_content := {  # String: bool
	"autoformat": false,
	"palettes": false,
	"shortcuts": false,
	"theming": false,
	"other": false,
}

func _on_autoformatting_tab_toggled(toggled_on: bool) -> void:
	if toggled_on and not generated_content.autoformat:
		setup_autoformat_tab()
		generated_content.autoformat = true

func _on_palettes_tab_toggled(toggled_on: bool) -> void:
	if toggled_on and not generated_content.palettes:
		rebuild_color_palettes()
		generated_content.palettes = true

func _on_shortcuts_tab_toggled(toggled_on: bool) -> void:
	if toggled_on and not generated_content.shortcuts:
		setup_shortcuts_tab()
		generated_content.shortcuts = true

func _on_theme_tab_toggled(toggled_on: bool) -> void:
	if toggled_on and not generated_content.theming:
		setup_theming_tab()
		generated_content.theming = true

func _on_other_tab_toggled(toggled_on: bool) -> void:
	if toggled_on and not generated_content.other:
		%ContentContainer/Other/OtherSettings/Misc/HandleSize.value_changed.connect(
				custom_notify.bind(Utils.CustomNotification.HANDLE_VISUALS_CHANGED))
		%ContentContainer/Other/OtherSettings/Misc/UIScale.value_changed.connect(
				custom_notify.bind(Utils.CustomNotification.UI_SCALE_CHANGED))
		%ContentContainer/Other/OtherSettings/Misc/AutoUIScale.pressed.connect(
				custom_notify.bind(Utils.CustomNotification.UI_SCALE_CHANGED))
		# Disable mouse wrap if not available.
		if not DisplayServer.has_feature(DisplayServer.FEATURE_MOUSE_WARP):
			wrap_mouse.checkbox.set_pressed_no_signal(false)
			wrap_mouse.set_checkbox_enabled(false)
		# Disable fallback file dialog on web, and native file dialog if not available.
		if OS.has_feature("web"):
			use_native_file_dialog.checkbox.set_pressed_no_signal(true)
			use_native_file_dialog.set_checkbox_enabled(false)
		if not DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG):
			use_native_file_dialog.checkbox.set_pressed_no_signal(false)
			use_native_file_dialog.set_checkbox_enabled(false)
		generated_content.other = true
