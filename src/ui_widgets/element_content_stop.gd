extends VBoxContainer

const TransformField = preload("res://src/ui_widgets/transform_field.tscn")
const NumberField = preload("res://src/ui_widgets/number_field.tscn")
const NumberSlider = preload("res://src/ui_widgets/number_field_with_slider.tscn")
const ColorField = preload("res://src/ui_widgets/color_field.tscn")
const EnumField = preload("res://src/ui_widgets/enum_field.tscn")

@onready var attribute_container: HFlowContainer = $AttributeContainer

var element: Element

func _ready() -> void:
	var offset_input_field: Control = NumberSlider.instantiate()
	offset_input_field.allow_lower = false
	offset_input_field.allow_higher = false
	offset_input_field.min_value = DB.attribute_numeric_bounds["offset"].x
	offset_input_field.max_value = DB.attribute_numeric_bounds["offset"].y
	offset_input_field.slider_step = 0.01
	offset_input_field.element = element
	offset_input_field.attribute_name = "offset"
	
	var color_input_field: Control = ColorField.instantiate()
	color_input_field.element = element
	color_input_field.attribute_name = "stop-color"
	
	var opacity_input_field: Control = NumberSlider.instantiate()
	opacity_input_field.allow_lower = false
	opacity_input_field.allow_higher = false
	opacity_input_field.min_value = DB.attribute_numeric_bounds["stop-opacity"].x
	opacity_input_field.max_value = DB.attribute_numeric_bounds["stop-opacity"].y
	opacity_input_field.slider_step = 0.01
	opacity_input_field.element = element
	opacity_input_field.attribute_name = "stop-opacity"
	
	attribute_container.add_child(offset_input_field)
	attribute_container.add_child(color_input_field)
	attribute_container.add_child(opacity_input_field)
