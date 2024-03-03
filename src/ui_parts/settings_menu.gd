extends PanelContainer

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const PaletteConfigWidget = preload("res://src/ui_parts/palette_config.tscn")
const plus_icon = preload("res://visual/icons/Plus.svg")

const SettingCheckBox = preload("res://src/ui_elements/setting_check_box.gd")
const SettingColor = preload("res://src/ui_elements/setting_color.gd")

@onready var lang_button: Button = %Language
@onready var palette_container: VBoxContainer = %PaletteContainer
@onready var content_container: MarginContainer = %ContentContainer
@onready var tabs: VBoxContainer = %Tabs
@onready var wrap_mouse: HBoxContainer = %WrapMouse

var focused_content := 0

func _ready() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_MOUSE_WARP):
		wrap_mouse.set_pressed_no_signal(false)
		wrap_mouse.disabled = true
	update_language_button()
	rebuild_color_palettes()
	setup_setting_labels()
	setup_autoformat_tab()
	setup_theming_tab()
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
	var invert_zoom := %ContentContainer/Other/Input/InvertZoom
	invert_zoom.label.text = tr("Invert zoom direction")
	invert_zoom.label.tooltip_text = tr("Swaps zoom in and zoom out with the mouse wheel.")
	wrap_mouse.label.text = tr("Wrap mouse")
	wrap_mouse.label.tooltip_text = tr("Wraps the mouse cursor around when panning the viewport.")
	var ctrl_for_zoom := %ContentContainer/Other/Input/UseCtrlForZoom
	ctrl_for_zoom.label.text = tr("Use CTRL for zooming")
	ctrl_for_zoom.label.tooltip_text = tr("If turned on, scrolling will pan the view. To zoom, hold CTRL while scrolling.")
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
	%PathVBox/PathEnable.label.text = tr("Enable autoformatting")
	%PathVBox/CompressNumbers.label.text = tr("Compress numbers")
	%PathVBox/MinimizeSpacing.label.text = tr("Minimize spacing")
	%PathVBox/RemoveSpacingAfterFlags.label.text = tr("Remove spacing after flags")
	%PathVBox/RemoveConsecutiveCommands.label.text = tr("Remove consecutive commands")
	%TransformVBox/TransformEnable.label.text = tr("Enable autoformatting")
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

func _on_window_mode_pressed() -> void:
	GlobalSettings.save_window_mode = not GlobalSettings.save_window_mode

func _on_svg_pressed() -> void:
	GlobalSettings.save_svg = not GlobalSettings.save_svg

func _on_close_pressed() -> void:
	queue_free()

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
	for palette in GlobalSettings.get_palettes():
		# If there's an unnamed pallete, don't add a new one (there'll be a name clash).
		if palette.name.is_empty():
			return
	
	GlobalSettings.get_palettes().append(ColorPalette.new())
	GlobalSettings.save_user_data()
	rebuild_color_palettes()

func rebuild_color_palettes() -> void:
	for palette_config in palette_container.get_children():
		palette_config.queue_free()
	
	for palette in GlobalSettings.get_palettes():
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
	for vbox in [number_vbox, color_vbox, path_vbox, transform_vbox]:
		disable_autoformat_checkboxes()
		for child in vbox.get_children():
			if child is SettingCheckBox:
				child.pressed.connect(_on_autoformat_settings_changed)

func _on_autoformat_settings_changed() -> void:
	SVG.root_tag.replace_self(SVG.root_tag.create_duplicate())
	disable_autoformat_checkboxes()

func disable_autoformat_checkboxes() -> void:
	for checkbox in number_vbox.get_children():
		if checkbox is SettingCheckBox:
			if checkbox.setting_name != "number_enable_autoformatting":
				checkbox.set_checkbox_enabled(GlobalSettings.number_enable_autoformatting)
	for checkbox in color_vbox.get_children():
		if checkbox is SettingCheckBox:
			if checkbox.setting_name != "color_enable_autoformatting":
				checkbox.set_checkbox_enabled(GlobalSettings.color_enable_autoformatting)
	for checkbox in path_vbox.get_children():
		if checkbox is SettingCheckBox:
			if checkbox.setting_name != "path_enable_autoformatting":
				checkbox.set_checkbox_enabled(GlobalSettings.path_enable_autoformatting)
	for checkbox in transform_vbox.get_children():
		if checkbox is SettingCheckBox:
			if checkbox.setting_name != "transform_enable_autoformatting":
				checkbox.set_checkbox_enabled(GlobalSettings.transform_enable_autoformatting)


func setup_theming_tab() -> void:
	for child in %HighlighterVBox.get_children():
		if child is SettingColor:
			child.value_changed.connect(_on_theme_settings_changed)

func _on_theme_settings_changed() -> void:
	get_tree().get_root().propagate_notification(NOTIFICATION_THEME_CHANGED)
