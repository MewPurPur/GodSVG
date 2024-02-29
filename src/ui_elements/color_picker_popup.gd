extends Popup

const GoodColorPickerType = preload("res://src/ui_elements/good_color_picker.gd")

@onready var picker: GoodColorPickerType = $PanelContainer/MarginContainer/ColorPicker

signal color_picked(new_color: String, final: bool)
var current_value: String

func _ready() -> void:
	await get_tree().process_frame
	picker.setup_color(current_value)

func pick_color(color: String) -> void:
	color_picked.emit(color, false)


func _on_popup_hide() -> void:
	queue_free()
