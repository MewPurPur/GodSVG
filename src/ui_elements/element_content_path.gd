extends VBoxContainer

const TransformField = preload("res://src/ui_elements/transform_field.tscn")
const NumberField = preload("res://src/ui_elements/number_field.tscn")
const NumberSlider = preload("res://src/ui_elements/number_field_with_slider.tscn")
const ColorField = preload("res://src/ui_elements/color_field.tscn")
const EnumField = preload("res://src/ui_elements/enum_field.tscn")

@onready var attribute_container: HFlowContainer = $AttributeContainer
@onready var path_field: VBoxContainer = $PathField

var element: Element

func _ready() -> void:
	path_field.element = element
	path_field.setup()
	path_field.focused.connect(Indications.normal_select.bind(element.xid))
	
	for attribute_key in DB.recognized_attributes["path"]:
		if attribute_key == "d":
			continue
		var input_field: Control
		match DB.get_attribute_type(attribute_key):
			DB.AttributeType.TRANSFORM_LIST: input_field = TransformField.instantiate()
			DB.AttributeType.COLOR: input_field = ColorField.instantiate()
			DB.AttributeType.ENUM: input_field = EnumField.instantiate()
			DB.AttributeType.NUMERIC:
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
		input_field.attribute_name = attribute_key
		input_field.element = element
		# Focused signal for pathdata attribute.
		input_field.focus_entered.connect(Indications.normal_select.bind(element.xid))
		attribute_container.add_child(input_field)
