extends VBoxContainer

@onready var panel_container: PanelContainer = $PanelContainer
@onready var code_edit: TextEdit = $ScriptEditor/SVGCodeEdit
@onready var error_bar: PanelContainer = $ScriptEditor/ErrorBar
@onready var error_label: RichTextLabel = $ScriptEditor/ErrorBar/Label
@onready var options_button: Button = %MetaActions/OptionsButton

func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("copy_svg_text", func() -> void: DisplayServer.clipboard_set(State.svg_text))
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	options_button.pressed.connect(_on_options_button_pressed)
	code_edit.text_changed.connect(_on_svg_code_edit_text_changed)
	code_edit.focus_entered.connect(_on_svg_code_edit_focus_entered)
	code_edit.focus_exited.connect(_on_svg_code_edit_focus_exited)
	Configs.theme_changed.connect(sync_theming)
	sync_theming()
	State.parsing_finished.connect(react_to_last_parsing)
	react_to_last_parsing()
	Configs.highlighting_colors_changed.connect(update_syntax_highlighter)
	update_syntax_highlighter()
	Configs.basic_colors_changed.connect(sync_basic_colors)
	sync_basic_colors()
	code_edit.clear_undo_history()
	State.svg_changed.connect(sync_text_from_svg)
	sync_text_from_svg()


func sync_text_from_svg() -> void:
	if not code_edit.has_focus():
		if error_bar.visible:
			error_bar.hide()
			sync_theming()
		code_edit.text = State.stable_editor_markup
		code_edit.clear_undo_history()

func react_to_last_parsing() -> void:
	if State.last_parse_error == SVGParser.ParseError.OK:
		if error_bar.visible:
			error_bar.hide()
			sync_theming()
		return
	# When the error is shown, the code editor's theme is changed to match up.
	if not code_edit.has_focus():
		code_edit.text = State.unstable_markup
		code_edit.grab_focus()
	if not error_bar.visible:
		error_bar.show()
		error_label.text = SVGParser.get_parsing_error_string(State.last_parse_error)
		sync_theming()

func sync_theming() -> void:
	# Set up the code edit.
	code_edit.begin_bulk_theme_override()
	const CONST_ARR_1: PackedStringArray = ["normal", "focus", "hover"]
	for theme_type in CONST_ARR_1:
		var stylebox := get_theme_stylebox(theme_type, "TextEdit").duplicate()
		stylebox.corner_radius_top_right = 0
		stylebox.corner_radius_top_left = 0
		stylebox.border_width_top = 2
		stylebox.bg_color = ThemeUtils.text_edit_alternative_inner_color
		if error_bar.visible:
			stylebox.corner_radius_bottom_right = 0
			stylebox.corner_radius_bottom_left = 0
			stylebox.border_width_bottom = 1
		code_edit.add_theme_stylebox_override(theme_type, stylebox)
	code_edit.end_bulk_theme_override()
	# Make it so the scrollbar doesn't overlap with the code editor's border.
	var scrollbar := code_edit.get_v_scroll_bar()
	scrollbar.begin_bulk_theme_override()
	const CONST_ARR_2: PackedStringArray = ["grabber", "grabber_highlight", "grabber_pressed"]
	for theme_type in CONST_ARR_2:
		var stylebox := get_theme_stylebox(theme_type, "VScrollBar").duplicate()
		# TODO No idea why I need to adjust it for the TextEdit, maybe a Godot issue.
		stylebox.expand_margin_right = -2.0
		stylebox.expand_margin_bottom = 2.0
		scrollbar.add_theme_stylebox_override(theme_type, stylebox)
	var bg_stylebox := get_theme_stylebox("scroll", "VScrollBar").duplicate()
	bg_stylebox.expand_margin_right = -2.0
	bg_stylebox.expand_margin_bottom = 2.0
	bg_stylebox.content_margin_left += 1.0
	bg_stylebox.content_margin_right += 1.0
	scrollbar.add_theme_stylebox_override("scroll", bg_stylebox)
	scrollbar.end_bulk_theme_override()
	
	error_label.add_theme_color_override("default_color", Configs.savedata.basic_color_error)
	var panel_stylebox := get_theme_stylebox("panel", "PanelContainer")
	# Set up the top panel.
	var top_stylebox := panel_stylebox.duplicate()
	top_stylebox.border_color = ThemeUtils.subtle_panel_border_color
	top_stylebox.border_width_bottom = 0
	top_stylebox.corner_radius_bottom_right = 0
	top_stylebox.corner_radius_bottom_left = 0
	top_stylebox.content_margin_left = 8.0
	top_stylebox.content_margin_right = 6.0
	top_stylebox.content_margin_top = 3.0
	top_stylebox.content_margin_bottom = 1.0
	panel_container.add_theme_stylebox_override("panel", top_stylebox)
	# Set up the bottom panel.
	var bottom_stylebox := panel_stylebox.duplicate()
	bottom_stylebox.border_color = ThemeUtils.subtle_panel_border_color
	bottom_stylebox.corner_radius_top_right = 0
	bottom_stylebox.corner_radius_top_left = 0
	bottom_stylebox.content_margin_left = 10.0
	bottom_stylebox.content_margin_right = 8.0
	bottom_stylebox.content_margin_top = -1
	bottom_stylebox.content_margin_bottom = -1
	error_bar.add_theme_stylebox_override("panel", bottom_stylebox)

func sync_basic_colors() -> void:
	error_label.add_theme_color_override("default_color", Configs.savedata.basic_color_error)


func _on_svg_code_edit_text_changed() -> void:
	State.apply_markup(code_edit.text, true)

func _on_svg_code_edit_focus_entered() -> void:
	State.clear_all_selections()

func _on_svg_code_edit_focus_exited() -> void:
	State.save_svg()
	if not State.stable_editor_markup.is_empty():
		State.apply_markup(State.stable_editor_markup, true)


func _on_options_button_pressed() -> void:
	var btn_array: Array[Button] = []
	btn_array.append(ContextPopup.create_shortcut_button("copy_svg_text"))
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_array, true)
	HandlerGUI.popup_under_rect_center(context_popup, options_button.get_global_rect(), get_viewport())


func update_syntax_highlighter() -> void:
	if is_instance_valid(code_edit):
		code_edit.syntax_highlighter = SVGHighlighter.new()
