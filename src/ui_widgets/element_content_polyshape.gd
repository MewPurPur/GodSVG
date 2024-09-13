extends VBoxContainer

@onready var attribute_container: HFlowContainer = $AttributeContainer
@onready var points_field: VBoxContainer = $PointsField

var element: Element

func _ready() -> void:
	points_field.element = element
	points_field.setup()
	points_field.focused.connect(Indications.normal_select.bind(element.xid))
	
	for attribute in DB.recognized_attributes[element.name]:
		if attribute == "points":
			continue
		var input_field := AttributeFieldBuilder.create(attribute, element)
		# Focused signal for pathdata attribute.
		input_field.focus_entered.connect(Indications.normal_select.bind(element.xid))
		attribute_container.add_child(input_field)
