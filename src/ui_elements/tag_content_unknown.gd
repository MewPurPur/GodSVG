extends VBoxContainer

const UnknownField = preload("res://src/ui_elements/unknown_field.tscn")
const TransformField = preload("res://src/ui_elements/transform_field.tscn")
const NumberField = preload("res://src/ui_elements/number_field.tscn")
const NumberSlider = preload("res://src/ui_elements/number_field_with_slider.tscn")
const ColorField = preload("res://src/ui_elements/color_field.tscn")
const PathField = preload("res://src/ui_elements/path_field.tscn")
const EnumField = preload("res://src/ui_elements/enum_field.tscn")

var unknown_container: HFlowContainer  # Only created if there are unknown attributes.
@onready var paint_container: FlowContainer = $PaintAttributes
@onready var shape_container: FlowContainer = $ShapeAttributes

var tag: Tag
var tid: PackedInt32Array

func _ready() -> void:
	# Fill up the containers. Start with unknown attributes, if there are any.
	if not tag.unknown_attributes.is_empty():
		unknown_container = HFlowContainer.new()
		add_child(unknown_container)
		move_child(unknown_container, 0)
		for attribute in tag.unknown_attributes:
			var input_field := UnknownField.instantiate()
			input_field.attribute = attribute
			input_field.attribute_name = attribute.name
			unknown_container.add_child(input_field)
	# Continue with supported attributes.
	for attribute_key in tag.attributes:
		var attribute: Attribute = tag.attributes[attribute_key]
		var input_field: Control
		if attribute is AttributeTransform:
			input_field = TransformField.instantiate()
		elif attribute is AttributeNumeric:
			match attribute.mode:
				AttributeNumeric.Mode.FLOAT:
					input_field = NumberField.instantiate()
				AttributeNumeric.Mode.UFLOAT:
					input_field = NumberField.instantiate()
					input_field.allow_lower = false
				AttributeNumeric.Mode.NFLOAT:
					input_field = NumberSlider.instantiate()
					input_field.allow_lower = false
					input_field.allow_higher = false
					input_field.slider_step = 0.01
		elif attribute is AttributeColor:
			input_field = ColorField.instantiate()
		elif attribute is AttributePath:
			input_field = PathField.instantiate()
		elif attribute is AttributeEnum:
			input_field = EnumField.instantiate()
		input_field.attribute = attribute
		input_field.attribute_name = attribute_key
		input_field.focused.connect(Indications.normal_select.bind(tid))
		# Add the attribute to its corresponding container.
		if attribute_key in tag.known_shape_attributes:
			shape_container.add_child(input_field)
		elif attribute_key in tag.known_inheritable_attributes:
			paint_container.add_child(input_field)
