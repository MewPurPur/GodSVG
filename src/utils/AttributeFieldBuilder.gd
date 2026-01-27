@abstract class_name AttributeFieldBuilder

const TransformFieldScene = preload("res://src/ui_widgets/transform_field.tscn")
const PathdataFieldScene = preload("res://src/ui_widgets/pathdata_field.tscn")
const NumberFieldScene = preload("res://src/ui_widgets/number_field.tscn")
const NumberSliderScene = preload("res://src/ui_widgets/number_field_with_slider.tscn")
const ColorFieldScene = preload("res://src/ui_widgets/color_field.tscn")
const EnumFieldScene = preload("res://src/ui_widgets/enum_field.tscn")
const IdFieldScene = preload("res://src/ui_widgets/id_field.tscn")
const HrefFieldScene = preload("res://src/ui_widgets/href_field.tscn")
const UnrecognizedFieldScene = preload("res://src/ui_widgets/unrecognized_field.tscn")

static func create(attribute: String) -> Control:
	match DB.get_attribute_type(attribute):
		DB.AttributeType.ID: return IdFieldScene.instantiate()
		DB.AttributeType.HREF: return HrefFieldScene.instantiate()
		DB.AttributeType.PATHDATA: return PathdataFieldScene.instantiate()
		DB.AttributeType.TRANSFORM_LIST: return _generate(TransformFieldScene, attribute)
		DB.AttributeType.COLOR: return _generate(ColorFieldScene, attribute)
		DB.AttributeType.ENUM: return _generate(EnumFieldScene, attribute)
		DB.AttributeType.NUMERIC:
			match DB.ATTRIBUTE_NUMBER_RANGE[attribute]:
				DB.NumberRange.UNIT: return _generate(NumberSliderScene, attribute)
				_: return _generate(NumberFieldScene, attribute)
		_: return _generate(UnrecognizedFieldScene, attribute)

static func _generate(widget: PackedScene, attribute: String) -> Control:
	var widget_instance := widget.instantiate()
	widget_instance.attribute_name = attribute
	return widget_instance
