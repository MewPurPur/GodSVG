extends VBoxContainer

const TransformField = preload("res://src/ui_elements/transform_field.tscn")
const NumberField = preload("res://src/ui_elements/number_field.tscn")
const NumberSlider = preload("res://src/ui_elements/number_field_with_slider.tscn")
const ColorField = preload("res://src/ui_elements/color_field.tscn")
const EnumField = preload("res://src/ui_elements/enum_field.tscn")

@onready var attribute_container: HFlowContainer = $AttributeContainer
@onready var path_field: VBoxContainer = $PathField

var tag: Tag
var tid: PackedInt32Array

func _ready() -> void:
	path_field.attribute_name = "d"
	path_field.set_attribute(tag.attributes.d)
	for attribute_key in tag.attributes:
		if attribute_key == "d":
			continue
		var attribute: Attribute = tag.attributes[attribute_key]
		var input_field: Control
		if attribute is AttributeTransform:
			input_field = TransformField.instantiate()
		elif attribute is AttributeNumeric:
			if is_inf(attribute.max_value):
				input_field = NumberField.instantiate()
				if not is_inf(attribute.min_value):
					input_field.allow_lower = false
					input_field.min_value = attribute.min_value
			else:
				input_field = NumberSlider.instantiate()
				input_field.allow_lower = false
				input_field.allow_higher = false
				input_field.min_value = attribute.min_value
				input_field.max_value = attribute.max_value
				input_field.slider_step = 0.01
		elif attribute is AttributeColor:
			input_field = ColorField.instantiate()
		elif attribute is AttributeEnum:
			input_field = EnumField.instantiate()
		input_field.attribute = attribute
		input_field.attribute_name = attribute_key
		input_field.focused.connect(Indications.normal_select.bind(tid))
		attribute_container.add_child(input_field)
