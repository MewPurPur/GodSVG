extends PanelContainer

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const PaletteConfigWidget = preload("res://src/ui_parts/palette_config.tscn")
const plus_icon = preload("res://visual/icons/Plus.svg")

const SettingCheckBox = preload("res://src/ui_elements/setting_check_box.gd")

@onready var lang_button: Button = %Language
@onready var palette_container: VBoxContainer = %PaletteContainer
@onready var wrap_mouse: CheckBox = %WrapMouse

func _ready() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_MOUSE_WARP):
		wrap_mouse.set_pressed_no_signal(false)
		wrap_mouse.disabled = true
	update_language_button()
	rebuild_color_palettes()
	setup_autoformat_tab()

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
	lang_button.text = tr(&"Language") + ": " + TranslationServer.get_locale().to_upper()


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
	add_palette_button.theme_type_variation = &"TranslucentButton"
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
				set_checkbox_enabled(checkbox, GlobalSettings.number_enable_autoformatting)
	for checkbox in color_vbox.get_children():
		if checkbox is SettingCheckBox:
			if checkbox.setting_name != "color_enable_autoformatting":
				set_checkbox_enabled(checkbox, GlobalSettings.color_enable_autoformatting)
	for checkbox in path_vbox.get_children():
		if checkbox is SettingCheckBox:
			if checkbox.setting_name != "path_enable_autoformatting":
				set_checkbox_enabled(checkbox, GlobalSettings.path_enable_autoformatting)
	for checkbox in transform_vbox.get_children():
		if checkbox is SettingCheckBox:
			if checkbox.setting_name != "transform_enable_autoformatting":
				set_checkbox_enabled(checkbox, GlobalSettings.transform_enable_autoformatting)

func set_checkbox_enabled(checkbox: SettingCheckBox, enabled: bool) -> void:
	checkbox.disabled = not enabled
	checkbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else\
			Control.CURSOR_ARROW
