extends VBoxContainer

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")

@onready var code_edit: TextEdit = $ScriptEditor/SVGCodeEdit
@onready var error_bar: PanelContainer = $ScriptEditor/ErrorBar
@onready var error_label: RichTextLabel = $ScriptEditor/ErrorBar/Label
@onready var size_label: Label = %SizeLabelContainer/SizeLabel
@onready var size_label_container: PanelContainer = %SizeLabelContainer
@onready var file_button: Button = %FileButton
@onready var options_button = $PanelContainer/CodeButtons/MetaActions/OptionsButton
@onready var optimize_button: Button = $PanelContainer/CodeButtons/OptimizeButton

func _ready() -> void:
	SVG.parsing_finished.connect(update_error)
	auto_update_text()
	update_size_label()
	update_file_button()
	setup_theme(false)
	setup_highlighter()
	code_edit.clear_undo_history()
	SVG.root_tag.attribute_changed.connect(auto_update_text.unbind(1))
	SVG.root_tag.child_attribute_changed.connect(auto_update_text.unbind(1))
	SVG.root_tag.tag_layout_changed.connect(auto_update_text)
	SVG.root_tag.changed_unknown.connect(auto_update_text)
	GlobalSettings.save_data.current_file_path_changed.connect(update_file_button)

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
			setup_theme(false)
	else:
		# When the error is shown, the code editor's theme is changed to match up.
		if not error_bar.visible:
			error_bar.show()
			error_label.text = tr(SVGParser.get_error_string(err_id))
			var error_bar_real_height := error_bar.size.y - 2
			code_edit.custom_minimum_size.y -= error_bar_real_height
			code_edit.size.y -= error_bar_real_height
			setup_theme(true)

func setup_theme(match_below: bool) -> void:
	code_edit.begin_bulk_theme_override()
	for theming in ["normal", "focus", "hover"]:
		var stylebox := get_theme_stylebox(theming, "TextEdit").duplicate()
		stylebox.corner_radius_top_right = 0
		stylebox.corner_radius_top_left = 0
		stylebox.border_width_top = 2
		if match_below:
			stylebox.corner_radius_bottom_right = 0
			stylebox.corner_radius_bottom_left = 0
			stylebox.border_width_bottom = 1
		code_edit.add_theme_stylebox_override(theming, stylebox)
	code_edit.end_bulk_theme_override()
	error_label.add_theme_color_override("default_color", GlobalSettings.basic_color_error)


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(code_edit.text)


func _on_import_button_pressed() -> void:
	SVG.open_import_dialog()

func _on_export_button_pressed() -> void:
	SVG.open_export_dialog()

func set_new_text(svg_text: String) -> void:
	code_edit.text = svg_text
	_on_code_edit_text_changed()  # Call it automatically yeah.


func _on_code_edit_text_changed() -> void:
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
	optimize_button.disabled = not SVG.root_tag.optimize(false)
	optimize_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if\
			optimize_button.disabled else Control.CURSOR_POINTING_HAND

func _on_svg_code_edit_focus_exited() -> void:
	code_edit.text = SVG.text
	if GlobalSettings.save_data.svg_text != code_edit.text:
		SVG.update_text(true)


func _on_optimize_button_pressed() -> void:
	SVG.root_tag.optimize()

func _on_file_button_pressed() -> void:
	var btn_array: Array[Button] = [Utils.create_btn(tr("Remove the association"),
			clear_file_path)]
	var context_popup := ContextPopup.instantiate()
	add_child(context_popup)
	context_popup.set_button_array(btn_array, false, file_button.size.x)
	Utils.popup_under_rect_center(context_popup, file_button.get_global_rect(),
			get_viewport())


func _on_options_button_pressed():
	var btn_array: Array[Button] = [Utils.create_btn("Copy All Text", _on_copy_button_pressed), Utils.create_btn("Reset SVG", reset_svg)]
	var context_popup := ContextPopup.instantiate()
	add_child(context_popup)
	context_popup.set_button_array(btn_array, false, options_button.size.x)
	Utils.popup_under_rect_center(context_popup, options_button.get_global_rect(), get_viewport())


func clear_file_path() -> void:
	GlobalSettings.modify_save_data("current_file_path", "")

func reset_svg() -> void:
	SVG.text = '<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg"></svg>'
	SVG.update_tags()

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.HIGHLIGHT_COLORS_CHANGED:
		setup_highlighter()

func setup_highlighter() -> void:
	if code_edit != null:
		var new_highlighter := SVGHighlighter.new()
		new_highlighter.symbol_color = GlobalSettings.highlighting_symbol_color
		new_highlighter.tag_color = GlobalSettings.highlighting_tag_color
		new_highlighter.attribute_color = GlobalSettings.highlighting_attribute_color
		new_highlighter.string_color = GlobalSettings.highlighting_string_color
		new_highlighter.comment_color = GlobalSettings.highlighting_comment_color
		new_highlighter.text_color = GlobalSettings.highlighting_text_color
		new_highlighter.error_color = GlobalSettings.highlighting_error_color
		code_edit.syntax_highlighter = new_highlighter
