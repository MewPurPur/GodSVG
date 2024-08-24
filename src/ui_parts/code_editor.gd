extends VBoxContainer

@onready var panel_container: PanelContainer = $PanelContainer
@onready var code_edit: TextEdit = $ScriptEditor/SVGCodeEdit
@onready var error_bar: PanelContainer = $ScriptEditor/ErrorBar
@onready var error_label: RichTextLabel = $ScriptEditor/ErrorBar/Label
@onready var size_button: Button = %SizeButton
@onready var file_button: Button = %FileButton

@onready var options_button: Button = %MetaActions/OptionsButton
@onready var import_button: Button = %MetaActions/ImportButton
@onready var export_button: Button = %MetaActions/ExportButton

func _ready() -> void:
	GlobalSettings.theme_changed.connect(setup_theme)
	SVG.parsing_finished.connect(update_error)
	GlobalSettings.highlighting_colors_changed.connect(update_syntax_highlighter)
	auto_update_text()
	update_size_button()
	update_file_button()
	setup_theme()
	update_syntax_highlighter()
	code_edit.clear_undo_history()
	SVG.changed.connect(auto_update_text)
	GlobalSettings.file_path_changed.connect(update_file_button)
	import_button.pressed.connect(ShortcutUtils.fn("import"))
	export_button.pressed.connect(ShortcutUtils.fn("export"))
	# Fix the size button sizing.
	for theming in ["normal", "hover", "pressed", "disabled"]:
		var stylebox := size_button.get_theme_stylebox(theming).duplicate()
		stylebox.content_margin_bottom = 0
		stylebox.content_margin_top = 0
		size_button.add_theme_stylebox_override(theming, stylebox)


func auto_update_text() -> void:
	if not code_edit.has_focus():
		code_edit.text = SVG.text
		code_edit.clear_undo_history()
	update_size_button()

func update_error(err_id: SVGParser.ParseError) -> void:
	if err_id == SVGParser.ParseError.OK:
		if error_bar.visible:
			error_bar.hide()
			var error_bar_real_height := error_bar.size.y - 2
			code_edit.custom_minimum_size.y += error_bar_real_height
			code_edit.size.y += error_bar_real_height
			setup_theme()
	else:
		# When the error is shown, the code editor's theme is changed to match up.
		if not error_bar.visible:
			error_bar.show()
			error_label.text = SVGParser.get_error_string(err_id)
			var error_bar_real_height := error_bar.size.y - 2
			code_edit.custom_minimum_size.y -= error_bar_real_height
			code_edit.size.y -= error_bar_real_height
			setup_theme()

func setup_theme() -> void:
	# Set up the code edit.
	code_edit.begin_bulk_theme_override()
	for theming in ["normal", "focus", "hover"]:
		var stylebox := get_theme_stylebox(theming, "TextEdit").duplicate()
		stylebox.corner_radius_top_right = 0
		stylebox.corner_radius_top_left = 0
		stylebox.border_width_top = 2
		if error_bar.visible:
			stylebox.corner_radius_bottom_right = 0
			stylebox.corner_radius_bottom_left = 0
			stylebox.border_width_bottom = 1
		code_edit.add_theme_stylebox_override(theming, stylebox)
	code_edit.end_bulk_theme_override()
	# Make it so the scrollbar doesn't overlap with the code editor's border.
	var scrollbar := code_edit.get_v_scroll_bar()
	scrollbar.begin_bulk_theme_override()
	for theming in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var stylebox := get_theme_stylebox(theming, "VScrollBar").duplicate()
		stylebox.expand_margin_right = -2.0
		scrollbar.add_theme_stylebox_override(theming, stylebox)
	var bg_stylebox := get_theme_stylebox("scroll", "VScrollBar").duplicate()
	bg_stylebox.expand_margin_right = -2.0
	bg_stylebox.content_margin_left += 1.0
	bg_stylebox.content_margin_right += 1.0
	scrollbar.add_theme_stylebox_override("scroll", bg_stylebox)
	scrollbar.end_bulk_theme_override()
	
	error_label.add_theme_color_override("default_color",
			GlobalSettings.savedata.basic_color_error)
	var panel_stylebox := get_theme_stylebox("panel", "PanelContainer")
	# Set up the top panel.
	var top_stylebox := panel_stylebox.duplicate()
	top_stylebox.border_color = code_edit.get_theme_stylebox("normal").border_color
	top_stylebox.border_width_bottom = 0
	top_stylebox.corner_radius_bottom_right = 0
	top_stylebox.corner_radius_bottom_left = 0
	top_stylebox.content_margin_left = 8
	top_stylebox.content_margin_right = 6
	top_stylebox.content_margin_top = 3
	top_stylebox.content_margin_bottom = 1
	panel_container.add_theme_stylebox_override("panel", top_stylebox)
	# Set up the bottom panel.
	var bottom_stylebox := panel_stylebox.duplicate()
	bottom_stylebox.border_color = code_edit.get_theme_stylebox("normal").border_color
	bottom_stylebox.corner_radius_top_right = 0
	bottom_stylebox.corner_radius_top_left = 0
	bottom_stylebox.content_margin_left = 10
	bottom_stylebox.content_margin_right = 8
	bottom_stylebox.content_margin_top = -1
	bottom_stylebox.content_margin_bottom = -1
	error_bar.add_theme_stylebox_override("panel", bottom_stylebox)


