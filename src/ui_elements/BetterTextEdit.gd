## A TextEdit that doesn't fully redraw on caret blink and has a custom context menu.
class_name BetterTextEdit extends TextEdit

const code_font = preload("res://visual/fonts/FontMono.ttf")
const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const caret_color = Color("defd")

var surface := RenderingServer.canvas_item_create()
var timer := Timer.new()

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	add_child(timer)
	timer.timeout.connect(blink)
	get_v_scroll_bar().value_changed.connect(redraw_caret.unbind(1))
	get_h_scroll_bar().value_changed.connect(redraw_caret.unbind(1))
	gui_input.connect(_on_gui_input)


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


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var context_popup := ContextPopup.instantiate()
			var btn_arr: Array[Button] = []
			
			var undo_button := Button.new()
			undo_button.text = tr(&"#undo")
			if has_undo():
				undo_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			else:
				undo_button.disabled = true
				undo_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
			undo_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			undo_button.pressed.connect(undo)
			btn_arr.append(undo_button)
			
			var redo_button := Button.new()
			redo_button.text = tr(&"#redo")
			if has_redo():
				redo_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			else:
				redo_button.disabled = true
				redo_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
			redo_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			redo_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			redo_button.pressed.connect(redo)
			btn_arr.append(redo_button)
			
			var copy_button := Button.new()
			copy_button.text = tr(&"#copy")
			copy_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			copy_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			copy_button.pressed.connect(copy)
			btn_arr.append(copy_button)
			
			var paste_button := Button.new()
			paste_button.text = tr(&"#paste")
			paste_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			paste_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			paste_button.pressed.connect(paste)
			btn_arr.append(paste_button)
			
			var cut_button := Button.new()
			cut_button.text = tr(&"#cut")
			cut_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			cut_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			cut_button.pressed.connect(cut)
			btn_arr.append(cut_button)
			
			add_child(context_popup)
			context_popup.set_min_width(72.0)
			context_popup.set_btn_array(btn_arr)
			Utils.popup_under_mouse(context_popup, event.global_position)
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
