extends PanelContainer

@onready var grid_container: GridContainer = %GridContainer

var attribute: AttributeDasharray

func _ready() -> void:
	sync()

func sync() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	
	grid_container.add_child(Label.new())
	grid_container.add_child(Label.new())
	grid_container.add_child(Label.new())
	
	for i in attribute.get_dash_array_size():
		grid_container.add_child(Label.new())
		grid_container.add_child(LineEdit.new())
		grid_container.add_child(LineEdit.new())
