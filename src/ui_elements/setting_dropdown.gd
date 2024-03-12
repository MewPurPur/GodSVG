extends HBoxContainer

const DropdownType = preload("res://src/ui_elements/dropdown.gd")

signal value_changed

@export var section_name: String
@export var setting_name: String
@export var values: Array[String]
@export var type: Variant.Type
@export var restricted := true

@onready var dropdown_widget: DropdownType = $PanelContainer/HBoxContainer/Dropdown
@onready var label: Label = $Label
@onready var reset_button: Button = $PanelContainer/HBoxContainer/ResetButton

func _ready() -> void:
	dropdown_widget.value = var_to_str(GlobalSettings.get(setting_name))
	dropdown_widget.values = values
	dropdown_widget.restricted = restricted
	reset_button.tooltip_text = tr("Reset to default")

func _on_dropdown_value_changed(new_value: String) -> void:
	if type in [TYPE_INT, TYPE_FLOAT]:
		new_value = var_to_str(NumberParser.evaluate(new_value))
	GlobalSettings.modify_setting(section_name, setting_name, str_to_var(new_value))
	value_changed.emit()
	update_widgets()

func _on_reset_button_pressed() -> void:
	GlobalSettings.reset_setting(section_name, setting_name)
	value_changed.emit()
	update_widgets()

func update_widgets() -> void:
	var setting_value = GlobalSettings.get(setting_name)
	dropdown_widget.value = var_to_str(setting_value)
	reset_button.visible = (setting_value !=\
			GlobalSettings.default_config[section_name][setting_name])
