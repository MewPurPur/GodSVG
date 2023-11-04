## A button for a path command picker.
extends Button

@onready var rtl: RichTextLabel = $RichTextLabel

@export var command_char := ""
@export var command_text := ""

func _ready() -> void:
	text = ""
	update_text()

func update_text() -> void:
	rtl.text = ""
	rtl.clear()
	rtl.push_bold()
	rtl.add_text(command_char)
	rtl.add_text(":")
	rtl.pop()
	rtl.add_text(" ")
	rtl.add_text(command_text)

func set_invalid(new_state := true) -> void:
	if new_state:
		rtl.add_theme_color_override(&"default_color", Color(0.5, 0.5, 0.5))
	else:
		rtl.remove_theme_color_override(&"default_color")
	disabled = new_state
	mouse_default_cursor_shape = CURSOR_ARROW if new_state else CURSOR_POINTING_HAND
