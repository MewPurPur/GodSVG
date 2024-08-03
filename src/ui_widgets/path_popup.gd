# A popup for picking a path command.
extends PanelContainer

signal path_command_picked(new_command: String)

@onready var command_container: VBoxContainer = %CommandContainer
@onready var relative_toggle: CheckButton = %RelativeToggle
@onready var vbox: VBoxContainer = $VBoxContainer
@onready var top_margin: MarginContainer = $VBoxContainer/MarginContainer

func _ready() -> void:
	relative_toggle.toggled.connect(_on_relative_toggle_toggled)
	relative_toggle.button_pressed = GlobalSettings.savedata.path_command_relative
	for command_button in command_container.get_children():
		command_button.pressed_custom.connect(emit_picked)

func emit_picked(cmd_char: String) -> void:
	path_command_picked.emit(cmd_char)
	queue_free()

func _on_relative_toggle_toggled(toggled_on: bool) -> void:
	GlobalSettings.savedata.path_command_relative = toggled_on
	for command_button in command_container.get_children():
		command_button.command_char = command_button.command_char.to_lower() if toggled_on\
				else command_button.command_char.to_upper()
		command_button.queue_redraw()

func disable_invalid(cmd_chars: Array) -> void:
	for cmd_char in cmd_chars:
		var cmd_char_upper: String = cmd_char.to_upper()
		command_container.get_node(cmd_char_upper).set_invalid()

func force_relativity(relative: bool) -> void:
	relative_toggle.hide()
	vbox.add_theme_constant_override("separation", 0)
	top_margin.add_theme_constant_override("margin_top", 0)
	for command_button in command_container.get_children():
		if relative:
			command_button.command_char = command_button.command_char.to_lower()
			command_button.queue_redraw()
		else:
			command_button.command_char = command_button.command_char.to_upper()
			command_button.queue_redraw()
	reset_size()
