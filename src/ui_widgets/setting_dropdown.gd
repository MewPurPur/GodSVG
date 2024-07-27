extends HBoxContainer

const DropdownType = preload("res://src/ui_widgets/dropdown.gd")

signal value_changed

@export var section: String
@export var setting: String
@export var values: Array[String]
@export var type: Variant.Type
@export var restricted := true
@export var number_min := -INF
@export var number_max := INF

@onready var dropdown_widget: DropdownType = $PanelContainer/HBoxContainer/Dropdown
@onready var label: Label = $Label
@onready var reset_button: Button = $PanelContainer/HBoxContainer/ResetButton

func _ready() -> void:
	dropdown_widget.value_changed.connect(_on_dropdown_value_changed)
	dropdown_widget.values = values
	dropdown_widget.restricted = restricted
	dropdown_widget.value = var_to_str(GlobalSettings.get(setting))
	reset_button.tooltip_text = TranslationServer.translate("Reset to default")

func _on_dropdown_value_changed(new_value: String) -> void:
	if type in [TYPE_INT, TYPE_FLOAT]:
		var actual_number := NumberParser.evaluate(new_value)
		actual_number = clamp(actual_number, number_min, number_max)
		new_value = var_to_str(actual_number)
	if new_value == "nan":
		GlobalSettings.reset_setting(section, setting)
	else:
		GlobalSettings.modify_setting(section, setting, str_to_var(new_value))
	value_changed.emit()
	update_widgets()

func _on_reset_button_pressed() -> void:
	GlobalSettings.reset_setting(section, setting)
	value_changed.emit()
	update_widgets()

func update_widgets() -> void:
	var setting_value: Variant = GlobalSettings.get(setting)
	dropdown_widget.value = var_to_str(setting_value)
	reset_button.visible = (setting_value !=\
			GlobalSettings.get_default(section, setting))
