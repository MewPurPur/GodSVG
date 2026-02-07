# A dropdown with multiple options, not tied to any attribute.
extends Dropdown

const edit_icon = preload("res://assets/icons/Edit.svg")

@export var use_integers := false
@export var min_value := 0.0
@export var max_value := INF
@export var special_value_exception := NAN  # An optional single value outside of the range.
@export var values_for_dropdown: PackedFloat64Array
@export var value_text_map: Dictionary[float, String] = {}

signal value_changed(new_value: float)
var _value := NAN

func set_value(new_value: float, emit_changed := true) -> void:
	if _value != new_value:
		_value = new_value
		if emit_changed:
			value_changed.emit(_value)
		set_text(get_value_string(_value))


func _on_text_submitted(new_text: String) -> void:
	var new_value := NumstringParser.evaluate(new_text)
	if new_value == special_value_exception:
		set_value(new_value)
	else:
		set_value(clampf(new_value, min_value, max_value))

func _get_dropdown_buttons() -> Array[ContextButton]:
	var btn_arr: Array[ContextButton] = [ContextButton.create_custom("", _enter_edit_mode, edit_icon)]
	for i in values_for_dropdown:
		btn_arr.append(ContextButton.create_custom(get_value_string(i), set_value.bind(i), null, is_equal_approx(i, _value)))
	return btn_arr

func get_value_string(p_value: float) -> String:
	return value_text_map.get(p_value, String.num_int64(roundi(p_value)) if use_integers else String.num(p_value))
