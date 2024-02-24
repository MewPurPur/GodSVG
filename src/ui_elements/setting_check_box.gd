extends CheckBox

@export var section_name: String
@export var setting_name: String

func _ready() -> void:
	button_pressed = GlobalSettings.get(setting_name)

func _on_pressed() -> void:
	GlobalSettings.toggle_bool_setting(section_name, setting_name)
