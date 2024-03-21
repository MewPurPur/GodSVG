## A TextEdit with some improvements.
@icon("res://visual/godot_only/BetterTextEdit.svg")
class_name BetterTextEdit extends TextEdit

const code_font = preload("res://visual/fonts/FontMono.ttf")
const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const caret_color = Color("defd")

var surface := RenderingServer.canvas_item_create()
var timer := Timer.new()

var hovered := false

@export var block_non_ascii: bool  ## Blocks non-ASCII characters.

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
	get_v_scroll_bar().value_changed.connect(redraw_caret.unbind(1))
	get_h_scroll_bar().value_changed.connect(redraw_caret.unbind(1))
	mouse_exited.connect(_on_mouse_exited)


# Workaround for there not being a built-in overtype_mode_changed signal.
var overtype_mode := false
func _process(_delta: float) -> void:
	if is_overtype_mode_enabled() != overtype_mode:
		overtype_mode = not overtype_mode
		redraw_caret()

func redraw_caret() -> void:
	await get_tree().process_frame  # Buggy with backspace otherwise, likely a Godot bug.
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
		var rect: Rect2 = get_rect_at_line_column(caret_line, caret_column)
		var caret_pos := rect.end + Vector2(1, -2)
		# Workaround for ligatures.
		var chars_back := 0
		while get_line(caret_line).length() > caret_column + chars_back and\
		rect == Rect2(get_rect_at_line_column(caret_line, caret_column + chars_back + 1)):
			chars_back += 1
			caret_pos.x -= char_size.x
		
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
				Utils.create_btn(tr("Copy"), copy, text.is_empty(),
						load("res://visual/icons/Copy.svg")),
				Utils.create_btn(tr("Paste"), paste, !DisplayServer.clipboard_has(),
						load("res://visual/icons/Paste.svg")),
				Utils.create_btn(tr("Cut"), cut, text.is_empty(),
						load("res://visual/icons/Cut.svg")),
			]
			
			add_child(context_popup)
			context_popup.set_button_array(btn_arr, true, 72)
			var viewport := get_viewport()
			Utils.popup_under_pos(context_popup, viewport.get_mouse_position(), viewport)
			accept_event()
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


# I'd prefer to block non-ASCII inputs in SVG code. SVG syntax is ASCII-only, and while
# text blocks and comments allow non-ASCII, they are still difficult to deal with
# because they are 2-4 bytes long. <text> tags make the situation a whole lot harder,
# but for now they are not supported. Maybe in some future version I'll have them
# be translated directly into paths or have an abstraction over them, I don't know.
# Either way, not planning to support UTF-8, so I block it if the user tries to type it.
func _handle_unicode_input(unicode_char: int, caret_index: int) -> void:
	if (block_non_ascii and unicode_char <= 127) or not block_non_ascii:
		insert_text_at_caret(char(unicode_char), caret_index)
