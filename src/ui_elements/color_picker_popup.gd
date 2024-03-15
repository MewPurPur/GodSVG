extends Popup

const GoodColorPicker = preload("res://src/ui_elements/good_color_picker.tscn")

@onready var margin_container: MarginContainer = $PanelContainer/MarginContainer

signal color_picked(new_color: String, final: bool)
var enable_alpha := false
var current_value: String

func _ready() -> void:
	var color_picker := GoodColorPicker.instantiate()
	color_picker.alpha_enabled = enable_alpha
	margin_container.add_child(color_picker)
	await get_tree().process_frame
	color_picker.setup_color(current_value)
	color_picker.color_changed.connect(pick_color)

func pick_color(color: String) -> void:
	color_picked.emit(color, false)


func _on_popup_hide() -> void:
	queue_free()
