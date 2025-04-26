extends PanelContainer

# The popup from color edits shouldn't access the palettes, so it's simpler.

const GoodColorPickerScene = preload("res://src/ui_widgets/good_color_picker.tscn")

@onready var margin_container: MarginContainer = $MarginContainer

signal color_picked(new_color: String)
var enable_alpha := false
var current_value: String

func _ready() -> void:
	var color_picker := GoodColorPickerScene.instantiate()
	color_picker.alpha_enabled = enable_alpha
	margin_container.add_child(color_picker)
	await get_tree().process_frame
	color_picker.setup_color(current_value, Color.BLACK)
	color_picker.color_changed.connect(color_picked.emit)
