## A button for a path command picker.
extends Button

signal pressed_custom(cmd_char: String)

@onready var rtl: RichTextLabel = $RichTextLabel

@export var command_char := ""

func _ready() -> void:
	text = ""
	update_text()
	pressed.connect(emit_pressed_custom)

func emit_pressed_custom() -> void:
	pressed_custom.emit(command_char)

func update_text() -> void:
	rtl.text = ""
	rtl.clear()
	rtl.push_bold()
	rtl.add_text(command_char)
	rtl.add_text(":")
	rtl.pop()
	rtl.add_text(" ")
	rtl.add_text(TranslationUtils.new().get_command_char_description(command_char))

func set_invalid(new_state := true) -> void:
	if new_state:
		rtl.add_theme_color_override("default_color", Color(0.5, 0.5, 0.5))
	else:
		rtl.remove_theme_color_override("default_color")
	disabled = new_state
	mouse_default_cursor_shape = CURSOR_ARROW if new_state else CURSOR_POINTING_HAND
