# A button for a path command conversion picker.
extends Button

var warned := false

signal pressed_custom(conversion: AttributePathdata.Conversion)

var conversion: AttributePathdata.Conversion
var original_commands_char: String

func _ready() -> void:
	text = ""
	queue_redraw()
	pressed.connect(
		func() -> void:
			pressed_custom.emit(conversion)
	)

func setup(new_conversion: AttributePathdata.Conversion, new_original_commands_char: String, is_invalid: bool, is_warned: bool) -> void:
	conversion = new_conversion
	original_commands_char = new_original_commands_char
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
	
	var conversion_char := ""
	match conversion:
		AttributePathdata.Conversion.ANY_TO_MOVEMENT: conversion_char = "M"
		AttributePathdata.Conversion.ANY_TO_LINE: conversion_char = "L"
		AttributePathdata.Conversion.ANY_TO_HORIZONTAL_LINE: conversion_char = "H"
		AttributePathdata.Conversion.ANY_TO_VERTICAL_LINE: conversion_char = "V"
		AttributePathdata.Conversion.ANY_TO_CLOSURE: conversion_char = "Z"
		AttributePathdata.Conversion.ANY_TO_ELLIPTICAL_ARC: conversion_char = "A"
		AttributePathdata.Conversion.ANY_TO_QUADRATIC_BEZIER_CURVE: conversion_char = "Q"
		AttributePathdata.Conversion.ANY_TO_SHORTHAND_QUADRATIC_BEZIER_CURVE: conversion_char = "T"
		AttributePathdata.Conversion.ANY_TO_CUBIC_BEZIER_CURVE: conversion_char = "C"
		AttributePathdata.Conversion.ANY_TO_SHORTHAND_CUBIC_BEZIER_CURVE: conversion_char = "S"
	
	var bold_text := "%s→%s:" % [original_commands_char, conversion_char]
	var normal_text := " " + TranslationUtils.get_path_command_description(conversion_char, true)
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
