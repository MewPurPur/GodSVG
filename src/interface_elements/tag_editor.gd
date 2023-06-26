extends PanelContainer

const shape_attributes = ["cx", "cy", "x", "y", "r", "rx", "ry", "width", "height", "d"]

const NumberField = preload("number_field.tscn")
const ColorField = preload("color_field.tscn")
const PathField = preload("path_field.tscn")
const EnumField = preload("enum_field.tscn")

@onready var paint_container: FlowContainer = %AttributeContainer/PaintAttributes
@onready var shape_container: FlowContainer = %AttributeContainer/ShapeAttributes
@onready var label: Label = %Title

signal deleted

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
			SVGAttribute.Type.PATHDATA:
				input_field = PathField.instantiate()
			SVGAttribute.Type.ENUM:
				input_field = EnumField.instantiate()
		input_field.attribute = attribute_value
		input_field.attribute_name = attribute_key
		# Add the attribute to its corresponding container.
		if attribute_key in shape_attributes:
			shape_container.add_child(input_field)
		else:
			paint_container.add_child(input_field)
	SVG.data.tags.insert(tag_index, tag)
	SVG.update()


func _on_close_button_pressed() -> void:
	deleted.emit(tag_index)
	SVG.data.tags.remove_at(tag_index)
	SVG.update()
	queue_free()
