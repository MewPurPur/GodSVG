## An editor to be tied to a transform attribute.
extends HBoxContainer

signal focused
var attribute: AttributeTransform
var attribute_name: String

const MatrixPopup = preload("res://src/ui_elements/matrix_popup.tscn")

@onready var line_edit: BetterLineEdit = $LineEdit

# TODO needs more work, can't handle every scenario.
func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR):
	# Validate the value.
	if not TransformParser.text_to_transform(new_value).is_finite():
		sync(attribute.get_value())
		return
	
	if TransformParser.text_to_transform(new_value) ==\
	TransformParser.text_to_transform(attribute.default):
		new_value = attribute.default
	
	sync(attribute.autoformat(new_value))
	# Update the attribute.
	if attribute.get_value() != new_value or update_type == Utils.UpdateType.FINAL:
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
	line_edit.tooltip_text = attribute_name

func _on_focus_exited() -> void:
	set_value(line_edit.text)

func _on_focus_entered() -> void:
	focused.emit()

func _on_text_submitted(submitted_text: String) -> void:
	set_value(submitted_text)

func matrix_popup_edited(new_matrix: String) -> void:
	set_value(new_matrix)

func sync(new_value: String) -> void:
	if line_edit != null:
		line_edit.text = new_value
		
		if new_value == attribute.default:
			line_edit.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
		else:
			line_edit.remove_theme_color_override(&"font_color")
	queue_redraw()

func _on_button_pressed() -> void:
	var matrix_popup := MatrixPopup.instantiate()
	matrix_popup.transform = attribute.get_transform()
	matrix_popup.matrix_edited.connect(matrix_popup_edited)
	add_child(matrix_popup)
	matrix_popup.initialize()
	Utils.popup_under_control(matrix_popup, line_edit)
