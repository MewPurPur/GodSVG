extends HBoxContainer

signal value_changed

@export var section: String
@export var setting: String
@export var enable_alpha := true

@onready var color_edit: LineEditButton = $PanelContainer/HBoxContainer/ColorEdit
@onready var label: Label = $Label
@onready var reset_button: Button = $PanelContainer/HBoxContainer/ResetButton

func _ready() -> void:
	color_edit.enable_alpha = enable_alpha
	color_edit.value = GlobalSettings.get(setting).to_html(enable_alpha)
	reset_button.tooltip_text = TranslationServer.translate("Reset to default")

func _on_color_edit_value_changed(new_value: String) -> void:
	GlobalSettings.modify_setting(section, setting, Color(new_value))
	value_changed.emit()
	update_widgets()

func _on_reset_button_pressed() -> void:
	GlobalSettings.reset_setting(section, setting)
	value_changed.emit()
	update_widgets()

func update_widgets() -> void:
	var setting_value: Color = GlobalSettings.get(setting)
	var show_alpha := enable_alpha and setting_value.a != 1.0
	var setting_str: String = setting_value.to_html(show_alpha)
	color_edit.value = setting_str
	var default_value: Color = GlobalSettings.get_default(section, setting)
	reset_button.visible = (setting_str != default_value.to_html(default_value.a != 1.0))
