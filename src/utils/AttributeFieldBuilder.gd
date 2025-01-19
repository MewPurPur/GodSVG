class_name AttributeFieldBuilder

const TransformField = preload("res://src/ui_widgets/transform_field.tscn")
const NumberField = preload("res://src/ui_widgets/number_field.tscn")
const NumberSlider = preload("res://src/ui_widgets/number_field_with_slider.tscn")
const ColorField = preload("res://src/ui_widgets/color_field.tscn")
const EnumField = preload("res://src/ui_widgets/enum_field.tscn")
const IdField = preload("res://src/ui_widgets/id_field.tscn")
const UnrecognizedField = preload("res://src/ui_widgets/unrecognized_field.tscn")

static func create(attribute_name: String, element: Element) -> Control:
	match DB.get_attribute_type(attribute_name):
		DB.AttributeType.ID: return _generate_no_name(IdField, element)
		DB.AttributeType.TRANSFORM_LIST: return _generate(TransformField, element, attribute_name)
		DB.AttributeType.COLOR: return _generate(ColorField, element, attribute_name)
		DB.AttributeType.ENUM: return _generate(EnumField, element, attribute_name)
		DB.AttributeType.NUMERIC:
			match DB.get_attribute_default_number_type(attribute_name):
				DB.NumberType.FRACTION: return _generate(NumberSlider, element, attribute_name)
				_: return _generate(NumberField, element, attribute_name)
		_: return _generate(UnrecognizedField, element, attribute_name)

static func _generate(widget: PackedScene, element: Element, attribute: String) -> Control:
	var widget_instance := widget.instantiate()
	widget_instance.element = element
	widget_instance.attribute_name = attribute
	return widget_instance

static func _generate_no_name(widget: PackedScene, element: Element) -> Control:
	var widget_instance := widget.instantiate()
	widget_instance.element = element
	return widget_instance
