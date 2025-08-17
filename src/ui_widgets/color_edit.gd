# A color editor, not tied to any attribute.
extends LineEditButton

const ColorEditPopup = preload("res://src/ui_widgets/color_edit_popup.gd")

const ColorEditPopupScene = preload("res://src/ui_widgets/color_edit_popup.tscn")
const checkerboard = preload("res://assets/icons/CheckerboardColorButton.svg")

var color_picker: ColorEditPopup

@export var enable_alpha := false

signal value_changed(new_value: String)
var value: String:
	set(new_value):
		new_value = ColorParser.add_hash_if_hex(new_value)
		if ColorParser.is_valid(new_value, enable_alpha):
			if new_value != value:
				value = new_value
				value_changed.emit(value)
		sync()


func _ready() -> void:
	text_submitted.connect(func(x: String) -> void: value = x)
	pressed.connect(_on_pressed)
	text_changed.connect(_on_text_changed)
	text_change_canceled.connect(sync)
	button_gui_input.connect(queue_redraw.unbind(1))
	if enable_alpha:
		custom_minimum_size.x += 14.0
	sync()


func sync() -> void:
	text = value.trim_prefix("#")
	reset_font_color()
	queue_redraw()

func _on_pressed() -> void:
	color_picker = ColorEditPopupScene.instantiate()
	if enable_alpha:
		color_picker.enable_alpha = true
	color_picker.current_value = ColorParser.add_hash_if_hex(value)
	HandlerGUI.popup_under_rect(color_picker, get_global_rect(), get_viewport())
	color_picker.color_picked.connect(_on_color_picked)

func _on_text_changed(new_text: String) -> void:
	font_color = Configs.savedata.get_validity_color(
			not ColorParser.is_valid(ColorParser.add_hash_if_hex(new_text), enable_alpha))

func _draw() -> void:
	super()
	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.bg_color = ColorParser.text_to_color(ColorParser.add_hash_if_hex(value),
			Color(), enable_alpha)
	draw_texture(checkerboard, Vector2(size.x - button_width, 1))
	draw_style_box(stylebox, Rect2(size.x - button_width, 1, button_width - 1, size.y - 2))
	if is_instance_valid(temp_button) and temp_button.button_pressed:
		draw_button_border("pressed")
	elif is_instance_valid(temp_button) and temp_button.get_global_rect().has_point(
	get_viewport().get_mouse_position()):
		draw_button_border("hover")
	else:
		draw_button_border("normal")

func _on_color_picked(new_color: String) -> void:
	value = new_color
