# The need for a unique 0 value made the regular numeric dropdown unusable.
extends HBoxContainer

signal value_changed(new_value: String)

@onready var line_edit: BetterLineEdit = $LineEdit
@onready var button: Button = $Button

const values: PackedInt32Array = [0, 30, 60, 90, 120, 144, 240, 360]
const min_value := SaveData.MAX_FPS_MIN
const max_value := SaveData.MAX_FPS_MAX

var _value := ""

func set_value(new_value: String) -> void:
	var current_num := roundi(_value.to_float())
	var proposed_num := roundi(new_value.to_float())
	if is_nan(proposed_num) or proposed_num == INF:
		proposed_num = 0
	elif proposed_num != 0:
		proposed_num = clampi(proposed_num, min_value, max_value)
	
	if not is_equal_approx(current_num, proposed_num):
		_value = to_str(proposed_num)
		value_changed.emit(_value)
	elif _value.is_empty():
		_value = to_str(proposed_num)
	if is_instance_valid(line_edit):
		line_edit.text = _value

func _ready() -> void:
	line_edit.text_submitted.connect(set_value)
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	var btn_arr: Array[Button] = []
	for val in values:
		var new_value := to_str(val)
		btn_arr.append(ContextPopup.create_button(new_value,
				set_value.bind(new_value), new_value == _value))
	var value_picker := ContextPopup.new()
	value_picker.setup(btn_arr, false, size.x)
	HandlerGUI.popup_under_rect(value_picker, line_edit.get_global_rect(), get_viewport())


func to_str(num: int) -> String:
	return Translator.translate("Unlimited") if num == 0 else String.num_int64(num)
