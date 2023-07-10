extends Popup

signal path_command_picked(new_command: String)

@onready var main_container: VBoxContainer = %MainContainer

func _ready() -> void:
	for command_button in main_container.get_children():
		command_button.gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and\
	event.button_mask == MOUSE_BUTTON_LEFT:
		for command_button in main_container.get_children():
			if command_button.get_global_rect().has_point(get_mouse_position()):
				path_command_picked.emit(command_button.command_char)
				hide()
