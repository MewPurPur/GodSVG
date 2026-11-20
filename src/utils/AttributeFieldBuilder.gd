@abstract class_name AttributeFieldBuilder

const TransformListFieldScene = preload("res://src/ui_widgets/transform_list_field.tscn")
const NumberFieldScene = preload("res://src/ui_widgets/number_field.tscn")
const NumberSliderScene = preload("res://src/ui_widgets/number_field_with_slider.tscn")
const ColorFieldScene = preload("res://src/ui_widgets/color_field.tscn")
const EnumFieldScene = preload("res://src/ui_widgets/enum_field.tscn")
const IdFieldScene = preload("res://src/ui_widgets/id_field.tscn")
const HrefFieldScene = preload("res://src/ui_widgets/href_field.tscn")
const DashArrayFieldScene = preload("res://src/ui_widgets/dasharray_field.tscn")
const UnrecognizedFieldScene = preload("res://src/ui_widgets/unrecognized_field.tscn")

static func create(attribute_name: String, element: Element) -> Control:
	match DB.get_attribute_syntaxes(attribute_name):
		[DB.AttributeSyntax.ID]: return _generate_no_name(IdFieldScene, element)
		[DB.AttributeSyntax.HREF]: return _generate_no_name(HrefFieldScene, element)
		[DB.AttributeSyntax.TRANSFORM_LIST]: return _generate(TransformListFieldScene, element, attribute_name)
		[DB.AttributeSyntax.COLOR], [DB.AttributeSyntax.COLOR, DB.AttributeSyntax.URL]: return _generate(ColorFieldScene, element, attribute_name)
		[DB.AttributeSyntax.DASHARRAY]: return _generate_no_name(DashArrayFieldScene, element)
		[DB.AttributeSyntax.FRACTION]: return _generate(NumberSliderScene, element, attribute_name)
		[DB.AttributeSyntax.ARBITRARY_NUMERIC], [DB.AttributeSyntax.POSITIVE_NUMERIC]: return _generate(NumberFieldScene, element, attribute_name)
		_:
			if attribute_name in DB.ATTRIBUTE_KEYWORDS:
				return _generate(EnumFieldScene, element, attribute_name)
			return _generate(UnrecognizedFieldScene, element, attribute_name)

static func _generate(widget: PackedScene, element: Element, attribute: String) -> Control:
	var widget_instance := widget.instantiate()
	widget_instance.element = element
	widget_instance.attribute_name = attribute
	return widget_instance

static func _generate_no_name(widget: PackedScene, element: Element) -> Control:
	var widget_instance := widget.instantiate()
	widget_instance.element = element
	return widget_instance
