# An editor to be tied to a transform list attribute.
extends LineEditButton

var tag: Tag
var attribute_name: String

const TransformPopup = preload("res://src/ui_elements/transform_popup.tscn")

func set_value(new_value: String, save := true) -> void:
	sync(new_value)
	var attribute := tag.get_attribute(attribute_name)
	if attribute.get_value() != new_value:
		attribute.set_value(new_value, save)


func _notification(what: int) -> void:
	if what == Utils.CustomNotification.LANGUAGE_CHANGED:
		update_translation()

func _ready() -> void:
	var attribute: AttributeTransformList = tag.get_attribute(attribute_name)
	set_value(attribute.get_value())
	attribute.value_changed.connect(set_value)
	tooltip_text = attribute_name
	text_submitted.connect(set_value)
	text_changed.connect(setup_font)
	update_translation()


func update_translation() -> void:
	placeholder_text = TranslationServer.translate("No transforms")

func setup_font(new_text: String) -> void:
	use_code_font = !new_text.is_empty()

func sync(new_value: String) -> void:
	text = new_value
	setup_font(new_value)

func _on_pressed() -> void:
	var transform_popup := TransformPopup.instantiate()
	transform_popup.attribute_ref = tag.get_attribute(attribute_name)
	HandlerGUI.popup_under_rect(transform_popup, get_global_rect(), get_viewport())


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and\
	event.is_pressed():
		accept_event()
		Utils.throw_mouse_motion_event(get_viewport())
	else:
		if is_instance_valid(temp_button):
			temp_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
