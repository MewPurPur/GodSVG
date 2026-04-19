extends HBoxContainer

const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")

signal scale_changed(new_scale: float)

var original_dimensions: Vector2
var max_dimension: int

@onready var scale_label: Label = %ScaleLabel
@onready var scale_edit: NumberEdit = %ScaleEdit
@onready var width_label: Label = %WidthLabel
@onready var width_edit: NumberEdit = %WidthEdit
@onready var height_label: Label = %HeightLabel
@onready var height_edit: NumberEdit = %HeightEdit

func _ready() -> void:
	scale_label.text = Translator.translate("Scale") + ":"
	width_label.text = Translator.translate("Width") + ":"
	height_label.text = Translator.translate("Height") + ":"
	HandlerGUI.register_focus_sequence(self, [scale_edit, width_edit, height_edit])

func setup(new_original_dimensions: Vector2, initial_scale: float, new_max_dimension: int) -> void:
	if not is_node_ready():
		await ready
	original_dimensions = new_original_dimensions
	max_dimension = new_max_dimension
	scale_edit.min_value = 1 / minf(original_dimensions.x, original_dimensions.y)
	scale_edit.max_value = max_dimension / maxf(original_dimensions.x, original_dimensions.y)
	width_edit.max_value = max_dimension
	height_edit.max_value = max_dimension
	scale_edit.value_changed.connect(_on_scale_edit_value_changed)
	width_edit.value_changed.connect(_on_width_edit_value_changed)
	height_edit.value_changed.connect(_on_height_edit_value_changed)
	set_export_scale(initial_scale)
	HandlerGUI.register_focus_sequence(self, [scale_edit, width_edit, height_edit])


func set_export_scale(new_scale: float) -> void:
	scale_edit.set_value(new_scale, false)
	width_edit.set_value(roundi(original_dimensions.x * new_scale), false)
	height_edit.set_value(roundi(original_dimensions.y * new_scale), false)

func _on_scale_edit_value_changed(new_value: float) -> void:
	width_edit.set_value(roundi(original_dimensions.x * new_value))
	height_edit.set_value(roundi(original_dimensions.y * new_value))
	scale_changed.emit(new_value)

func _on_width_edit_value_changed(new_value: float) -> void:
	if roundi(original_dimensions.x * scale_edit.get_value()) != roundi(new_value):
		scale_edit.set_value(new_value / original_dimensions.x)

func _on_height_edit_value_changed(new_value: float) -> void:
	if roundi(original_dimensions.y * scale_edit.get_value()) != roundi(new_value):
		scale_edit.set_value(new_value / original_dimensions.y)
