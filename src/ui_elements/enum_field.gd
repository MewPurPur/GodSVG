# An editor to be tied to an enum attribute.
extends LineEditButton

var attribute: AttributeEnum

const bold_font = preload("res://visual/fonts/FontBold.ttf")
const reload_icon = preload("res://visual/icons/Reload.svg")

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR) -> void:
	sync(new_value)
	if attribute.get_value() != new_value or update_type == Utils.UpdateType.FINAL:
		match update_type:
			Utils.UpdateType.INTERMEDIATE:
				attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
			Utils.UpdateType.FINAL:
				attribute.set_value(new_value, Attribute.SyncMode.FINAL)
			_:
				attribute.set_value(new_value)


func _ready() -> void:
	set_value(attribute.get_value())
	tooltip_text = attribute.name
	placeholder_text = attribute.get_default()
	focus_entered.connect(reset_font_color)

func _on_pressed() -> void:
	var btn_arr: Array[Button] = []
	# Add a default.
	var reset_btn := ContextPopup.create_button("", set_value.bind(""),
			attribute.get_value().is_empty(), reload_icon)
	reset_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_arr.append(reset_btn)
	# Add a button for each enum value.
	for enum_constant in DB.attribute_enum_values[attribute.name]:
		var btn := ContextPopup.create_button(enum_constant, set_value.bind(enum_constant),
				enum_constant == attribute.get_value())
		if enum_constant == attribute.get_default():
			btn.add_theme_font_override("font", bold_font)
		btn_arr.append(btn)
	var value_picker := ContextPopup.new()
	value_picker.setup(btn_arr, false, size.x)
	HandlerGUI.popup_under_rect(value_picker, get_global_rect(), get_viewport())


func _on_text_submitted(new_text: String) -> void:
	if new_text.is_empty() or new_text in DB.attribute_enum_values[attribute.name]:
		set_value(new_text)
	else:
		sync(attribute.get_value())

func _on_text_change_canceled() -> void:
	sync(attribute.get_value())


func _on_text_changed(new_text: String) -> void:
	font_color = GlobalSettings.get_validity_color(
			not new_text in DB.attribute_enum_values[attribute.name])

func sync(new_value: String) -> void:
	text = new_value
	reset_font_color()
	if new_value == attribute.get_default():
		font_color = GlobalSettings.basic_color_warning

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.BASIC_COLORS_CHANGED:
		sync(text)


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and\
	event.is_pressed():
		accept_event()
		Utils.throw_mouse_motion_event(get_viewport())
	else:
		temp_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
