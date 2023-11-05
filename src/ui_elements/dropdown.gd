## A dropdown with multiple options, not tied to any attribute.
extends HBoxContainer

signal value_changed(new_value: String)

@onready var value_picker: Popup = $ContextPopup
@onready var line_edit: BetterLineEdit = $LineEdit

@export var values: Array[String]
@export var restricted := true

var current_value := "":
	set(new_value):
		if current_value != new_value:
			current_value = new_value
			value_changed.emit(current_value)
			if line_edit != null:
				line_edit.text = current_value

func _ready() -> void:
	if not values.is_empty():
		current_value = values[0]
	
	var btn_arr: Array[Button] = []
	for value in values:
		var button := Button.new()
		button.text = value
		button.pressed.connect(_on_value_chosen.bind(value))
		button.mouse_default_cursor_shape = CURSOR_POINTING_HAND
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_arr.append(button)
	value_picker.set_btn_array(btn_arr)
	
	var max_length := 0
	for value in values:
		max_length = maxi(value.length(), max_length)
		
	line_edit.custom_minimum_size.x = line_edit.get_theme_font(&"font").get_string_size(
			"m".repeat(max_length + 1), HORIZONTAL_ALIGNMENT_LEFT, -1,
			line_edit.get_theme_font_size(&"font_size")).x
	line_edit.size.x = 0

func _on_button_pressed() -> void:
	Utils.popup_under_control(value_picker, line_edit)

func _on_value_chosen(new_value: String) -> void:
	value_picker.hide()
	current_value = new_value


func _on_text_submitted(new_text: String) -> void:
	if (restricted and new_text in values) or not restricted:
		current_value = new_text
	else:
		line_edit.text = current_value
	line_edit.remove_theme_color_override(&"font_color")


func _on_text_changed(new_text: String) -> void:
	if restricted:
		if new_text in values:
			line_edit.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.6))
		else:
			line_edit.add_theme_color_override(&"font_color", Color(1.0, 0.6, 0.6))
