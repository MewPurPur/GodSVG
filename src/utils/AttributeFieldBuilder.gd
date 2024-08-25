class_name AttributeFieldBuilder

const TransformField = preload("res://src/ui_widgets/transform_field.tscn")
const NumberField = preload("res://src/ui_widgets/number_field.tscn")
const NumberSlider = preload("res://src/ui_widgets/number_field_with_slider.tscn")
const ColorField = preload("res://src/ui_widgets/color_field.tscn")
const EnumField = preload("res://src/ui_widgets/enum_field.tscn")
const IdField = preload("res://src/ui_widgets/id_field.tscn")
const UnrecognizedField = preload("res://src/ui_widgets/unrecognized_field.tscn")

static func create(attribute: String, element: Element) -> Control:
	match DB.get_attribute_type(attribute):
		DB.AttributeType.ID: return _generate_no_name(IdField, element)
		DB.AttributeType.TRANSFORM_LIST: return _generate(TransformField, element, attribute)
		DB.AttributeType.COLOR: return _generate(ColorField, element, attribute)
		DB.AttributeType.ENUM: return _generate(EnumField, element, attribute)
		DB.AttributeType.NUMERIC:
			match DB.attribute_number_range[attribute]:
				DB.NumberRange.UNIT: return _generate(NumberSlider, element, attribute)
				_: return _generate(NumberField, element, attribute)
		_: return _generate(UnrecognizedField, element, attribute)

static func _generate(widget: PackedScene, element: Element, attribute: String) -> Control:
	var widget_instance := widget.instantiate()
	widget_instance.element = element
	widget_instance.attribute_name = attribute
	return widget_instance

static func _generate_no_name(widget: PackedScene, element: Element) -> Control:
	var widget_instance := widget.instantiate()
	widget_instance.element = element
	return widget_instance
