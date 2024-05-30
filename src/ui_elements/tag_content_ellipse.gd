extends VBoxContainer

const TransformField = preload("res://src/ui_elements/transform_field.tscn")
const NumberField = preload("res://src/ui_elements/number_field.tscn")
const NumberSlider = preload("res://src/ui_elements/number_field_with_slider.tscn")
const ColorField = preload("res://src/ui_elements/color_field.tscn")
const EnumField = preload("res://src/ui_elements/enum_field.tscn")

@onready var attribute_container: HFlowContainer = $AttributeContainer

var tag: Tag
var tid: PackedInt32Array

func _ready() -> void:
	for attribute_key in ["transform", "opacity", "cx", "cy", "rx", "ry",
	"fill", "fill-opacity", "stroke", "stroke-opacity", "stroke-width"]:
		var attribute: Attribute = tag.attributes[attribute_key]
		var input_field: Control
		if attribute is AttributeTransform:
			input_field = TransformField.instantiate()
		elif attribute is AttributeNumeric:
			var min_value: float = DB.attribute_numeric_bounds[attribute_key].x
			var max_value: float = DB.attribute_numeric_bounds[attribute_key].y
			if is_inf(max_value):
				input_field = NumberField.instantiate()
				if not is_inf(min_value):
					input_field.allow_lower = false
					input_field.min_value = min_value
			else:
				input_field = NumberSlider.instantiate()
				input_field.allow_lower = false
				input_field.allow_higher = false
				input_field.min_value = min_value
				input_field.max_value = max_value
				input_field.slider_step = 0.01
		elif attribute is AttributeColor:
			input_field = ColorField.instantiate()
		elif attribute is AttributeEnum:
			input_field = EnumField.instantiate()
		input_field.attribute = attribute
		# Focused signal for pathdata attribute.
		if input_field.has_signal("focused"):
			input_field.focused.connect(Indications.normal_select.bind(tid))
		else:
			input_field.focus_entered.connect(Indications.normal_select.bind(tid))
		attribute_container.add_child(input_field)
