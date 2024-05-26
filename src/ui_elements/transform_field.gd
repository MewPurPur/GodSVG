# An editor to be tied to a transform list attribute.
extends LineEditButton

var attribute: AttributeTransform

const TransformPopup = preload("res://src/ui_elements/transform_popup.tscn")

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR) -> void:
	sync(attribute.format(new_value))
	if attribute.get_value() != new_value or update_type == Utils.UpdateType.FINAL:
		match update_type:
			Utils.UpdateType.INTERMEDIATE:
				attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
			Utils.UpdateType.FINAL:
				attribute.set_value(new_value, Attribute.SyncMode.FINAL)
			_:
				attribute.set_value(new_value)


func _notification(what: int) -> void:
	if what == Utils.CustomNotification.LANGUAGE_CHANGED:
		update_translation()

func _ready() -> void:
	set_value(attribute.get_value())
	attribute.value_changed.connect(set_value)
	tooltip_text = attribute.name
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
	transform_popup.attribute_ref = attribute
	HandlerGUI.popup_under_rect(transform_popup, get_global_rect(), get_viewport())


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and\
	event.is_pressed():
		accept_event()
		Utils.throw_mouse_motion_event(get_viewport())
	else:
		if is_instance_valid(temp_button):
			temp_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
