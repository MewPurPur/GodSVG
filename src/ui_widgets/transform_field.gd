# An editor to be tied to a transform list attribute.
extends LineEditButton

var element: Element
var attribute_name: String  # Never propagates.

const TransformPopup = preload("res://src/ui_widgets/transform_popup.tscn")

func set_value(new_value: String, save := false) -> void:
	element.set_attribute(attribute_name, new_value)
	sync(element.get_attribute(attribute_name).get_value())
	if save:
		SVG.queue_save()


func _ready() -> void:
	GlobalSettings.language_changed.connect(update_translation)
	sync_to_attribute()
	element.attribute_changed.connect(_on_element_attribute_changed)
	tooltip_text = attribute_name
	text_submitted.connect(set_value.bind(true))
	text_changed.connect(setup_font)
	setup_font(text)
	text_change_canceled.connect(sync_to_attribute)
	button_gui_input.connect(_on_button_gui_input)
	pressed.connect(_on_pressed)
	update_translation()


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync_to_attribute()

func update_translation() -> void:
	placeholder_text = TranslationServer.translate("No transforms")

func setup_font(new_text: String) -> void:
	use_mono_font = !new_text.is_empty()

func sync(new_value: String) -> void:
	text = new_value

func _on_pressed() -> void:
	var transform_popup := TransformPopup.instantiate()
	transform_popup.attribute_ref = element.get_attribute(attribute_name)
	HandlerGUI.popup_under_rect(transform_popup, get_global_rect(), get_viewport())

func sync_to_attribute() -> void:
	set_value(element.get_attribute_value(attribute_name, true))


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and\
	event.is_pressed():
		accept_event()
		Utils.throw_mouse_motion_event()
	else:
		if is_instance_valid(temp_button):
			temp_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
