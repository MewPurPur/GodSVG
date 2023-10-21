extends Popup

signal path_command_picked(new_command: String)

@onready var command_container: VBoxContainer = %CommandContainer
@onready var relative_toggle: CheckButton = %RelativeToggle

func _ready() -> void:
	relative_toggle.toggled.connect(_on_relative_toggle_toggled)
	for command_button in command_container.get_children():
		command_button.pressed.connect(emit_picked.bind(command_button.command_char))

func emit_picked(cmd_char: String) -> void:
	path_command_picked.emit(cmd_char)
	hide()

func _on_relative_toggle_toggled(toggled_on: bool) -> void:
	for command_button in command_container.get_children():
		if toggled_on:
			command_button.command_char = command_button.command_char.to_lower()
			command_button.update_text()
		else:
			command_button.command_char = command_button.command_char.to_upper()
			command_button.update_text()

func disable_invalid(cmd_char: String) -> void:
	var cmd_char_upper := cmd_char.to_upper()
	if cmd_char_upper == "M" or cmd_char_upper == "Z":
		command_container.get_node(^"M").set_invalid()
		command_container.get_node(^"M").set_invalid()
	if cmd_char_upper != "C" and cmd_char_upper != "S":
		command_container.get_node(^"S").set_invalid()
	if cmd_char_upper != "Q" and cmd_char_upper != "T":
		command_container.get_node(^"T").set_invalid()
