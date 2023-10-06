extends ColorRect

@onready var window_mode_button: CheckBox = %WindowMode

func _ready() -> void:
	window_mode_button.button_pressed = GlobalSettings.save_window_mode

func _on_window_mode_pressed() -> void:
	GlobalSettings.save_window_mode = not GlobalSettings.save_window_mode

func _on_close_pressed() -> void:
	queue_free()
