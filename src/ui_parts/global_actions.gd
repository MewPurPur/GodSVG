extends HBoxContainer

const LayoutPopupScene = preload("res://src/ui_parts/layout_popup.tscn")

@onready var more_options: Button = $LeftSide/MoreOptions
@onready var settings_button: BetterButton = $LeftSide/SettingsButton
@onready var layout_button: Button = $LeftSide/LayoutButton
@onready var size_button: Button = $RightSide/SizeButton
@onready var current_file_button: Button = $RightSide/CurrentFileButton
@onready var import_button: BetterButton = $RightSide/ImportButton
@onready var export_button: BetterButton = $RightSide/ExportButton

func sync_localization() -> void:
	layout_button.tooltip_text = Translator.translate("Layout")

func _ready() -> void:
	# The settings button can be called from anywhere, but it's bound to this registration for the highlight.
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("open_settings", HandlerGUI.open_settings, ShortcutsRegistration.Behavior.PASS_THROUGH_POPUPS)
	shortcuts.add_shortcut("import", FileUtils.open_svg_import_dialog, ShortcutsRegistration.Behavior.PASS_THROUGH_POPUPS)
	shortcuts.add_shortcut("export", HandlerGUI.open_export, ShortcutsRegistration.Behavior.PASS_THROUGH_POPUPS)
	HandlerGUI.register_shortcuts(self, shortcuts)
	settings_button.shortcuts_bind = shortcuts
	import_button.shortcuts_bind = shortcuts
	export_button.shortcuts_bind = shortcuts
	
	State.svg_changed.connect(update_size_button)
	update_size_button()
	Configs.theme_changed.connect(sync_theming)
	Configs.basic_colors_changed.connect(update_size_button_colors)
	sync_theming()
	Configs.language_changed.connect(sync_localization)
	sync_localization()
	more_options.pressed.connect(_on_more_options_pressed)
	size_button.pressed.connect(_on_size_button_pressed)
	layout_button.pressed.connect(_on_layout_button_pressed)
	
	HandlerGUI.register_focus_sequence(self, [more_options, settings_button, layout_button, size_button, current_file_button, import_button, export_button], true)

func sync_theming() -> void:
	size_button.begin_bulk_theme_override()
	const CONST_ARR: PackedStringArray = ["normal", "focus", "hover", "disabled"]
	for theme_type in CONST_ARR:
		size_button.remove_theme_stylebox_override(theme_type)
		var stylebox := size_button.get_theme_stylebox(theme_type).duplicate()
		stylebox.content_margin_bottom = 0.0
		stylebox.content_margin_top = 0.0
		size_button.add_theme_stylebox_override(theme_type, stylebox)
	size_button.end_bulk_theme_override()
	update_size_button_colors()

func _on_size_button_pressed() -> void:
	var btn_arr: Array[ContextButton] = [ContextButton.create_from_action("optimize")]
	HandlerGUI.popup_under_rect_center(ContextPopup.create(btn_arr), size_button.get_global_rect(), get_viewport())

func _on_more_options_pressed() -> void:
	var btn_arr: Array[ContextButton] = []
	var separator_indices := PackedInt32Array()
	
	btn_arr.append(ContextButton.create_from_action("check_updates"))
	
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE_EXTRA):
		btn_arr.append(ContextButton.create_custom(Translator.translate("View savedata"),
				open_savedata_folder, preload("res://assets/icons/OpenFolder.svg")))
	
	separator_indices.append(btn_arr.size())
	
	var about_btn := ContextButton.create_from_action("about_info").add_custom_icon(preload("res://assets/logos/icon.svg")).set_icon_unmodulated()
	btn_arr.append(about_btn)
	btn_arr.append(ContextButton.create_from_action("about_donate"))
	
	separator_indices.append(btn_arr.size())
	
	btn_arr.append(ContextButton.create_from_action("about_repo"))
	btn_arr.append(ContextButton.create_from_action("about_website"))
	
	HandlerGUI.popup_under_rect_center(ContextPopup.create(btn_arr, true, -1, separator_indices), more_options.get_global_rect(), get_viewport())


func open_savedata_folder() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"))


func update_size_button() -> void:
	var svg_text_size := State.get_export_text().length()
	size_button.text = String.humanize_size(svg_text_size)
	size_button.tooltip_text = String.num_uint64(svg_text_size) + " B"
	if State.root_element.optimize(Configs.savedata.default_optimizer, true):
		size_button.disabled = false
		size_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		update_size_button_colors()
	else:
		size_button.disabled = true
		size_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		size_button.remove_theme_color_override("font_color")

func update_size_button_colors() -> void:
	size_button.begin_bulk_theme_override()
	const CONST_ARR: PackedStringArray = ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]
	for theme_type in CONST_ARR:
		size_button.add_theme_color_override(theme_type,
				Configs.savedata.basic_color_warning.lerp(ThemeUtils.max_contrast_color, 0.4))
	size_button.end_bulk_theme_override()

func _on_layout_button_pressed() -> void:
	var layout_popup := LayoutPopupScene.instantiate()
	HandlerGUI.popup_under_rect_center(layout_popup, layout_button.get_global_rect(), get_viewport())
