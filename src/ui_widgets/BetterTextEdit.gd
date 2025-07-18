@icon("res://godot_only/icons/BetterTextEdit.svg")
class_name BetterTextEdit extends TextEdit
## A TextEdit with some improvements.

@export var show_line_numbers := true
var _line_gutter_needed_space: int

var _surface := RenderingServer.canvas_item_create()
var _timer := Timer.new()

var _is_caret_queued_for_redraw := false

var _hovered := false

func _init() -> void:
	# Solves an issue where Ctrl+S would type an "s" and handle the input.
	# We want anything with Ctrl to not be handled, but other keys to still be handled.
	set_process_unhandled_key_input(false)
	
	context_menu_enabled = false
	wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	scroll_smooth = true
	scroll_v_scroll_speed = 30.0
	caret_multiple = false
	highlight_all_occurrences = true
	set_tab_size(2)

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(_surface, get_canvas_item())
	add_child(_timer)
	_timer.timeout.connect(blink)
	get_v_scroll_bar().value_changed.connect(queue_redraw_caret.unbind(1))
	get_h_scroll_bar().value_changed.connect(queue_redraw_caret.unbind(1))
	mouse_exited.connect(_on_base_class_mouse_exited)
	focus_entered.connect(_on_base_class_focus_entered)
	focus_exited.connect(_on_base_class_focus_exited)
	caret_changed.connect(queue_redraw_caret)
	# Add gutter for line numbers.
	if show_line_numbers:
		text_changed.connect(recalibrate_line_gutter)
		text_set.connect(recalibrate_line_gutter)
		recalibrate_line_gutter()

func recalibrate_line_gutter() -> void:
	if get_gutter_count() == 1:
		remove_gutter(0)
	add_gutter(0)
	set_gutter_name(0, "line_numbers")
	set_gutter_type(0, GUTTER_TYPE_CUSTOM)
	set_gutter_custom_draw(0, _line_number_draw_callback)
	set_gutter_clickable(0, false)
	var max_digits := floori(log(get_line_count()) / log(10) + 1.0)
	_line_gutter_needed_space = int(max_digits * get_theme_font("font").get_char_size(69,
			get_theme_font_size("font_size")).x) + 11
	set_gutter_width(0, _line_gutter_needed_space)

func _line_number_draw_callback(line: int, _gutter: int, region: Rect2) -> void:
	if not Rect2(Vector2.ZERO, size).intersects(region):
		return
	
	var line_number_text := String.num_int64(line + 1)
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	
	# Center vertically, align to the left of the gutter.
	var text_pos := Vector2(-5,
			region.get_center().y + font.get_ascent(font_size) - font.get_string_size(
			line_number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).y / 2)
	draw_string(font, text_pos, line_number_text, HORIZONTAL_ALIGNMENT_RIGHT,
			_line_gutter_needed_space, font_size, ThemeUtils.dimmer_text_color)


func _exit_tree() -> void:
	RenderingServer.free_rid(_surface)

# Workaround for there not being a built-in overtype_mode_changed signal.
var overtype_mode := false
func _process(_delta: float) -> void:
	if is_overtype_mode_enabled() != overtype_mode:
		overtype_mode = not overtype_mode
		queue_redraw_caret()


func queue_redraw_caret() -> void:
	_redraw_caret.call_deferred()
	_is_caret_queued_for_redraw = true

