@abstract class_name AttributeFieldBuilder

const TransformFieldScene = preload("res://src/ui_widgets/transform_field.tscn")
const NumberFieldScene = preload("res://src/ui_widgets/number_field.tscn")
const NumberSliderScene = preload("res://src/ui_widgets/number_field_with_slider.tscn")
const ColorFieldScene = preload("res://src/ui_widgets/color_field.tscn")
const EnumFieldScene = preload("res://src/ui_widgets/enum_field.tscn")
const IdFieldScene = preload("res://src/ui_widgets/id_field.tscn")
const HrefFieldScene = preload("res://src/ui_widgets/href_field.tscn")
const UnrecognizedFieldScene = preload("res://src/ui_widgets/unrecognized_field.tscn")

static func create(attribute_name: String, element: Element) -> Control:
	match DB.get_attribute_type(attribute_name):
		DB.AttributeType.ID: return _generate_no_name(IdFieldScene, element)
		DB.AttributeType.HREF: return _generate_no_name(HrefFieldScene, element)
		DB.AttributeType.TRANSFORM_LIST: return _generate(TransformFieldScene, element, attribute_name)
		DB.AttributeType.COLOR: return _generate(ColorFieldScene, element, attribute_name)
		DB.AttributeType.ENUM: return _generate(EnumFieldScene, element, attribute_name)
		DB.AttributeType.NUMERIC:
			match DB.ATTRIBUTE_NUMBER_RANGE[attribute_name]:
				DB.NumberRange.UNIT: return _generate(NumberSliderScene, element, attribute_name)
				_: return _generate(NumberFieldScene, element, attribute_name)
		_: return _generate(UnrecognizedFieldScene, element, attribute_name)

static func _generate(widget: PackedScene, element: Element, attribute: String) -> Control:
	var widget_instance := widget.instantiate()
	widget_instance.element = element
	widget_instance.attribute_name = attribute
	return widget_instance

static func _generate_no_name(widget: PackedScene, element: Element) -> Control:
	var widget_instance := widget.instantiate()
	widget_instance.element = element
	return widget_instance
