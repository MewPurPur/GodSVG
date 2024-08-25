# An editor to be tied to an enum attribute.
extends LineEditButton

var element: Element
var attribute_name: String  # May propagate.

const reload_icon = preload("res://visual/icons/Reload.svg")

func set_value(new_value: String, save := false) -> void:
	sync(new_value)
	element.set_attribute(attribute_name, new_value)
	if save:
		SVG.queue_save()

func setup_placeholder() -> void:
	placeholder_text = element.get_default(attribute_name)


func _ready() -> void:
	GlobalSettings.basic_colors_changed.connect(resync)
	set_value(element.get_attribute_value(attribute_name, true))
	element.attribute_changed.connect(_on_element_attribute_changed)
	if attribute_name in DB.propagated_attributes:
		element.ancestor_attribute_changed.connect(_on_element_ancestor_attribute_changed)
	text_submitted.connect(_on_text_submitted)
	focus_entered.connect(reset_font_color)
	text_changed.connect(_on_text_changed)
	text_change_canceled.connect(sync_to_attribute)
	pressed.connect(_on_pressed)
	button_gui_input.connect(_on_button_gui_input)
	tooltip_text = attribute_name
	setup_placeholder()


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync_to_attribute()

func _on_element_ancestor_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		setup_placeholder()
		resync()


func _on_pressed() -> void:
	var btn_arr: Array[Button] = []
	# Add a default.
	var reset_btn := ContextPopup.create_button("", set_value.bind("", true),
			element.get_attribute_value(attribute_name, true).is_empty(), reload_icon)
	reset_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_arr.append(reset_btn)
	# Add a button for each enum value.
	for enum_constant in DB.attribute_enum_values[attribute_name]:
		var btn := ContextPopup.create_button(enum_constant,
				set_value.bind(enum_constant, true),
				enum_constant == element.get_attribute_value(attribute_name, true))
		if enum_constant == element.get_default(attribute_name):
			btn.add_theme_font_override("font", ThemeUtils.bold_font)
		btn_arr.append(btn)
	var value_picker := ContextPopup.new()
	value_picker.setup(btn_arr, false, size.x)
	HandlerGUI.popup_under_rect(value_picker, get_global_rect(), get_viewport())


func _on_text_submitted(new_text: String) -> void:
	if new_text.is_empty() or new_text in DB.attribute_enum_values[attribute_name]:
		set_value(new_text)
	else:
		sync_to_attribute()

func sync_to_attribute() -> void:
	sync(element.get_attribute_value(attribute_name, true))


func _on_text_changed(new_text: String) -> void:
	font_color = GlobalSettings.get_validity_color(
			not new_text in DB.attribute_enum_values[attribute_name])

func resync() -> void:
	sync(text)

func sync(new_value: String) -> void:
	text = new_value
	reset_font_color()
	if new_value == element.get_default(attribute_name):
		font_color = GlobalSettings.savedata.basic_color_warning


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and\
	event.is_pressed():
		accept_event()
		Utils.throw_mouse_motion_event()
	else:
		temp_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
