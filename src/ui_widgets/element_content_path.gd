extends VBoxContainer

const TransformField = preload("res://src/ui_widgets/transform_field.tscn")
const NumberField = preload("res://src/ui_widgets/number_field.tscn")
const NumberSlider = preload("res://src/ui_widgets/number_field_with_slider.tscn")
const ColorField = preload("res://src/ui_widgets/color_field.tscn")
const EnumField = preload("res://src/ui_widgets/enum_field.tscn")

@onready var attribute_container: HFlowContainer = $AttributeContainer
@onready var path_field: VBoxContainer = $PathField

var element: Element

func _ready() -> void:
	path_field.element = element
	path_field.setup()
	path_field.focused.connect(Indications.normal_select.bind(element.xid))
	
	for attribute in DB.recognized_attributes["path"]:
		if attribute == "d":
			continue
		var input_field := AttributeFieldBuilder.create(attribute, element)
		# Focused signal for pathdata attribute.
		input_field.focus_entered.connect(Indications.normal_select.bind(element.xid))
		attribute_container.add_child(input_field)
