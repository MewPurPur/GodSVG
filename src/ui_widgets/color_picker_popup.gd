extends PanelContainer

const GoodColorPicker = preload("res://src/ui_widgets/good_color_picker.tscn")

@onready var margin_container: MarginContainer = $MarginContainer

signal color_picked(new_color: String, final: bool)
var enable_alpha := false
var show_disable_color := false
var current_value: String

func _ready() -> void:
	var color_picker := GoodColorPicker.instantiate()
	color_picker.alpha_enabled = enable_alpha
	color_picker.show_disable_color = show_disable_color
	margin_container.add_child(color_picker)
	await get_tree().process_frame
	color_picker.setup_color(current_value)
	color_picker.color_changed.connect(pick_color)

func pick_color(color: String) -> void:
	color_picked.emit(color, false)
