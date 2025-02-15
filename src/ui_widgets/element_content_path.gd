extends VBoxContainer

@onready var attribute_container: HFlowContainer = $AttributeContainer
@onready var path_field: VBoxContainer = $PathField

var element: Element

func _ready() -> void:
	path_field.element = element
	path_field.setup()
	path_field.focused.connect(State.normal_select.bind(element.xid))
	
	for attribute in DB.get_recognized_attributes("path"):
		if attribute == "d":
			continue
		var input_field := AttributeFieldBuilder.create(attribute, element)
		input_field.focus_entered.connect(State.normal_select.bind(element.xid))
		attribute_container.add_child(input_field)
