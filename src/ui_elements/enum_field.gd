## An editor to be tied to an AttributeEnum.
extends HBoxContainer

var attribute: AttributeEnum
var attribute_name: String

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const bold_font = preload("res://visual/fonts/FontBold.ttf")

@onready var indicator: LineEdit = $LineEdit

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR):
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
	indicator.tooltip_text = attribute_name

func _on_button_pressed() -> void:
	var value_picker := ContextPopup.instantiate()
	var buttons_arr: Array[Button] = []
	for enum_constant in attribute.possible_values:
		var btn := Button.new()
		btn.text = enum_constant
		btn.pressed.connect(_on_option_pressed.bind(enum_constant))
		if enum_constant == attribute.get_value():
			btn.disabled = true
		if attribute != null and enum_constant == attribute.default:
			btn.add_theme_font_override(&"font", bold_font)
		buttons_arr.append(btn)
	add_child(value_picker)
	value_picker.set_btn_array(buttons_arr)
	value_picker.set_min_width(74)
	Utils.popup_under_control(value_picker, indicator)

func _on_option_pressed(option: String) -> void:
	set_value(option)


func _on_text_submitted(new_text: String) -> void:
	indicator.release_focus()
	if new_text in attribute.possible_values:
		set_value(new_text)
	elif new_text.is_empty():
		indicator.text = attribute.default
	else:
		indicator.text = attribute.get_value()

func _on_text_changed(new_text: String) -> void:
	if new_text in attribute.possible_values:
		indicator.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.6))
	else:
		indicator.add_theme_color_override(&"font_color", Color(1.0, 0.6, 0.6))

func sync(new_value: String) -> void:
	if indicator != null:
		indicator.text = new_value
		if attribute.get_value() == attribute.default:
			indicator.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
		else:
			indicator.remove_theme_color_override(&"font_color")
