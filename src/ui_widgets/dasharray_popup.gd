extends PanelContainer

@onready var grid_container: GridContainer = %GridContainer

var element: Element
var attribute_name: String

func get_attribute_meta() -> AttributeMetaLengthList:
	return element.get_attribute_meta(attribute_name)

func setup(new_element: Element, new_attribute_name: String) -> void:
	element = new_element
	attribute_name = new_attribute_name

func _ready() -> void:
	sync()

func sync() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	
	grid_container.add_child(Label.new())
	grid_container.add_child(Label.new())
	grid_container.add_child(Label.new())
	
	for i in get_attribute_meta().get_dash_array_size():
		grid_container.add_child(Label.new())
		grid_container.add_child(LineEdit.new())
		grid_container.add_child(LineEdit.new())
