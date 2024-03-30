## A TextEdit with some improvements.
@icon("res://visual/godot_only/BetterTextEdit.svg")
class_name BetterTextEdit extends TextEdit

const code_font = preload("res://visual/fonts/FontMono.ttf")
const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const caret_color = Color("defd")

var surface := RenderingServer.canvas_item_create()
var timer := Timer.new()

var hovered := false

func _init() -> void:
	context_menu_enabled = false
	wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	scroll_smooth = true
	scroll_v_scroll_speed = 30.0
	caret_multiple = false
	highlight_all_occurrences = true

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	add_child(timer)
	timer.timeout.connect(blink)
	get_v_scroll_bar().value_changed.connect(queue_redraw_caret.unbind(1))
	get_h_scroll_bar().value_changed.connect(queue_redraw_caret.unbind(1))
	mouse_exited.connect(_on_mouse_exited)


# Workaround for there not being a built-in overtype_mode_changed signal.
var overtype_mode := false
var is_caret_queued_for_redraw := false
func _process(_delta: float) -> void:
	if is_overtype_mode_enabled() != overtype_mode:
		overtype_mode = not overtype_mode
		redraw_caret()
	if is_caret_queued_for_redraw:
		redraw_caret()


func queue_redraw_caret() -> void:
	is_caret_queued_for_redraw = true

func redraw_caret() -> void:
	is_caret_queued_for_redraw = false
	blonk = false
	blink()
	timer.start(0.6)
	RenderingServer.canvas_item_clear(surface)
	if not has_focus():
		return
	
	var char_size := code_font.get_char_size(69, get_theme_font_size("font_size"))
	for caret in get_caret_count():
		var caret_line := get_caret_line(caret)
		var caret_column := get_caret_column(caret)
		var glyph_end := Vector2(get_rect_at_line_column(caret_line, caret_column).end)
		# Workaround for empty text.
		if glyph_end == Vector2.ZERO:
			glyph_end = Vector2(get_theme_stylebox("normal").content_margin_left,
					get_line_height() + 2)
		
		var caret_pos := glyph_end + Vector2(1, -2)
		# Workaround for ligatures.
		if glyph_end.x > 0 and glyph_end.y > 0:
			var chars_back := 0
			while get_line(caret_line).length() > caret_column + chars_back and glyph_end ==\
			Vector2(get_rect_at_line_column(caret_line, caret_column + chars_back + 1).end):
				chars_back += 1
				caret_pos.x -= char_size.x
		# Determine the end of the caret and draw it.
		var caret_end := caret_pos
		if is_overtype_mode_enabled():
			caret_end.x += char_size.x - 1
		else:
			caret_end.y -= char_size.y + 1
		RenderingServer.canvas_item_add_line(surface, caret_pos, caret_end, caret_color, 1)

var blonk := true
func blink() -> void:
	blonk = not blonk
	RenderingServer.canvas_item_set_visible(surface, blonk)

func _on_focus_entered() -> void:
	timer.start(0.6)

func _on_focus_exited() -> void:
	timer.stop()
	RenderingServer.canvas_item_clear(surface)

func _on_mouse_exited() -> void:
	hovered = false
	queue_redraw()

func _draw() -> void:
	if editable and hovered and has_theme_stylebox("hover"):
		draw_style_box(get_theme_stylebox("hover"), Rect2(Vector2.ZERO, size))

func _input(event: InputEvent) -> void:
	if (has_focus() and event is InputEventMouseButton and event.is_pressed() and\
	not get_global_rect().has_point(event.position)):
		release_focus()

func _gui_input(event: InputEvent) -> void:
	mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
	
	if event is InputEventMouseMotion and event.button_mask == 0:
		hovered = true
		queue_redraw()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			grab_focus()
			var context_popup := ContextPopup.instantiate()
			var btn_arr: Array[Button] = [
				Utils.create_btn(tr("Undo"), undo, !has_undo(),
						load("res://visual/icons/Undo.svg")),
				Utils.create_btn(tr("Redo"), redo, !has_redo(),
						load("res://visual/icons/Redo.svg")),
				Utils.create_btn(tr("Cut"), cut, text.is_empty(),
						load("res://visual/icons/Cut.svg")),
				Utils.create_btn(tr("Copy"), copy, text.is_empty(),
						load("res://visual/icons/Copy.svg")),
				Utils.create_btn(tr("Paste"), paste, !DisplayServer.clipboard_has(),
						load("res://visual/icons/Paste.svg")),
			]
			
			add_child(context_popup)
			context_popup.set_button_array(btn_arr, true, 72)
			var viewport := get_viewport()
			Utils.popup_under_pos(context_popup, viewport.get_mouse_position(), viewport)
			accept_event()
			var click_pos := get_line_column_at_pos(event.position)
			set_caret_line(click_pos.y, false)
			set_caret_column(click_pos.x, false)
	else:
		# Set these inputs as handled, so the default UndoRedo doesn't eat them.
		if event.is_action_pressed("redo"):
			if has_redo():
				redo()
			accept_event()
		elif event.is_action_pressed("undo"):
			if has_undo():
				undo()
			accept_event()
