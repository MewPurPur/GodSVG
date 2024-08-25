extends VBoxContainer

@onready var attribute_container: HFlowContainer = $AttributeContainer

var element: Element

func _ready() -> void:
	var offset_input_field := AttributeFieldBuilder.create("offset", element)
	attribute_container.add_child(offset_input_field)
	
	var color_input_field := AttributeFieldBuilder.create("stop-color", element)
	attribute_container.add_child(color_input_field)
	
	var opacity_input_field := AttributeFieldBuilder.create("stop-opacity", element)
	attribute_container.add_child(opacity_input_field)
