# A color editor, not tied to any attribute.
extends LineEditButton

const ColorPopupScene = preload("res://src/ui_widgets/color_popup.tscn")
const checkerboard = preload("res://assets/icons/CheckerboardColorButton.svg")

@export var alpha_enabled := false

signal value_changed(new_value: String, final: bool, old_final_value: String)
var _final_value: String
var _value: String

func set_value(new_value: String, is_final := true) -> void:
	new_value = ColorParser.add_hash_if_hex(new_value)
	if ColorParser.is_valid(new_value, alpha_enabled):
		if is_final and new_value != _final_value:
			_value = new_value
			value_changed.emit(_value, true, _final_value)
			_final_value = _value
		elif _value != new_value:
			_value = new_value
			value_changed.emit(_value, false, _final_value)
	sync()

func set_value_no_signal(new_value: String) -> void:
	_value = ColorParser.add_hash_if_hex(new_value)
	sync()

func set_initial_value(new_value: String) -> void:
	set_value_no_signal(new_value)
	_final_value = _value

func get_value() -> String:
	return _value


func _ready() -> void:
	text_submitted.connect(set_value)
	pressed.connect(_on_pressed)
	text_changed.connect(_on_text_changed)
	text_change_canceled.connect(sync)
	button_gui_input.connect(queue_redraw.unbind(1))
	if alpha_enabled:
		custom_minimum_size.x += 14.0
	sync()


func sync() -> void:
	text = _value.trim_prefix("#")
	reset_font_color()
	queue_redraw()

func _on_pressed() -> void:
	var color_picker := ColorPopupScene.instantiate()
	color_picker.alpha_enabled = alpha_enabled
	color_picker.setup(ColorParser.add_hash_if_hex(_value), ColorParser.text_to_color(_value))
	HandlerGUI.popup_under_rect(color_picker, get_global_rect(), get_viewport())
	color_picker.color_picked.connect(set_value)

func _on_text_changed(new_text: String) -> void:
	font_color = Configs.savedata.get_validity_color(not ColorParser.is_valid(ColorParser.add_hash_if_hex(new_text), alpha_enabled))

func _draw() -> void:
	super()
	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.bg_color = ColorParser.text_to_color(ColorParser.add_hash_if_hex(_value), Color.BLACK, alpha_enabled)
	draw_texture(checkerboard, Vector2(size.x - button_width, 1))
	draw_style_box(stylebox, Rect2(size.x - button_width, 1, button_width - 1, size.y - 2))
	if is_instance_valid(temp_button) and temp_button.button_pressed:
		draw_button_border("pressed")
	elif is_instance_valid(temp_button) and temp_button.get_global_rect().has_point(
	get_viewport().get_mouse_position()):
		draw_button_border("hover")
	else:
		draw_button_border("normal")