func update_size_button() -> void:
	var svg_text_size := SVG.text.length()
	size_button.text = String.humanize_size(svg_text_size)
	size_button.tooltip_text = String.num_uint64(svg_text_size) + " B"
	if SVG.root_element.optimize(true):
		size_button.disabled = false
		size_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for theming in ["font_color", "font_hover_color", "font_pressed_color"]:
			size_button.add_theme_color_override(theming,
					Color.WHITE * 0.5 + GlobalSettings.savedata.basic_color_warning * 0.5)
	else:
		size_button.disabled = true
		size_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		size_button.remove_theme_color_override("font_color")

func update_file_button() -> void:
	var file_path := GlobalSettings.savedata.current_file_path
	file_button.visible = !file_path.is_empty()
	file_button.text = file_path.get_file()
	file_button.tooltip_text = file_path.get_file()
	Utils.set_max_text_width(file_button, 140.0, 12.0)


func _on_svg_code_edit_text_changed() -> void:
	SVG.set_text(code_edit.text)
	SVG.sync_elements()

func _on_svg_code_edit_focus_exited() -> void:
	SVG.queue_save()
	code_edit.text = SVG.text

func _on_svg_code_edit_focus_entered() -> void:
	Indications.clear_all_selections()


func _on_file_button_pressed() -> void:
	var btn_array: Array[Button] = []
	btn_array.append(ContextPopup.create_button(TranslationServer.translate("Save SVG"),
			FileUtils.open_save_dialog.bind("svg", FileUtils.native_file_save,
			FileUtils.save_svg_to_file), false, load("res://visual/icons/Save.svg"), "save"))
	btn_array.append(ContextPopup.create_button(TranslationServer.translate("Reset SVG"),
			ShortcutUtils.fn("reset_svg"), FileUtils.does_svg_data_match_disk_contents(),
			load("res://visual/icons/Reload.svg"), "reset_svg"))
	btn_array.append(ContextPopup.create_button(
			TranslationServer.translate("Clear saving path"),
			ShortcutUtils.fn("clear_file_path"), false, load("res://visual/icons/Clear.svg"),
			"clear_file_path"))
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true, file_button.size.x)
	HandlerGUI.popup_under_rect_center(context_popup, file_button.get_global_rect(),
			get_viewport())

func _on_size_button_pressed() -> void:
	var btn_array: Array[Button] = [
		ContextPopup.create_button(TranslationServer.translate("Optimize"),
				ShortcutUtils.fn("optimize"), false, load("res://visual/icons/Compress.svg"),
				"optimize")]
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true)
	HandlerGUI.popup_under_rect_center(context_popup, size_button.get_global_rect(),
			get_viewport())


func _on_options_button_pressed() -> void:
	var btn_array: Array[Button] = []
	btn_array.append(ContextPopup.create_button(
			TranslationServer.translate("Copy all text"), ShortcutUtils.fn("copy_svg_text"),
			false, load("res://visual/icons/Copy.svg"), "copy_svg_text"))
	btn_array.append(ContextPopup.create_button(
			TranslationServer.translate("Clear SVG"), ShortcutUtils.fn("clear_svg"),
			SVG.text == SVG.DEFAULT, load("res://visual/icons/Clear.svg"), "clear_svg"))
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true)
	HandlerGUI.popup_under_rect_center(context_popup, options_button.get_global_rect(),
			get_viewport())


func update_syntax_highlighter() -> void:
	if is_instance_valid(code_edit):
		code_edit.syntax_highlighter = GlobalSettings.generate_highlighter()
