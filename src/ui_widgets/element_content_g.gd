extends VBoxContainer

@onready var attribute_container: HFlowContainer = $AttributeContainer

var element: Element

func _ready() -> void:
	for attribute in DB.recognized_attributes["g"]:
		var input_field := AttributeFieldBuilder.create(attribute, element)
		input_field.focus_entered.connect(Indications.normal_select.bind(element.xid))
		attribute_container.add_child(input_field)
