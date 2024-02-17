## An editor to be tied to a transform attribute.
extends HBoxContainer

signal focused
var attribute: AttributeTransform
var attribute_name: String

const TransformPopup = preload("res://src/ui_elements/transform_popup.tscn")

@onready var line_edit: BetterLineEdit = $LineEdit
@onready var popup_button: Button = $Button

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR):
	sync(attribute.autoformat(new_value))
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

func _on_focus_entered() -> void:
	focused.emit()

func _on_text_submitted(submitted_text: String) -> void:
	set_value(submitted_text)

func _on_matrix_popup_edited(new_matrix: String) -> void:
	set_value(new_matrix)

func sync(new_value: String) -> void:
	line_edit.text = new_value

func _on_button_pressed() -> void:
	var transform_popup := TransformPopup.instantiate()
	transform_popup.attribute_ref = attribute
	add_child(transform_popup)
	Utils.popup_under_rect(transform_popup, line_edit.get_global_rect(), get_viewport())


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and\
	event.is_pressed():
		accept_event()
		var mouse_motion_event := InputEventMouseMotion.new()
		mouse_motion_event.position = get_viewport().get_mouse_position()
		Input.parse_input_event(mouse_motion_event)
	else:
		popup_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
