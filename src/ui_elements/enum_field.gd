## An editor to be tied to an AttributeEnum.
extends HBoxContainer

signal focused
var attribute: AttributeEnum
var attribute_name: String

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const bold_font = preload("res://visual/fonts/FontBold.ttf")

@onready var indicator: LineEdit = $LineEdit
@onready var button: Button = $Button

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR) -> void:
	sync(attribute.autoformat(new_value))
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
	indicator.tooltip_text = attribute_name

func _on_button_pressed() -> void:
	var value_picker := ContextPopup.instantiate()
	var btn_arr: Array[Button] = []
	for enum_constant in attribute.possible_values:
		var btn := Utils.create_btn(enum_constant, _on_option_pressed.bind(enum_constant),
				enum_constant == attribute.get_value())
		if enum_constant == attribute.default:
			btn.add_theme_font_override(&"font", bold_font)
		btn_arr.append(btn)
	add_child(value_picker)
	value_picker.set_button_array(btn_arr, false, size.x)
	Utils.popup_under_rect(value_picker, indicator.get_global_rect(), get_viewport())

func _on_option_pressed(option: String) -> void:
	set_value(option)


func _on_focus_entered() -> void:
	indicator.remove_theme_color_override(&"font_color")
	focused.emit()

func _on_text_submitted(new_text: String) -> void:
	indicator.release_focus()
	if new_text in attribute.possible_values:
		set_value(new_text)
	elif new_text.is_empty():
		set_value(attribute.default)
	else:
		sync(attribute.get_value())

func _on_text_change_canceled() -> void:
	sync(attribute.get_value())


func _on_text_changed(new_text: String) -> void:
	if new_text in attribute.possible_values:
		indicator.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.6))
	else:
		indicator.add_theme_color_override(&"font_color", Color(1.0, 0.6, 0.6))

func sync(new_value: String) -> void:
	if indicator != null:
		indicator.text = new_value
		if new_value == attribute.default:
			indicator.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
		else:
			indicator.remove_theme_color_override(&"font_color")


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and\
	event.is_pressed():
		accept_event()
		var mouse_motion_event := InputEventMouseMotion.new()
		mouse_motion_event.position = get_viewport().get_mouse_position()
		Input.parse_input_event(mouse_motion_event)
	else:
		button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
