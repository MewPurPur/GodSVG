@abstract class_name AttributeFieldBuilder

const TransformFieldScene = preload("res://src/ui_widgets/transform_field.tscn")
const NumberFieldScene = preload("res://src/ui_widgets/number_field.tscn")
const NumberSliderScene = preload("res://src/ui_widgets/number_field_with_slider.tscn")
const ColorFieldScene = preload("res://src/ui_widgets/color_field.tscn")
const EnumFieldScene = preload("res://src/ui_widgets/enum_field.tscn")
const IdFieldScene = preload("res://src/ui_widgets/id_field.tscn")
const HrefFieldScene = preload("res://src/ui_widgets/href_field.tscn")
const UnrecognizedFieldScene = preload("res://src/ui_widgets/unrecognized_field.tscn")

static func create(attribute: String, element: Element) -> Control:
	match DB.get_attribute_type(attribute):
		DB.AttributeType.ID: return _generate_no_name(IdFieldScene, element)
		DB.AttributeType.HREF: return _generate_no_name(HrefFieldScene, element)
		DB.AttributeType.TRANSFORM_LIST: return _generate(TransformFieldScene, element, attribute)
		DB.AttributeType.COLOR: return _generate(ColorFieldScene, element, attribute)
		DB.AttributeType.ENUM: return _generate(EnumFieldScene, element, attribute)
		DB.AttributeType.NUMERIC:
			match DB.ATTRIBUTE_NUMBER_RANGE[attribute]:
				DB.NumberRange.UNIT: return _generate(NumberSliderScene, element, attribute)
				_: return _generate(NumberFieldScene, element, attribute)
		_: return _generate(UnrecognizedFieldScene, element, attribute)

static func _generate(widget: PackedScene, element: Element, attribute: String) -> Control:
	var widget_instance := widget.instantiate()
	widget_instance.element = element
	widget_instance.attribute_name = attribute
	return widget_instance

static func _generate_no_name(widget: PackedScene, element: Element) -> Control:
	var widget_instance := widget.instantiate()
	widget_instance.element = element
	return widget_instance
