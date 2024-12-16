extends VBoxContainer

@onready var panel_container: PanelContainer = $PanelContainer
@onready var code_edit: TextEdit = $ScriptEditor/SVGCodeEdit
@onready var error_bar: PanelContainer = $ScriptEditor/ErrorBar
@onready var error_label: RichTextLabel = $ScriptEditor/ErrorBar/Label
@onready var options_button: Button = %OptionsButton

func _ready() -> void:
	Configs.theme_changed.connect(setup_theme)
	SVG.parsing_finished.connect(update_error)
	Configs.highlighting_colors_changed.connect(update_syntax_highlighter)
	auto_update_text()
	setup_theme()
	update_syntax_highlighter()
	code_edit.clear_undo_history()
	SVG.changed.connect(auto_update_text)


func auto_update_text() -> void:
	if not code_edit.has_focus():
		code_edit.text = SVG.text
		code_edit.clear_undo_history()

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
			Configs.savedata.theme_config.basic_color_error)
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


func _on_svg_code_edit_text_changed() -> void:
	SVG.set_text(code_edit.text)
	SVG.sync_elements()

func _on_svg_code_edit_focus_exited() -> void:
	SVG.queue_save()
	code_edit.text = SVG.text

func _on_svg_code_edit_focus_entered() -> void:
	Indications.clear_all_selections()


func _on_options_button_pressed() -> void:
	var btn_array: Array[Button] = []
	btn_array.append(ContextPopup.create_button(
			Translator.translate("Copy all text"), ShortcutUtils.fn("copy_svg_text"),
			false, load("res://visual/icons/Copy.svg"), "copy_svg_text"))
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true)
	HandlerGUI.popup_under_rect_center(context_popup, options_button.get_global_rect(),
			get_viewport())


func update_syntax_highlighter() -> void:
	if is_instance_valid(code_edit):
		code_edit.syntax_highlighter = Configs.savedata.theme_config.highlighter_config.\
				generate_highlighter()
