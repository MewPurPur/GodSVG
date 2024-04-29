# An editor to be tied to an enum attribute.
extends HBoxContainer

signal focused
var attribute: AttributeEnum

const bold_font = preload("res://visual/fonts/FontBold.ttf")
const reload_icon = preload("res://visual/icons/Reload.svg")

@onready var indicator: LineEdit = $LineEdit
@onready var button: Button = $Button

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
	indicator.tooltip_text = attribute.name
	indicator.placeholder_text = attribute.get_default()

func _on_button_pressed() -> void:
	var btn_arr: Array[Button] = []
	# Add a default.
	var reset_btn := Utils.create_btn("", set_value.bind(""),
			attribute.get_value().is_empty(), reload_icon)
	reset_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_arr.append(reset_btn)
	# Add a button for each enum value.
	for enum_constant in DB.attribute_enum_values[attribute.name]:
		var btn := Utils.create_btn(enum_constant, set_value.bind(enum_constant),
				enum_constant == attribute.get_value())
		if enum_constant == attribute.get_default():
			btn.add_theme_font_override("font", bold_font)
		btn_arr.append(btn)
	var value_picker := ContextPopup.new()
	value_picker.setup(btn_arr, false, size.x)
	HandlerGUI.popup_under_rect(value_picker, indicator.get_global_rect(), get_viewport())


func _on_focus_entered() -> void:
	indicator.remove_theme_color_override("font_color")
	focused.emit()

func _on_text_submitted(new_text: String) -> void:
	if new_text.is_empty() or new_text in DB.attribute_enum_values[attribute.name]:
		set_value(new_text)
	else:
		sync(attribute.get_value())

func _on_text_change_canceled() -> void:
	sync(attribute.get_value())


func _on_text_changed(new_text: String) -> void:
	indicator.add_theme_color_override("font_color", GlobalSettings.get_validity_color(
			not new_text in DB.attribute_enum_values[attribute.name]))

func sync(new_value: String) -> void:
	if indicator != null:
		indicator.text = new_value
		indicator.remove_theme_color_override("font_color")
		if new_value == attribute.get_default():
			indicator.add_theme_color_override("font_color", GlobalSettings.basic_color_warning)

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.BASIC_COLORS_CHANGED:
		sync(indicator.text)


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and\
	event.is_pressed():
		accept_event()
		Utils.throw_mouse_motion_event(get_viewport())
	else:
		button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
