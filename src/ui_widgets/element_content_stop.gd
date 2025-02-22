extends VBoxContainer

@onready var attribute_container: HFlowContainer = $AttributeContainer

var element: Element

func _ready() -> void:
	for attrib_name in ["offset", "stop-color", "stop-opacity"]:
		var input_field := AttributeFieldBuilder.create(attrib_name, element)
		input_field.focus_entered.connect(State.normal_select.bind(element.xid))
		attribute_container.add_child(input_field)
