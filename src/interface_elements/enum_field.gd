extends AttributeEditor

@onready var value_picker: Popup = $EnumPopup
@onready var indicator: LineEdit = $MainLine/LineEdit
@onready var main_container: VBoxContainer = %MainContainer

signal value_changed(new_value: String)
var value: String:
	set(new_value):
		if value != new_value:
			value = new_value
			value_changed.emit(new_value)


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		value = attribute.possible_values[0]
		for enum_constant in attribute.possible_values:
			var butt := Button.new()
			butt.text = str(enum_constant)
			main_container.add_child(butt)
			butt.pressed.connect(_on_option_pressed.bind(enum_constant))
	indicator.text = str(value)
	indicator.tooltip_text = attribute_name

func _on_button_pressed() -> void:
	value_picker.popup(Rect2(global_position + Vector2(0, size.y), size))


func _on_option_pressed(option: String) -> void:
	value_picker.hide()
	value = option

func _on_value_changed(new_value: String) -> void:
	indicator.text = new_value
	if attribute != null:
		attribute.value = new_value
