# A button for a path command picker.
extends Button

signal pressed_custom(cmd_char: String)

@export var command_char := ""

func _ready() -> void:
	text = ""
	queue_redraw()
	pressed.connect(emit_pressed_custom)

func emit_pressed_custom() -> void:
	pressed_custom.emit(command_char)

func set_invalid(new_state := true) -> void:
	disabled = new_state
	mouse_default_cursor_shape = CURSOR_ARROW if new_state else CURSOR_POINTING_HAND

# Couldn't think of any way to get RichTextLabel to autoresize its font on one line.
func _draw() -> void:
	var text_obj := TextLine.new()
	var text_color := Color(0.5, 0.5, 0.5) if disabled else Color(1, 1, 1)
	var left_margin := get_theme_stylebox("normal").content_margin_left
	var right_margin := get_theme_stylebox("normal").content_margin_right
	var max_size := size.x - left_margin - right_margin
	var bold_text := command_char + ":"
	var normal_text := " " + TranslationUtils.get_command_description(command_char)
	# Try with font size 13.
	text_obj.add_string(bold_text, ThemeUtils.bold_font, 13)
	text_obj.add_string(normal_text, ThemeUtils.regular_font, 13)
	if text_obj.get_line_width() > max_size:
		# Try with font size 12.
		text_obj.clear()
		text_obj.add_string(bold_text, ThemeUtils.bold_font, 12)
		text_obj.add_string(normal_text, ThemeUtils.regular_font, 12)
		if text_obj.get_line_width() > max_size:
			custom_minimum_size.x = size.x + 4 + text_obj.get_line_width() - max_size
	text_obj.draw(get_canvas_item(), Vector2(left_margin + 2, 3), text_color)
