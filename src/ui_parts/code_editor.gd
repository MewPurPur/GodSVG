extends VBoxContainer

signal optimize_button_enable_updated(is_optimize_enabled: bool)

@onready var panel_container: PanelContainer = $PanelContainer
@onready var code_edit: TextEdit = $ScriptEditor/SVGCodeEdit
@onready var error_bar: PanelContainer = $ScriptEditor/ErrorBar
@onready var error_label: RichTextLabel = $ScriptEditor/ErrorBar/Label
@onready var size_label: Label = %SizeLabelContainer/SizeLabel
@onready var size_label_container: PanelContainer = %SizeLabelContainer
@onready var file_button: Button = %FileButton
@onready var optimize_button: Button = $PanelContainer/CodeButtons/OptimizeButton

@onready var options_button: Button = %MetaActions/OptionsButton
@onready var import_button: Button = %MetaActions/ImportButton
@onready var export_button: Button = %MetaActions/ExportButton

func _ready() -> void:
	SVG.parsing_finished.connect(update_error)
	auto_update_text()
	update_size_label()
	update_file_button()
	setup_theme()
	setup_highlighter()
	code_edit.clear_undo_history()
	SVG.root_tag.attribute_changed.connect(auto_update_text.unbind(1))
	SVG.root_tag.child_attribute_changed.connect(auto_update_text.unbind(1))
	SVG.root_tag.tag_layout_changed.connect(auto_update_text)
	SVG.root_tag.changed_unknown.connect(auto_update_text)
	GlobalSettings.save_data.current_file_path_changed.connect(update_file_button)
	import_button.pressed.connect(ShortcutUtils.fn("import"))
	export_button.pressed.connect(ShortcutUtils.fn("export"))
	optimize_button.pressed.connect(ShortcutUtils.fn("optimize"))


func _notification(what: int) -> void:
	if what == Utils.CustomNotification.HIGHLIGHT_COLORS_CHANGED:
		setup_highlighter()
	elif what == Utils.CustomNotification.THEME_CHANGED:
		setup_theme()


func auto_update_text() -> void:
	if not code_edit.has_focus():
		code_edit.text = SVG.text
		code_edit.clear_undo_history()
	update_size_label()
	update_optimize_button()

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
	
	error_label.add_theme_color_override("default_color", GlobalSettings.basic_color_error)
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


func set_new_text(svg_text: String) -> void:
	code_edit.text = svg_text
	_on_svg_code_edit_text_changed()  # Call it automatically yeah.

func _on_svg_code_edit_text_changed() -> void:
	SVG.text = code_edit.text
	SVG.update_tags()


func update_size_label() -> void:
	var svg_text_size := SVG.text.length()
	size_label.text = String.humanize_size(svg_text_size)
	size_label_container.tooltip_text = String.num_uint64(svg_text_size) + " B"

func update_file_button() -> void:
	var file_path := GlobalSettings.save_data.current_file_path
	file_button.visible = !file_path.is_empty()
	file_button.text = file_path.get_file()
	file_button.tooltip_text = file_path.get_file()
	Utils.set_max_text_width(file_button, 140.0, 12.0)
	if not file_path.is_empty():
		get_window().title = file_path.get_file() + " - GodSVG"
	else:
		get_window().title = "GodSVG"


func update_optimize_button() -> void:
	var enabled: bool = SVG.root_tag.optimize(true)
	optimize_button.disabled = not enabled
	optimize_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if\
			optimize_button.disabled else Control.CURSOR_POINTING_HAND
	optimize_button_enable_updated.emit(enabled)


func _on_svg_code_edit_focus_exited() -> void:
	code_edit.text = SVG.text
	if GlobalSettings.save_data.svg_text != code_edit.text:
		SVG.update_text(true)

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


func setup_highlighter() -> void:
	if is_instance_valid(code_edit):
		var new_highlighter := SVGHighlighter.new()
		new_highlighter.symbol_color = GlobalSettings.highlighting_symbol_color
		new_highlighter.tag_color = GlobalSettings.highlighting_tag_color
		new_highlighter.attribute_color = GlobalSettings.highlighting_attribute_color
		new_highlighter.string_color = GlobalSettings.highlighting_string_color
		new_highlighter.comment_color = GlobalSettings.highlighting_comment_color
		new_highlighter.text_color = GlobalSettings.highlighting_text_color
		new_highlighter.cdata_color = GlobalSettings.highlighting_cdata_color
		new_highlighter.error_color = GlobalSettings.highlighting_error_color
		new_highlighter.setup_extra_colors()
		code_edit.syntax_highlighter = new_highlighter
