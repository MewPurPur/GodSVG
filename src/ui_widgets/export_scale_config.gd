extends HBoxContainer

const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")

signal scale_changed(new_scale: float)

var original_width: float
var original_height: float

@export var max_dimension := 16383

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

func setup(new_original_width: float, new_original_height: float, initial_scale: float) -> void:
	if not is_node_ready():
		await ready
	original_width = new_original_width
	original_height = new_original_height
	var bigger_dimension := maxf(original_width, original_height)
	var max_scale := max_dimension / bigger_dimension
	scale_edit.min_value = 1 / bigger_dimension
	scale_edit.max_value = max_dimension / bigger_dimension
	width_edit.max_value = floori(original_width * max_scale)
	height_edit.max_value = floori(original_height * max_scale)
	scale_edit.value_changed.connect(_on_scale_edit_value_changed)
	width_edit.value_changed.connect(_on_width_edit_value_changed)
	height_edit.value_changed.connect(_on_height_edit_value_changed)
	set_export_scale(initial_scale)
	HandlerGUI.register_focus_sequence(self, [scale_edit, width_edit, height_edit])


func set_export_scale(new_scale: float) -> void:
	scale_edit.set_value(new_scale, false)
	new_scale = scale_edit.get_value()
	width_edit.set_value(roundi(original_width * new_scale), false)
	height_edit.set_value(roundi(original_height * new_scale), false)

func _on_scale_edit_value_changed(new_value: float) -> void:
	width_edit.set_value(roundi(original_width * new_value))
	height_edit.set_value(roundi(original_height * new_value))
	scale_changed.emit(new_value)

func _on_width_edit_value_changed(new_value: float) -> void:
	if roundi(original_width * scale_edit.get_value()) != roundi(new_value):
		scale_edit.set_value(new_value / original_width)

func _on_height_edit_value_changed(new_value: float) -> void:
	if roundi(original_height * scale_edit.get_value()) != roundi(new_value):
		scale_edit.set_value(new_value / original_height)
