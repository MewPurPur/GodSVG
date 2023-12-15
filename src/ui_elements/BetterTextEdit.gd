## A TextEdit that doesn't fully redraw on caret blink and has a custom context menu.
class_name BetterTextEdit extends TextEdit

const code_font = preload("res://visual/fonts/FontMono.ttf")
const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const caret_color = Color("defd")

var surface := RenderingServer.canvas_item_create()
var timer := Timer.new()

var hovered := false

@export var hover_stylebox: StyleBox  ## Overlayed on top when you hover the TextEdit.
@export var block_non_ascii: bool  ## Blocks non-ASCII characters.

func _init() -> void:
	context_menu_enabled = false
	wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	add_child(timer)
	timer.timeout.connect(blink)
	get_v_scroll_bar().value_changed.connect(redraw_caret.unbind(1))
	get_h_scroll_bar().value_changed.connect(redraw_caret.unbind(1))
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func redraw_caret() -> void:
	await get_tree().process_frame  # Buggy with backspace otherwise, likely a Godot bug.
	blonk = false
	blink()
	timer.start(0.6)
	RenderingServer.canvas_item_clear(surface)
	if has_focus():
		var char_size := code_font.get_char_size(69,
				get_theme_font_size(&"TextEdit", &"font_size"))
		for caret in get_caret_count():
			# FIXME There's a bug(?) causing the draw pos to sometimes not update
			# when outside of the screen.
			var caret_draw_pos := get_caret_draw_pos(caret)
			if is_overtype_mode_enabled():
				RenderingServer.canvas_item_add_line(surface, caret_draw_pos - Vector2(1, 0),
						caret_draw_pos + Vector2(char_size.x - 2, 0), caret_color, 1)
			else:
				RenderingServer.canvas_item_add_line(surface, caret_draw_pos - Vector2(0, 1),
						caret_draw_pos - Vector2(0, char_size.y - 2), caret_color, 1)

var blonk := true
func blink() -> void:
	blonk = not blonk
	RenderingServer.canvas_item_set_visible(surface, blonk)

func _on_focus_entered() -> void:
	timer.start(0.6)

func _on_focus_exited() -> void:
	timer.stop()
	RenderingServer.canvas_item_clear(surface)

func _on_mouse_entered() -> void:
	hovered = true
	queue_redraw()

func _on_mouse_exited() -> void:
	hovered = false
	queue_redraw()

func _draw() -> void:
	if editable and hovered and hover_stylebox != null:
		draw_style_box(hover_stylebox, Rect2(Vector2.ZERO, size))


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			grab_focus()
			var context_popup := ContextPopup.instantiate()
			var btn_arr: Array[Button] = [
				Utils.create_btn(tr(&"#undo"), undo, !has_undo()),
				Utils.create_btn(tr(&"#redo"), redo, !has_redo()),
				Utils.create_btn(tr(&"#copy"), copy, text.is_empty()),
				Utils.create_btn(tr(&"#paste"), paste, !DisplayServer.clipboard_has()),
				Utils.create_btn(tr(&"#cut"), cut, text.is_empty()),
			]
			
			add_child(context_popup)
			context_popup.set_button_array(btn_arr, true, 72)
			Utils.popup_under_mouse(context_popup, get_global_mouse_position())
	else:
		# Set these inputs as handled, so the default UndoRedo doesn't eat them.
		if event.is_action_pressed(&"redo"):
			if has_redo():
				redo()
			accept_event()
		elif event.is_action_pressed(&"undo"):
			if has_undo():
				undo()
			accept_event()


# I'd prefer to block non-ASCII inputs. SVG syntax is ASCII only, and while
# text blocks and comments allow non-ASCII, they are still difficult to deal with
# because they are two bytes long. <text> tags make the situation a whole lot harder,
# but for now they are not supported. Maybe in some future version I'll have them
# be translated directly into paths or have an abstraction over them, I don't know.
# Either way, not planning to support UTF-8, so I block it if the user tries to type it.
func _handle_unicode_input(unicode_char: int, caret_index: int) -> void:
	if (block_non_ascii and unicode_char <= 127) or not block_non_ascii:
		insert_text_at_caret(char(unicode_char), caret_index)
