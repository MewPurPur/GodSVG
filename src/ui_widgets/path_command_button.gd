# A button for a path command picker.
extends Button

var warned := false

signal pressed_custom(cmd_char: String)

var command_char := ""

func _ready() -> void:
	text = ""
	queue_redraw()
	pressed.connect(
		func() -> void:
			pressed_custom.emit(command_char)
	)

func setup(new_command_char: String, is_invalid: bool, is_warned: bool) -> void:
	command_char = new_command_char
	if is_invalid:
		disabled = is_invalid
		mouse_default_cursor_shape = CURSOR_ARROW if is_invalid else CURSOR_POINTING_HAND
	else:
		warned = is_warned

# Couldn't think of any way to get RichTextLabel to autoresize its font on one line.
func _draw() -> void:
	var text_obj := TextLine.new()
	var text_color := ThemeUtils.highlighted_text_color
	if disabled:
		text_color = ThemeUtils.dimmer_text_color
	elif warned:
		text_color = Configs.savedata.basic_color_warning
	
	var left_margin := get_theme_stylebox("normal").content_margin_left
	var right_margin := get_theme_stylebox("normal").content_margin_right
	var max_size := size.x - left_margin - right_margin
	var bold_text := command_char + ":"
	var normal_text := " " + TranslationUtils.get_path_command_description(command_char, true)
	# Try with font size 13.
	text_obj.add_string(bold_text, ThemeUtils.bold_font, 13)
	text_obj.add_string(normal_text, ThemeUtils.main_font, 13)
	if text_obj.get_line_width() > max_size:
		# Try with font size 12.
		text_obj.clear()
		text_obj.add_string(bold_text, ThemeUtils.bold_font, 12)
		text_obj.add_string(normal_text, ThemeUtils.main_font, 12)
		if text_obj.get_line_width() > max_size:
			custom_minimum_size.x = size.x + 4 + text_obj.get_line_width() - max_size
	text_obj.draw(get_canvas_item(), Vector2(left_margin + 2, 3), text_color)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and event.keycode == OS.find_keycode_from_string(command_char):
		grab_focus()
