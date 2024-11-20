# A dropdown with multiple options, not tied to any attribute.
extends HBoxContainer

signal value_changed(new_value: String)

@onready var line_edit: BetterLineEdit = $LineEdit

@export var values: PackedStringArray
@export var restricted := true

var value := "":
	set(new_value):
		if value != new_value:
			value = new_value
			value_changed.emit(value)
		if is_instance_valid(line_edit):
			line_edit.text = value

func _ready() -> void:
	line_edit.text_changed.connect(_on_text_changed)
	line_edit.text_submitted.connect(_on_text_submitted)
	
	if not values.is_empty():
		value = values[0]
	
	var max_width := 0
	for val in values:
		max_width = maxi(int(line_edit.get_theme_font("font").get_string_size(val,
				HORIZONTAL_ALIGNMENT_LEFT, -1, line_edit.get_theme_font_size("font_size")).x),
				max_width)
	line_edit.size.x = max_width + 4

func _on_button_pressed() -> void:
	var btn_arr: Array[Button] = []
	for val in values:
		btn_arr.append(ContextPopup.create_button(val, _on_value_chosen.bind(val),
				val == value))
	
	var value_picker := ContextPopup.new()
	value_picker.setup(btn_arr, false, size.x)
	HandlerGUI.popup_under_rect(value_picker, line_edit.get_global_rect(), get_viewport())

func _on_value_chosen(new_value: String) -> void:
	value = new_value


func _on_text_submitted(new_text: String) -> void:
	if (restricted and new_text in values) or not restricted:
		value = new_text
	else:
		line_edit.text = value
	line_edit.remove_theme_color_override("font_color")


func _on_text_changed(new_text: String) -> void:
	if restricted:
		line_edit.add_theme_color_override("font_color",
				GlobalSettings.get_validity_color(not new_text in values))
