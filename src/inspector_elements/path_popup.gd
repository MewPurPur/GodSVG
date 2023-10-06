extends Popup

signal path_command_picked(new_command: String)

@onready var main_container: VBoxContainer = %MainContainer

func _ready() -> void:
	for command_button in main_container.get_children():
		if command_button is CheckButton:
			# The relative toggle
			command_button.toggled.connect(_on_relative_toggle_toggled)
		else:
			# Everything else
			command_button.gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and\
	event.button_mask == MOUSE_BUTTON_LEFT:
		for command_button in main_container.get_children():
			if not command_button is CheckButton:
				if command_button.get_global_rect().has_point(get_mouse_position()):
					path_command_picked.emit(command_button.command_char)
					hide()

func _on_relative_toggle_toggled(toggled_on: bool) -> void:
	for command_button in main_container.get_children():
		if command_button is CheckButton:
			continue
		
		if toggled_on:
			command_button.command_char = command_button.command_char.to_lower()
			command_button.text = command_button.command_char + command_button.text.right(-1)
		else:
			command_button.command_char = command_button.command_char.to_upper()
			command_button.text = command_button.command_char + command_button.text.right(-1)
