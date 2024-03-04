extends HBoxContainer

signal value_changed

@export var section_name: String
@export var setting_name: String

@onready var color_edit: HBoxContainer = $PanelContainer/HBoxContainer/ColorEdit
@onready var label: Label = $Label
@onready var reset_button: Button = $PanelContainer/HBoxContainer/ResetButton

func _ready() -> void:
	color_edit.value = GlobalSettings.get(setting_name).to_html(false)
	reset_button.tooltip_text = tr("Reset to default")

func _on_color_edit_value_changed(new_value: String) -> void:
	GlobalSettings.modify_setting(section_name, setting_name, Color(new_value))
	value_changed.emit()
	update_widgets()

func _on_reset_button_pressed() -> void:
	GlobalSettings.reset_setting(section_name, setting_name)
	value_changed.emit()
	update_widgets()

func update_widgets() -> void:
	var setting_value: String = GlobalSettings.get(setting_name).to_html(false)
	color_edit.value = setting_value
	reset_button.visible = (setting_value !=\
			GlobalSettings.default_config[section_name][setting_name].to_html(false))
