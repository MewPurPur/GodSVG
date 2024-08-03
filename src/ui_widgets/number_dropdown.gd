# A dropdown with multiple options, not tied to any attribute.
extends HBoxContainer

signal value_changed(new_value: String)

@onready var line_edit: BetterLineEdit = $LineEdit

@export var values: Array[float]
@export var is_integer := false
@export var restricted := true
@export var min_value := -INF
@export var max_value := INF

var value := "":
	set(new_value):
		var current_num := value.to_float()
		var proposed_num := new_value.to_float()
		if is_integer:
			proposed_num = roundi(proposed_num)
		if not restricted and not proposed_num in values:
			proposed_num = clampf(proposed_num, min_value, max_value)
		if not is_equal_approx(current_num, proposed_num):
			value = to_str(proposed_num)
			value_changed.emit(value)
			if is_instance_valid(line_edit):
				line_edit.text = value

func _on_button_pressed() -> void:
	var btn_arr: Array[Button] = []
	for val in values:
		var new_value := to_str(val)
		btn_arr.append(ContextPopup.create_button(new_value,
				set.bind("value", new_value), new_value == value))
	var value_picker := ContextPopup.new()
	value_picker.setup(btn_arr, false, size.x)
	HandlerGUI.popup_under_rect(value_picker, line_edit.get_global_rect(), get_viewport())


func to_str(num: float) -> String:
	var ret := String.num(num)
	if not (is_integer or "." in ret):
		ret += ".0"
	return ret

func _on_text_submitted(new_text: String) -> void:
	if (restricted and new_text.to_float() in values) or not restricted:
		value = new_text
	else:
		line_edit.text = value
	line_edit.remove_theme_color_override("font_color")


func _on_text_changed(new_text: String) -> void:
	if restricted:
		line_edit.add_theme_color_override("font_color",
				GlobalSettings.get_validity_color(not new_text.to_float() in values))
