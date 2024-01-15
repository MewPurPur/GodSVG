## An editor to be tied to a transform attribute.
extends VBoxContainer

signal focused
var attribute: AttributeTransform
var attribute_name: String

@onready var x1_edit: LineEdit = $FirstRow/X1
@onready var y1_edit: LineEdit = $FirstRow/Y1
@onready var z1_edit: LineEdit = $FirstRow/Z1

@onready var x2_edit: LineEdit = $SecondRow/X2
@onready var y2_edit: LineEdit = $SecondRow/Y2
@onready var z2_edit: LineEdit = $SecondRow/Z2

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR) -> void:
	var transform := TransformParser.text_to_transform(new_value)
	
	if attribute.default == TransformParser.transform_to_text(transform):
		new_value = attribute.default
	else:
		new_value = TransformParser.transform_to_text(transform)
	
	sync(attribute.autoformat(new_value))
	# Update the attribute.
	if new_value != attribute.get_value() or update_type == Utils.UpdateType.FINAL:
		match update_type:
			Utils.UpdateType.INTERMEDIATE:
				attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
			Utils.UpdateType.FINAL:
				attribute.set_value(new_value, Attribute.SyncMode.FINAL)
			_:
				attribute.set_value(new_value)

func set_num(new_number: float, update_type := Utils.UpdateType.REGULAR) -> void:
	set_value(NumberParser.num_to_text(new_number), update_type)


func _ready() -> void:
	set_value(attribute.get_value())
	attribute.value_changed.connect(set_value)

	x1_edit.tooltip_text = attribute_name + " X1"
	y1_edit.tooltip_text = attribute_name + " Y1"
	z1_edit.tooltip_text = attribute_name + " Z1"
	x2_edit.tooltip_text = attribute_name + " X2"
	y2_edit.tooltip_text = attribute_name + " Y2"
	z2_edit.tooltip_text = attribute_name + " Z2"

func _on_focus_exited() -> void:
	set_value("matrix(%s, %s, %s, %s, %s, %s)"%[x1_edit.text, x2_edit.text, y1_edit.text, y2_edit.text, z1_edit.text, z2_edit.text])

func _on_focus_entered() -> void:
	focused.emit()

func _on_text_submitted(_submitted_text: String) -> void:
	set_value("matrix(%s, %s, %s, %s, %s, %s)"%[x1_edit.text, x2_edit.text, y1_edit.text, y2_edit.text, z1_edit.text, z2_edit.text])

func sync(new_value: String) -> void:
	if x1_edit != null:
		var transform := TransformParser.text_to_transform(new_value)
		x1_edit.text = str(transform[0].x)
		y1_edit.text = str(transform[1].x)
		z1_edit.text = str(transform[2].x)
		x2_edit.text = str(transform[0].y)
		y2_edit.text = str(transform[1].y)
		z2_edit.text = str(transform[2].y)
		
		if new_value == attribute.default:
			x1_edit.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
			y1_edit.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
			z1_edit.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
			x2_edit.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
			y2_edit.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
			z2_edit.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
		else:
			x1_edit.remove_theme_color_override(&"font_color")
			y1_edit.remove_theme_color_override(&"font_color")
			z1_edit.remove_theme_color_override(&"font_color")
			x2_edit.remove_theme_color_override(&"font_color")
			y2_edit.remove_theme_color_override(&"font_color")
			z2_edit.remove_theme_color_override(&"font_color")
	queue_redraw()
