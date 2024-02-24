## Stores data that needs to be retained between sessions.
class_name SaveData extends Resource

const GoodColorPicker = preload("res://src/ui_elements/good_color_picker.gd")

@export var window_mode := DisplayServer.WINDOW_MODE_MAXIMIZED
@export var svg_text := ""
@export var viewbox_coupling := true
@export var snap := -0.5  # Negative when disabled.
@export var color_picker_slider_mode := GoodColorPicker.SliderMode.RGB
@export var path_command_relative := false
@export var last_used_dir := ""

signal current_file_path_changed
@export var current_file_path := "":
	set(new_value):
		if new_value != current_file_path:
			current_file_path = new_value
			current_file_path_changed.emit()
