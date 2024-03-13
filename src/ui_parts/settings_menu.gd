extends PanelContainer

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const PaletteConfigWidget = preload("res://src/ui_elements/palette_config.tscn")
const ShortcutConfigWidget = preload("res://src/ui_elements/setting_shortcut.tscn")
const ShortcutShowcaseWidget = preload("res://src/ui_elements/presented_shortcut.tscn")
const plus_icon = preload("res://visual/icons/Plus.svg")

const SettingCheckBox = preload("res://src/ui_elements/setting_check_box.gd")
const SettingColor = preload("res://src/ui_elements/setting_color.gd")

@onready var lang_button: Button = %Language
@onready var palette_container: VBoxContainer = %PaletteContainer
@onready var shortcut_container: VBoxContainer = %ShortcutContainer
@onready var content_container: MarginContainer = %ContentContainer
@onready var tabs: VBoxContainer = %Tabs
@onready var wrap_mouse: HBoxContainer = %WrapMouse
@onready var configurable_shortcuts: VBoxContainer = %ConfigurableShortcuts
@onready var non_configurable_shortcuts: VBoxContainer = %NonConfigurableShortcuts

var focused_content := 0

var shortcut_descriptions := {  # Dictionary{String: String}
	"export": tr("Export"),
	"import": tr("Import"),
	"save": tr("Save"),
	"undo": tr("Undo"),
	"redo": tr("Redo"),
	"select_all": tr("Select all tags"),
	"duplicate": tr("Duplicate the selected tags"),
	"delete": tr("Delete the selection"),
	"move_up": tr("Move the selected tags up"),
	"move_down": tr("Move the selected tags down"),
	"zoom_in": tr("Zoom in"),
	"zoom_out": tr("Zoom out"),
	"zoom_reset": tr("Zoom reset"),
}

func _ready() -> void:
	update_language_button()
	setup_setting_labels()
	for i in tabs.get_child_count():
		tabs.get_child(i).pressed.connect(update_focused_content.bind(i))
	update_focused_content(0)

func update_focused_content(idx: int) -> void:
	focused_content = idx
	for i in content_container.get_child_count():
		content_container.get_child(i).visible = (focused_content == i)
	tabs.get_child(focused_content).button_pressed = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		setup_setting_labels()

# Sets the text for all the labels.
func setup_setting_labels() -> void:
	tabs.get_node(^"AutoformattingTab").text = tr("Autoformatting")
	tabs.get_node(^"PalettesTab").text = tr("Palettes")
	tabs.get_node(^"ShortcutsTab").text = tr("Shortcuts")
	tabs.get_node(^"ThemeTab").text = tr("Theme")
	tabs.get_node(^"OtherTab").text = tr("Other")
	
	var invert_zoom := %ContentContainer/Other/Input/InvertZoom
	invert_zoom.label.text = tr("Invert zoom direction")
	invert_zoom.label.tooltip_text = tr("Swaps zoom in and zoom out with the mouse wheel.")
	wrap_mouse.label.text = tr("Wrap mouse")
	wrap_mouse.label.tooltip_text = tr("Wraps the mouse cursor around when panning the viewport.")
	var ctrl_for_zoom := %ContentContainer/Other/Input/UseCtrlForZoom
	ctrl_for_zoom.label.text = tr("Use CTRL for zooming")
	ctrl_for_zoom.label.tooltip_text = tr("If turned on, scrolling will pan the view. To zoom, hold CTRL while scrolling.")
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
	%HighlighterVBox/ErrorColor.label.text = tr("Error color")
	%BasicColorsVBox/DefaultValueOpacity.label.text = tr("Default value opacity")
	%BasicColorsVBox/ValidColor.label.text = tr("Valid color")
	%BasicColorsVBox/ErrorColor.label.text = tr("Error color")
	%BasicColorsVBox/WarningColor.label.text = tr("Warning color")

func _on_window_mode_pressed() -> void:
	GlobalSettings.save_window_mode = not GlobalSettings.save_window_mode

func _on_svg_pressed() -> void:
	GlobalSettings.save_svg = not GlobalSettings.save_svg

func _on_close_pressed() -> void:
	HandlerGUI.remove_overlay()

func _on_language_pressed() -> void:
	var btn_arr: Array[Button] = []
	for lang in TranslationServer.get_loaded_locales():
		btn_arr.append(Utils.create_btn(
				TranslationServer.get_locale_name(lang) + " (" + lang + ")",
				_on_language_chosen.bind(lang)))
	var lang_popup := ContextPopup.instantiate()
	add_child(lang_popup)
	lang_popup.set_button_array(btn_arr, true, lang_button.size.x)
	Utils.popup_under_rect(lang_popup, lang_button.get_global_rect(), get_viewport())

func _on_language_chosen(locale: String) -> void:
	GlobalSettings.language = locale
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
	get_tree().get_root().propagate_notification(
			Utils.CustomNotification.NUMBER_PRECISION_CHANGED)

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
	for action in GlobalSettings.configurable_keybinds:
		var keybind_config := ShortcutConfigWidget.instantiate()
		configurable_shortcuts.add_child(keybind_config)
		keybind_config.label.text = shortcut_descriptions[action] if\
				action in shortcut_descriptions else action
		keybind_config.setup(action)
	for action in ["move_relative", "move_absolute", "line_relative", "line_absolute",
	"horizontal_line_relative", "horizontal_line_absolute", "vertical_line_relative",
	"vertical_line_absolute", "close_path_relative", "close_path_absolute",
	"elliptical_arc_relative", "elliptical_arc_absolute", "quadratic_bezier_relative",
	"quadratic_bezier_absolute", "shorthand_quadratic_bezier_relative",
	"shorthand_quadratic_bezier_absolute", "cubic_bezier_relative",
	"cubic_bezier_absolute", "shorthand_cubic_bezier_relative",
	"shorthand_cubic_bezier_absolute"]:
		var keybind_config := ShortcutShowcaseWidget.instantiate()
		non_configurable_shortcuts.add_child(keybind_config)
		keybind_config.label.text = shortcut_descriptions[action] if\
				action in shortcut_descriptions else action
		keybind_config.setup(action)


func setup_theming_tab() -> void:
	for child in %HighlighterVBox.get_children():
		if child is SettingColor:
			child.value_changed.connect(_notify_highlight_colors_changed)
	%DefaultValueOpacity.value_changed.connect(_notify_default_value_opacity_changed)

func _on_theme_settings_changed() -> void:
	ThemeGenerator.generate_theme()

func _notify_highlight_colors_changed() -> void:
	get_tree().get_root().propagate_notification(
			Utils.CustomNotification.HIGHLIGHT_COLORS_CHANGED)

func _notify_default_value_opacity_changed() -> void:
	get_tree().get_root().propagate_notification(
			Utils.CustomNotification.DEFAULT_VALUE_OPACITY_CHANGED)


# Optimize by only generating content when you click them.

func _on_autoformatting_tab_pressed() -> void:
	setup_autoformat_tab()

func _on_palettes_tab_pressed() -> void:
	rebuild_color_palettes()

func _on_shortcuts_tab_pressed() -> void:
	setup_shortcuts_tab()

func _on_theme_tab_pressed() -> void:
	setup_theming_tab()

func _on_other_tab_pressed() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_MOUSE_WARP):
		wrap_mouse.set_pressed_no_signal(false)
		wrap_mouse.disabled = true
