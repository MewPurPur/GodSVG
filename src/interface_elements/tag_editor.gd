extends HBoxContainer

const NumberField = preload("res://interface_elements/number_field.tscn")
const ColorField = preload("res://interface_elements/color_field.tscn")

@onready var attribute_container: FlowContainer = $AttributeContainer
@onready var label: Label = $Label

var tag_index: int
var tag: SVGTag

func _ready() -> void:
	label.text = tag.title
	for attribute_key in tag.attributes:
		var attribute_value: SVGAttribute = tag.attributes[attribute_key]
		var input_field: Control
		match attribute_value.type:
			SVGAttribute.Type.INT:
				input_field = NumberField.instantiate()
			SVGAttribute.Type.FLOAT:
				input_field = NumberField.instantiate()
				input_field.is_float = true
				input_field.min_value = -1024
			SVGAttribute.Type.UFLOAT:
				input_field = NumberField.instantiate()
				input_field.is_float = true
			SVGAttribute.Type.NFLOAT:
				input_field = NumberField.instantiate()
				input_field.is_float = true
				input_field.max_value = 1
				input_field.step = 0.01
			SVGAttribute.Type.COLOR:
				input_field = ColorField.instantiate()
		input_field.attribute = attribute_value
		input_field.tooltip_text = attribute_key
		attribute_container.add_child(input_field)
	SVG.data.tags.insert(tag_index, tag)
	SVG.update()
