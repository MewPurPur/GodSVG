# A dropdown with multiple options, not tied to any attribute.
extends HBoxContainer

signal value_changed(new_value: String)

@onready var line_edit: BetterLineEdit = $LineEdit

@export var values: PackedFloat64Array
@export var is_integer := false
@export var restricted := true
@export var min_value := -INF
@export var max_value := INF

var _value := ""

func set_value(new_value: String) -> void:
	var current_num := _value.to_float()
	var proposed_num := new_value.to_float()
	if is_integer:
		proposed_num = roundi(proposed_num)
	if not restricted and not proposed_num in values:
		proposed_num = clampf(proposed_num, min_value, max_value)
	if not is_equal_approx(current_num, proposed_num) or _value.is_empty():
		_value = to_str(proposed_num)
		value_changed.emit(_value)
	if is_instance_valid(line_edit):
		line_edit.text = _value

func _on_button_pressed() -> void:
	var btn_arr: Array[Button] = []
	for val in values:
		var new_value := to_str(val)
		btn_arr.append(ContextPopup.create_button(new_value,
				set_value.bind(new_value), new_value == _value))
	var value_picker := ContextPopup.new()
	value_picker.setup(btn_arr, false, size.x)
	HandlerGUI.popup_under_rect(value_picker, line_edit.get_global_rect(), get_viewport())


func to_str(num: float) -> String:
	# Right now, all the places this is used benefit from showing "1" as "1.0".
	return String.num(num, 0 if is_integer else Utils.MAX_NUMERIC_PRECISION)

func _on_text_submitted(new_text: String) -> void:
	if (restricted and new_text.to_float() in values) or not restricted:
		set_value(new_text)
	else:
		line_edit.text = _value
	line_edit.remove_theme_color_override("font_color")


func _on_text_changed(new_text: String) -> void:
	if restricted:
		line_edit.add_theme_color_override("font_color",
				Configs.savedata.get_validity_color(not new_text.to_float() in values))
