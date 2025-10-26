# A dropdown with multiple options, not tied to any attribute.
extends Dropdown

@export var values: Array
@export var disabled_values: Array  # References values.
@export var aliases: Dictionary[String, Variant] = {}  # References values.
# TODO Typed Dictionary wonkiness
@export var value_text_map := {}  # Dictionary[Variant, String]

signal value_changed(new_value: Variant)
var _value: Variant

func set_value(new_value: Variant, emit_changed := true) -> void:
	if _value != new_value:
		_value = new_value
		if emit_changed:
			value_changed.emit(_value)
		set_text(get_value_string(_value))


func _on_text_submitted(new_text: String) -> void:
	var new_value: Variant = new_text
	if new_text in aliases:
		new_text = aliases[new_text]
	if new_value in values:
		set_value(new_value)

func _on_text_changed(new_text: String) -> void:
	if new_text in aliases:
		new_text = aliases[new_text]
	line_edit.add_theme_color_override("font_color", Configs.savedata.get_validity_color(not new_text in values))

func _get_dropdown_buttons() -> Array[Button]:
	var btn_arr: Array[Button] = []
	for i in values:
		btn_arr.append(ContextPopup.create_button(get_value_string(i), set_value.bind(i), disabled_values.has(i) or i == _value))
	return btn_arr

func get_value_string(p_value: Variant) -> String:
	return value_text_map.get(p_value, str(p_value))
