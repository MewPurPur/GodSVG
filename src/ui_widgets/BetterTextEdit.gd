@icon("res://godot_only/icons/BetterTextEdit.svg")
class_name BetterTextEdit extends TextEdit
## A TextEdit with some improvements.

const caret_color = Color("defd")

var _surface := RenderingServer.canvas_item_create()
var _timer := Timer.new()

var _is_caret_queued_for_redraw := false

var _hovered := false

func _init() -> void:
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
	
	var char_size := ThemeUtils.mono_font.get_char_size(69,
			get_theme_font_size("font_size"))
	for caret in get_caret_count():
		var caret_pos := Vector2.ZERO
		var caret_column := get_caret_column(caret)
		var caret_line := get_caret_line(caret)
		
		if caret_column == 0:
			caret_pos = Vector2(get_theme_stylebox("normal").content_margin_left,
					get_rect_at_line_column(caret_line, caret_column).end.y) + Vector2(1, -2)
		else:
			var glyph_end := Vector2(get_rect_at_line_column(caret_line, caret_column).end)
			caret_pos = glyph_end + Vector2(1, -2)
			# Workaround for ligatures.
			var line := get_line(caret_line)
			if caret_column < line.length() and line[caret_column] == '\t':
				caret_pos = caret_pos
			elif glyph_end.x > 0 and glyph_end.y > 0:
				var chars_back := 0
				while line.length() > caret_column + chars_back and glyph_end ==\
				Vector2(get_rect_at_line_column(caret_line, caret_column + chars_back + 1).end):
					chars_back += 1
					caret_pos.x -= char_size.x
		# Determine the end of the caret and draw it.
		var caret_end := caret_pos
		if is_overtype_mode_enabled():
			caret_end.x += char_size.x
		else:
			caret_end.y -= char_size.y + 1
		RenderingServer.canvas_item_add_line(_surface, caret_pos, caret_end, caret_color, 1)

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


func _input(event: InputEvent) -> void:
	if (has_focus() and event is InputEventMouseButton and event.is_pressed() and\
	not get_global_rect().has_point(event.position) and HandlerGUI.popup_stack.is_empty()):
		release_focus()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		release_focus()
		return
	
	mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
	
	if event is InputEventMouseMotion and event.button_mask == 0:
		_hovered = true
		queue_redraw()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			grab_focus()
			var btn_arr: Array[Button] = []
			var separator_arr := PackedInt32Array()
			if editable:
				btn_arr.append(ContextPopup.create_button(
						Translator.translate("Undo"), undo,
						!has_undo(), load("res://visual/icons/Undo.svg"), "ui_undo"))
				btn_arr.append(ContextPopup.create_button(
						Translator.translate("Redo"), redo,
						!has_redo(), load("res://visual/icons/Redo.svg"), "ui_redo"))
				if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
					separator_arr = PackedInt32Array([2])
					btn_arr.append(ContextPopup.create_button(
							Translator.translate("Cut"), cut,
							text.is_empty(), load("res://visual/icons/Cut.svg"), "ui_cut"))
					btn_arr.append(ContextPopup.create_button(
							Translator.translate("Copy"), copy,
							text.is_empty(), load("res://visual/icons/Copy.svg"), "ui_copy"))
					btn_arr.append(ContextPopup.create_button(
							Translator.translate("Paste"), paste,
							!Utils.has_clipboard_web_safe(),
							load("res://visual/icons/Paste.svg"), "ui_paste"))
			else:
				btn_arr.append(ContextPopup.create_button(
						Translator.translate("Copy"), copy,
						text.is_empty(), load("res://visual/icons/Copy.svg"), "ui_copy"))
			
			var context_popup := ContextPopup.new()
			context_popup.setup(btn_arr, true, -1, separator_arr)
			var vp := get_viewport()
			HandlerGUI.popup_under_pos(context_popup, vp.get_mouse_position(), vp)
			accept_event()
			var click_pos := get_line_column_at_pos(event.position)
			set_caret_line(click_pos.y, false)
			set_caret_column(click_pos.x, false)
	else:
		# Set these inputs as handled, so the default UndoRedo doesn't eat them.
		if ShortcutUtils.is_action_pressed(event, "redo"):
			if has_redo():
				redo()
			accept_event()
		elif ShortcutUtils.is_action_pressed(event, "undo"):
			if has_undo():
				undo()
			accept_event()


func initialize_text(initial_text: String) -> void:
	text = initial_text
	clear_undo_history()
