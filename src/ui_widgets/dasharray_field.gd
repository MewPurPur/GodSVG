# An editor to be tied to a transform list attribute.
extends LineEditButton

var element: Element
const attribute_name = "stroke-dasharray"  # Always propagates.

const DashArrayPopupScene = preload("res://src/ui_widgets/dasharray_popup.tscn")

func set_value(new_value: String, save := false) -> void:
	element.set_attribute(attribute_name, new_value)
	sync()
	if save:
		State.save_svg()


func _ready() -> void:
	Configs.language_changed.connect(sync_localization)
	sync_localization()
	sync()
	element.attribute_changed.connect(_on_element_attribute_changed)
	element.ancestor_attribute_changed.connect(_on_element_ancestor_attribute_changed)
	tooltip_text = attribute_name
	text_submitted.connect(set_value.bind(true))
	text_changed.connect(sync_font)
	sync_font(text)
	text_change_canceled.connect(sync)
	button_gui_input.connect(_on_button_gui_input)
	pressed.connect(_on_pressed)

func sync_localization() -> void:
	placeholder_text = Translator.translate("No transforms")

func sync() -> void:
	text = element.get_attribute_value(attribute_name)
	sync_font(text)

func sync_font(new_text: String) -> void:
	use_mono_font = not new_text.is_empty()


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync()

func _on_element_ancestor_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync()


func _on_pressed() -> void:
	var dasharray_popup := DashArrayPopupScene.instantiate()
	dasharray_popup.attribute = element.get_attribute(attribute_name)
	HandlerGUI.popup_under_rect(dasharray_popup, get_global_rect(), get_viewport())


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		accept_event()
		HandlerGUI.throw_mouse_motion_event()
	else:
		if is_instance_valid(temp_button):
			temp_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
