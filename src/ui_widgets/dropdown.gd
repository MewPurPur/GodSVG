# A dropdown with multiple options, not tied to any attribute.
extends HBoxContainer

@export var values: Array[Variant]
@export var disabled_values: Array[Variant]
@export var restricted := true
@export var align_left := false  # The alignment of the popup options' text.
# TODO Typed Dictionary wonkiness
@export var value_text_map: Dictionary = {}  # Dictionary[Variant, String]

@onready var line_edit: BetterLineEdit = $LineEdit

signal value_changed(new_value: Variant)
var _value: Variant

func set_value(new_value: Variant, emit_changed := true) -> void:
	if _value != new_value:
		_value = new_value
		if emit_changed:
			value_changed.emit(_value)
	if is_instance_valid(line_edit):
		_sync_line_edit()

func _ready() -> void:
	line_edit.text_changed.connect(_on_text_changed)
	line_edit.text_submitted.connect(_on_text_submitted)
	_sync_line_edit()
	
	var max_width := 0
	for val in values:
		max_width = maxi(int(line_edit.get_theme_font("font").get_string_size(str(val),
				HORIZONTAL_ALIGNMENT_LEFT, -1, line_edit.get_theme_font_size("font_size")).x),
				max_width)
	line_edit.size.x = max_width + 4

func _on_button_pressed() -> void:
	var btn_arr: Array[Button] = []
	for val in values:
		btn_arr.append(ContextPopup.create_button(value_text_map.get(val, str(val)),
				set_value.bind(val), disabled_values.has(val) or val == _value))
	
	var value_picker := ContextPopup.new()
	value_picker.setup(btn_arr, align_left, size.x, get_window().size.y / 2.0)
	HandlerGUI.popup_under_rect(value_picker, line_edit.get_global_rect(), get_viewport())


func _on_text_submitted(new_text: String) -> void:
	if (restricted and new_text in values) or not restricted:
		set_value(new_text)
	else:
		_sync_line_edit()
	line_edit.remove_theme_color_override("font_color")

func _on_text_changed(new_text: String) -> void:
	if restricted:
		line_edit.add_theme_color_override("font_color",
				Configs.savedata.get_validity_color(not new_text in values))

func _sync_line_edit() -> void:
	line_edit.text = value_text_map.get(_value, str(_value))
