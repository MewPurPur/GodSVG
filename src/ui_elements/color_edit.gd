## A color editor, not tied to any attribute.
extends HBoxContainer

const ColorPopup = preload("res://src/ui_elements/color_popup.tscn")
const ColorPickerPopup = preload("res://src/ui_elements/color_picker_popup.tscn")
const checkerboard = preload("res://visual/icons/backgrounds/ColorButtonBG.svg")

@onready var color_button: Button = $Button
@onready var color_edit: LineEdit = $LineEdit
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
			new_value = new_value.trim_prefix("#")
			if new_value != value:
				value = new_value
				value_changed.emit(value)
		sync(value)


func _ready() -> void:
	if enable_alpha:
		color_edit.custom_minimum_size.x += 14.0
	sync(value)

func is_color_valid_non_url(new_value: String) -> bool:
	new_value = ColorParser.add_hash_if_hex(new_value)
	return ColorParser.is_valid_named(new_value) or\
			ColorParser.is_valid_hex(new_value) or ColorParser.is_valid_rgb(new_value) or\
			(enable_alpha and ColorParser.is_valid_hex_with_alpha(new_value))

func sync(new_value: String) -> void:
	color_edit.remove_theme_color_override("font_color")
	color_edit.text = new_value.trim_prefix("#")
	queue_redraw()

func _on_button_pressed() -> void:
	color_picker = ColorPopup.instantiate() if enable_palettes\
			else ColorPickerPopup.instantiate()
	color_picker.show_disable_color = false
	if enable_alpha:
		color_picker.enable_alpha = true
	color_picker.current_value = ColorParser.add_hash_if_hex(value)
	HandlerGUI.popup_under_rect(color_picker, color_edit.get_global_rect(), get_viewport())
	color_picker.color_picked.connect(_on_color_picked)

func _draw() -> void:
	var button_size := color_button.get_size()
	var line_edit_size := color_edit.get_size()
	draw_set_transform(Vector2(line_edit_size.x, 1))
	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.bg_color = ColorParser.string_to_color(
			ColorParser.add_hash_if_hex(value), Color(), true)
	draw_texture(checkerboard, Vector2.ZERO)
	draw_style_box(stylebox, Rect2(Vector2.ZERO, button_size - Vector2(1, 2)))


func _on_text_submitted(new_text: String) -> void:
	value = new_text

func _on_text_change_canceled() -> void:
	sync(value)

func _on_color_picked(new_color: String, close_picker: bool) -> void:
	value = new_color
	if close_picker:
		color_picker.queue_free()


func _on_button_resized() -> void:
	# Not sure why this is needed, but the button doesn't have a correct size at first
	# which screws with the drawing logic.
	queue_redraw()

func _on_line_edit_text_changed(new_text: String) -> void:
	add_theme_color_override("font_color",
			GlobalSettings.get_validity_color(!is_color_valid_non_url(new_text)))
