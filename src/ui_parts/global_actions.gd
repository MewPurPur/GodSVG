extends HBoxContainer

@onready var import_button: Button = $RightSide/ImportButton
@onready var export_button: Button = $RightSide/ExportButton
@onready var more_options: Button = $LeftSide/MoreOptions
@onready var settings_button: Button = $LeftSide/SettingsButton
@onready var size_button: Button = $RightSide/SizeButton
@onready var file_button: Button = $RightSide/FileButton

func update_translations() -> void:
	import_button.tooltip_text = Translator.translate("Import")
	export_button.tooltip_text = Translator.translate("Export")
	settings_button.tooltip_text = Translator.translate("Settings")
	update_file_button()

func _ready() -> void:
	Configs.language_changed.connect(update_translations)
	update_translations()
	
	State.svg_changed.connect(update_size_button)
	Configs.active_tab_file_path_changed.connect(update_file_button)
	Configs.active_tab_changed.connect(update_file_button)
	Configs.basic_colors_changed.connect(update_size_button_colors)
	update_file_button()
	
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
	file_button.pressed.connect(_on_file_button_pressed)
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

func _on_file_button_pressed() -> void:
	var btn_array: Array[Button] = []
	btn_array.append(ContextPopup.create_button(Translator.translate("Save SVG"),
			FileUtils.save_svg, false, load("res://assets/icons/Save.svg"), "save"))
	btn_array.append(ContextPopup.create_button(Translator.translate("Save SVG as…"),
			FileUtils.save_svg_as, false, load("res://assets/icons/Save.svg"), "save_as"))
	btn_array.append(ContextPopup.create_button(Translator.translate("Reset SVG"),
			ShortcutUtils.fn("reset_svg"),
			FileUtils.compare_svg_to_disk_contents() != FileUtils.FileState.DIFFERENT,
			load("res://assets/icons/Reload.svg"), "reset_svg"))
	btn_array.append(ContextPopup.create_button(Translator.translate("Open externally"),
			ShortcutUtils.fn("open_externally"),
			not FileAccess.file_exists(Configs.savedata.get_active_tab().svg_file_path),
			load("res://assets/icons/OpenFile.svg"), "open_externally"))
	btn_array.append(ContextPopup.create_button(Translator.translate("Show in File Manager"),
			ShortcutUtils.fn("open_in_folder"),
			not FileAccess.file_exists(Configs.savedata.get_active_tab().svg_file_path),
			load("res://assets/icons/OpenFolder.svg"), "open_in_folder"))
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true, file_button.size.x, -1, PackedInt32Array([2]))
	HandlerGUI.popup_under_rect_center(context_popup, file_button.get_global_rect(),
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
	
	var antialias_fraction := 0.25
	var final_size := 16
	var first_resizing_size := final_size / antialias_fraction
	var svg_buffer := FileAccess.get_file_as_bytes("res://assets/logos/icon.svg")
	var about_image := Image.new()
	about_image.load_svg_from_buffer(svg_buffer)
	var factor := minf(first_resizing_size / about_image.get_width(),
			first_resizing_size / about_image.get_height())
	about_image.load_svg_from_buffer(svg_buffer, factor)
	about_image.resize(final_size, final_size, Image.INTERPOLATE_LANCZOS)
	
	var about_btn := ContextPopup.create_button(Translator.translate("About…"),
			ShortcutUtils.fn("about_info"), false,
			ImageTexture.create_from_image(about_image), "about_info")
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

func update_file_button() -> void:
	var file_name := State.transient_tab_path.get_file() if\
			not State.transient_tab_path.is_empty() else\
			Configs.savedata.get_active_tab().get_presented_name()
	file_button.text = file_name
	file_button.tooltip_text = file_name
	Utils.set_max_text_width(file_button, 140.0, 12.0)