func _redraw_caret() -> void:
	if not _is_caret_queued_for_redraw:
		return
	
	_is_caret_queued_for_redraw = false
	_blonk = false
	blink()
	_timer.start(0.6)
	RenderingServer.canvas_item_clear(_surface)
	if not has_focus():
		return
	
	var char_size := ThemeUtils.mono_font.get_char_size(69, get_theme_font_size("font_size"))
	for caret in get_caret_count():
		var caret_pos := Vector2.ZERO
		var caret_column := get_caret_column(caret)
		var caret_line := get_caret_line(caret)
		
		if caret_column == 0:
			var rect := get_rect_at_line_column(caret_line, caret_column)
			caret_pos = Vector2(rect.position.x + 1, rect.end.y - 2)
		else:
			var glyph_end := Vector2(get_rect_at_line_column(caret_line, caret_column).end)
			caret_pos = Vector2(glyph_end.x + 1, glyph_end.y - 2)
			var line := get_line(caret_line)
			# Workaround for indent_wrapped_lines.
			if get_line_wrap_index_at_column(caret_line, caret_column) >= 1:
				var i := 0
				while true:
					var c := line[i]
					if c == ' ':
						caret_pos.x += char_size.x
					elif c == '\t':
						caret_pos.x += char_size.x * get_tab_size()
					else:
						break
					i += 1
			# Workaround for ligatures.
			if (caret_column >= line.length() or line[caret_column] != '\t') and\
			glyph_end.x > 0 and glyph_end.y > 0:
				var chars_back := 0
				while line.length() > caret_column + chars_back and glyph_end ==\
				Vector2(get_rect_at_line_column(caret_line, caret_column + chars_back + 1).end):
					chars_back += 1
					caret_pos.x -= char_size.x
		# Determine the end of the caret and draw it.
		var caret_end := caret_pos
		if is_overtype_mode_enabled():
			var char_width: float
			if caret_column >= get_line(caret_line).length():
				char_width = char_size.x
			else:
				char_width = get_rect_at_line_column(caret_line, caret_column + 1).size.x
			caret_end.x += char_width
		else:
			caret_end.y -= char_size.y + 1
		RenderingServer.canvas_item_add_line(_surface, caret_pos, caret_end,
				ThemeUtils.caret_color, 1)

var _blonk := true
func blink() -> void:
	_blonk = not _blonk
	RenderingServer.canvas_item_set_visible(_surface, _blonk)

func _on_base_class_focus_entered() -> void:
	_timer.start(0.6)

func _on_base_class_focus_exited() -> void:
	_timer.stop()
	RenderingServer.canvas_item_clear(_surface)

func _on_base_class_mouse_exited() -> void:
	_hovered = false
	queue_redraw()

func _draw() -> void:
	if editable and _hovered and has_theme_stylebox("hover"):
		draw_style_box(get_theme_stylebox("hover"), Rect2(Vector2.ZERO, size))
	
	if get_gutter_count() == 1:
		var col := ThemeUtils.subtle_text_color
		col.a *= 0.4
		draw_line(Vector2(_line_gutter_needed_space, 0),
				Vector2(_line_gutter_needed_space, size.y), col)


func _input(event: InputEvent) -> void:
	if (has_focus() and event is InputEventMouseButton and (event.button_index in\
	[MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]) and\
	event.is_pressed() and not get_global_rect().has_point(event.position) and\
	HandlerGUI.popup_stack.is_empty()):
		release_focus()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("select_all"):
		select_all()
		accept_event()
		return
	
	if event.is_action_pressed("ui_cancel"):
		release_focus()
		return
	
	mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
	
	if event is InputEventMouseMotion and event.button_mask == 0:
		_hovered = true
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			grab_focus()
			var btn_arr: Array[Button] = []
			var separator_arr := PackedInt32Array()
			
			var is_text_empty := text.is_empty()
			
			if editable:
				btn_arr.append(ContextPopup.create_shortcut_button("ui_undo", not has_undo()))
				btn_arr.append(ContextPopup.create_shortcut_button("ui_redo", not has_redo()))
				if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
					separator_arr = PackedInt32Array([2])
					btn_arr.append(ContextPopup.create_shortcut_button("ui_cut", is_text_empty))
					btn_arr.append(ContextPopup.create_shortcut_button("ui_copy", is_text_empty))
					btn_arr.append(ContextPopup.create_shortcut_button("ui_paste",
							not Utils.has_clipboard_web_safe()))
			else:
				btn_arr.append(ContextPopup.create_shortcut_button("ui_copy", is_text_empty))
			
			var context_popup := ContextPopup.new()
			context_popup.setup(btn_arr, true, -1, -1, separator_arr)
			var vp := get_viewport()
			HandlerGUI.popup_under_pos(context_popup, vp.get_mouse_position(), vp)
			accept_event()
			var click_pos := get_line_column_at_pos(event.position)
			set_caret_line(click_pos.y, false)
			set_caret_column(click_pos.x, false)
	else:
		# Set these inputs as handled, so the default UndoRedo doesn't eat them.
		if ShortcutUtils.is_action_pressed(event, "ui_redo"):
			if has_redo():
				redo()
			accept_event()
		elif ShortcutUtils.is_action_pressed(event, "ui_undo"):
			if has_undo():
				undo()
			accept_event()


func initialize_text(initial_text: String) -> void:
	text = initial_text
	clear_undo_history()
