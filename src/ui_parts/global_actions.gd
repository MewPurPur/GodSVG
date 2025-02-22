extends HBoxContainer

@onready var import_button: Button = $RightSide/ImportButton
@onready var export_button: Button = $RightSide/ExportButton
@onready var more_options: Button = $LeftSide/MoreOptions
@onready var settings_button: Button = $LeftSide/SettingsButton
@onready var size_button: Button = $RightSide/SizeButton
@onready var file_button: Button = $RightSide/CurrentFileButton

func update_translations() -> void:
	import_button.tooltip_text = Translator.translate("Import")
	export_button.tooltip_text = Translator.translate("Export")
	settings_button.tooltip_text = Translator.translate("Settings")

func _ready() -> void:
	Configs.language_changed.connect(update_translations)
	update_translations()
	State.svg_changed.connect(update_size_button)
	Configs.basic_colors_changed.connect(update_size_button_colors)
	
	# Fix the size button sizing.
	size_button.begin_bulk_theme_override()
	for theming in ["normal", "hover", "pressed", "disabled"]:
		var stylebox := size_button.get_theme_stylebox(theming).duplicate()
		stylebox.content_margin_bottom = 0
		stylebox.content_margin_top = 0
		size_button.add_theme_stylebox_override(theming, stylebox)
	size_button.end_bulk_theme_override()
	
	import_button.pressed.connect(ShortcutUtils.fn("import"))
	export_button.pressed.connect(ShortcutUtils.fn("export"))
	more_options.pressed.connect(_on_more_options_pressed)
	size_button.pressed.connect(_on_size_button_pressed)
	settings_button.pressed.connect(ShortcutUtils.fn_call.bind("open_settings"))


func _on_size_button_pressed() -> void:
	var btn_array: Array[Button] = [
		ContextPopup.create_button(Translator.translate("Optimize"),
				ShortcutUtils.fn("optimize"), false, load("res://assets/icons/Compress.svg"),
				"optimize")]
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true)
	HandlerGUI.popup_under_rect_center(context_popup, size_button.get_global_rect(),
			get_viewport())

func _on_more_options_pressed() -> void:
	var can_show_savedata_folder := DisplayServer.has_feature(
				DisplayServer.FEATURE_NATIVE_DIALOG_FILE)
	var buttons_arr: Array[Button] = []
	buttons_arr.append(ContextPopup.create_button(Translator.translate(
			"Check for updates"), ShortcutUtils.fn("check_updates"), false,
			load("res://assets/icons/Reload.svg"), "check_updates"))
	
	if can_show_savedata_folder:
		buttons_arr.append(ContextPopup.create_button(Translator.translate(
				"View savedata"), open_savedata_folder , false,
				load("res://assets/icons/OpenFolder.svg")))
	
	var about_btn := ContextPopup.create_button(Translator.translate("About…"),
			ShortcutUtils.fn("about_info"), false,
			load("res://assets/logos/icon.svg"), "about_info")
	about_btn.expand_icon = true
	buttons_arr.append(about_btn)
	buttons_arr.append(ContextPopup.create_button(Translator.translate(
			"Donate…"), ShortcutUtils.fn("about_donate"), false,
			load("res://assets/icons/Heart.svg"), "about_donate"))
	buttons_arr.append(ContextPopup.create_button(Translator.translate(
			"GodSVG repository"), ShortcutUtils.fn("about_repo"), false,
			load("res://assets/icons/Link.svg"), "about_repo"))
	buttons_arr.append(ContextPopup.create_button(Translator.translate(
			"GodSVG website"), ShortcutUtils.fn("about_website"), false,
			load("res://assets/icons/Link.svg"), "about_website"))
	var separator_indices := PackedInt32Array([1, 3])
	if can_show_savedata_folder:
		separator_indices = PackedInt32Array([2, 4])
	
	var more_popup := ContextPopup.new()
	more_popup.setup(buttons_arr, true, -1, -1, separator_indices)
	HandlerGUI.popup_under_rect_center(more_popup, more_options.get_global_rect(),
			get_viewport())


func open_savedata_folder() -> void:
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"))


func update_size_button() -> void:
	var svg_text_size := State.svg_text.length()
	size_button.text = String.humanize_size(svg_text_size)
	size_button.tooltip_text = String.num_uint64(svg_text_size) + " B"
	if State.root_element.optimize(true):
		size_button.disabled = false
		size_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		update_size_button_colors()
	else:
		size_button.disabled = true
		size_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		size_button.remove_theme_color_override("font_color")

func update_size_button_colors() -> void:
	size_button.begin_bulk_theme_override()
	for theming in ["font_color", "font_hover_color", "font_pressed_color"]:
		size_button.add_theme_color_override(theming,
				Configs.savedata.basic_color_warning.lerp(Color.WHITE, 0.5))
	size_button.end_bulk_theme_override()
