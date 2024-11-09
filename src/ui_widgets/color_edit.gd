# A color editor, not tied to any attribute.
extends LineEditButton

const ColorPopup = preload("res://src/ui_widgets/color_popup.tscn")
const ColorPickerPopup = preload("res://src/ui_widgets/color_picker_popup.tscn")
const checkerboard = preload("res://visual/icons/backgrounds/ColorButtonBG.svg")

@onready var color_picker: Control

@export var enable_palettes := true
@export var enable_alpha := false

signal value_changed(new_value: String)
var value: String:
	set(new_value):
		new_value = ColorParser.add_hash_if_hex(new_value)
		if ColorParser.is_valid_hex(new_value) or ColorParser.is_valid_named(new_value) or\
		ColorParser.is_valid_rgb(new_value) or (enable_alpha and\
		ColorParser.is_valid_hex_with_alpha(new_value)):
			if new_value != value:
				value = new_value
				value_changed.emit(value)
		sync(value)


func _ready() -> void:
	text_submitted.connect(func(x): set("value", x))
	pressed.connect(_on_pressed)
	text_changed.connect(_on_text_changed)
	text_change_canceled.connect(func(): sync(value))
	button_gui_input.connect(queue_redraw.unbind(1))
	if enable_alpha:
		custom_minimum_size.x += 14.0
	sync(value)

func is_color_valid_non_url(new_value: String) -> bool:
	new_value = ColorParser.add_hash_if_hex(new_value)
	return ColorParser.is_valid_named(new_value) or\
			ColorParser.is_valid_hex(new_value) or ColorParser.is_valid_rgb(new_value) or\
			(enable_alpha and ColorParser.is_valid_hex_with_alpha(new_value))

func sync(new_value: String) -> void:
	text = new_value.trim_prefix("#")
	reset_font_color()
	queue_redraw()

func _on_pressed() -> void:
	color_picker = ColorPopup.instantiate() if enable_palettes\
			else ColorPickerPopup.instantiate()
	color_picker.show_disable_color = false
	if enable_alpha:
		color_picker.enable_alpha = true
	color_picker.current_value = ColorParser.add_hash_if_hex(value)
	HandlerGUI.popup_under_rect(color_picker, get_global_rect(), get_viewport())
	color_picker.color_picked.connect(_on_color_picked)

func _on_text_changed(new_text: String) -> void:
	font_color = GlobalSettings.get_validity_color(!is_color_valid_non_url(new_text))

func _draw() -> void:
	super()
	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.bg_color = ColorParser.text_to_color(ColorParser.add_hash_if_hex(value),
			Color(), true)
	draw_texture(checkerboard, Vector2(size.x - BUTTON_WIDTH, 1))
	draw_style_box(stylebox, Rect2(size.x - BUTTON_WIDTH, 1, BUTTON_WIDTH - 1, size.y - 2))
	if is_instance_valid(temp_button) and temp_button.button_pressed:
		draw_button_border("pressed")
	elif is_instance_valid(temp_button) and temp_button.get_global_rect().has_point(
	get_viewport().get_mouse_position()):
		draw_button_border("hover")
	else:
		draw_button_border("normal")

func _on_color_picked(new_color: String, close_picker: bool) -> void:
	value = new_color
	if close_picker:
		color_picker.queue_free()
