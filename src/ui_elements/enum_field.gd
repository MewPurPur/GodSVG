# An editor to be tied to an enum attribute.
extends LineEditButton

var tag: Tag
var attribute_name: String

const bold_font = preload("res://visual/fonts/FontBold.ttf")
const reload_icon = preload("res://visual/icons/Reload.svg")

func set_value(new_value: String, save := true) -> void:
	sync(new_value)
	var attribute := tag.get_attribute(attribute_name)
	if attribute.get_value() != new_value:
		attribute.set_value(new_value, save)


func _ready() -> void:
	var attribute: AttributeEnum = tag.get_attribute(attribute_name)
	set_value(attribute.get_value())
	attribute.value_changed.connect(set_value)
	tooltip_text = attribute_name
	placeholder_text = tag.get_default(attribute_name)
	focus_entered.connect(reset_font_color)

func _on_pressed() -> void:
	var btn_arr: Array[Button] = []
	# Add a default.
	var reset_btn := ContextPopup.create_button("", set_value.bind(""),
			tag.get_attribute(attribute_name).get_value().is_empty(), reload_icon)
	reset_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_arr.append(reset_btn)
	# Add a button for each enum value.
	for enum_constant in DB.attribute_enum_values[attribute_name]:
		var btn := ContextPopup.create_button(enum_constant, set_value.bind(enum_constant),
				enum_constant == tag.get_attribute(attribute_name).get_value())
		if enum_constant == tag.get_default(attribute_name):
			btn.add_theme_font_override("font", bold_font)
		btn_arr.append(btn)
	var value_picker := ContextPopup.new()
	value_picker.setup(btn_arr, false, size.x)
	HandlerGUI.popup_under_rect(value_picker, get_global_rect(), get_viewport())


func _on_text_submitted(new_text: String) -> void:
	if new_text.is_empty() or new_text in DB.attribute_enum_values[attribute_name]:
		set_value(new_text)
	else:
		sync(tag.get_attribute(attribute_name).get_value())

func _on_text_change_canceled() -> void:
	sync(tag.get_attribute(attribute_name).get_value())


func _on_text_changed(new_text: String) -> void:
	font_color = GlobalSettings.get_validity_color(
			not new_text in DB.attribute_enum_values[attribute_name])

func sync(new_value: String) -> void:
	text = new_value
	reset_font_color()
	if new_value == tag.get_default(attribute_name):
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
