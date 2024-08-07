extends HBoxContainer

signal pressed

@export var section: String
@export var setting: String

@onready var checkbox: CheckBox = $PanelContainer/HBoxContainer/CheckBox
@onready var label: Label = $Label
@onready var reset_button: Button = $PanelContainer/HBoxContainer/ResetButton

func _ready() -> void:
	checkbox.button_pressed = GlobalSettings.get(setting)
	reset_button.tooltip_text = TranslationServer.translate("Reset to default")
	update_widgets()

func _on_pressed() -> void:
	GlobalSettings.modify_setting(section, setting, !GlobalSettings.get(setting))
	update_widgets()
	pressed.emit()

func update_widgets() -> void:
	var setting_value: bool = GlobalSettings.get(setting)
	checkbox.text = "On" if setting_value else "Off"
	reset_button.visible = not checkbox.disabled and (setting_value !=\
			GlobalSettings.get_default(section, setting))
	if checkbox.disabled:
		label.add_theme_color_override("font_color",
				ThemeGenerator.common_subtle_text_color)
	else:
		label.remove_theme_color_override("font_color")

func _on_reset_button_pressed() -> void:
	checkbox.button_pressed = not checkbox.button_pressed
	checkbox.pressed.emit()

func set_checkbox_enabled(enabled: bool) -> void:
	checkbox.disabled = not enabled
	checkbox.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if enabled else\
			Control.CURSOR_ARROW
	update_widgets()
