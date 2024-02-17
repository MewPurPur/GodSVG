## A color editor, not tied to any attribute.
extends HBoxContainer

const ColorPopup = preload("res://src/ui_elements/color_popup.tscn")
const ColorPickerPopup = preload("res://src/ui_elements/color_picker_popup.tscn")
const checkerboard = preload("res://visual/icons/backgrounds/ColorButtonBG.svg")

@onready var color_button: Button = $Button
@onready var color_edit: LineEdit = $LineEdit
@onready var color_picker: Popup

@export var enable_palettes := true

signal value_changed(new_value: String)
var value: String:
	set(new_value):
		new_value = ColorParser.add_hash_if_hex(new_value)
		if ColorParser.is_valid_hex(new_value) or ColorParser.is_valid_named(new_value) or\
		ColorParser.is_valid_rgb(new_value):
			new_value = new_value.trim_prefix("#")
			if new_value != value:
				value = new_value
				sync(value)
				value_changed.emit(value)
		else:
			sync(new_value)


func _ready() -> void:
	sync(value)

func is_color_valid_non_url(new_value: String) -> bool:
	new_value = ColorParser.add_hash_if_hex(new_value)
	return ColorParser.is_valid_named(new_value) or\
			ColorParser.is_valid_hex(new_value) or ColorParser.is_valid_rgb(new_value)

func sync(new_value: String) -> void:
	color_edit.remove_theme_color_override(&"font_color")
	color_edit.text = new_value.trim_prefix("#")
	queue_redraw()

func _on_button_pressed() -> void:
	if enable_palettes:
		color_picker = ColorPopup.instantiate()
	else:
		color_picker = ColorPickerPopup.instantiate()
	color_picker.current_value = value
	add_child(color_picker)
	color_picker.color_picked.connect(_on_color_picked)
	Utils.popup_under_rect(color_picker, color_edit.get_global_rect(), get_viewport())

func _draw() -> void:
	var button_size := color_button.get_size()
	var line_edit_size := color_edit.get_size()
	draw_set_transform(Vector2(line_edit_size.x, 1))
	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.bg_color = ColorParser.string_to_color(value)
	draw_texture(checkerboard, Vector2.ZERO)
	draw_style_box(stylebox, Rect2(Vector2.ZERO, button_size - Vector2(1, 2)))


func _on_text_submitted(new_text: String) -> void:
	value = new_text

func _on_color_picked(new_color: String, close_picker: bool) -> void:
	value = new_color
	if close_picker:
		color_picker.queue_free()


func _on_button_resized() -> void:
	# Not sure why this is needed, but the button doesn't have a correct size at first
	# which screws with the drawing logic.
	queue_redraw()

func _on_line_edit_text_changed(new_text: String) -> void:
	if is_color_valid_non_url(new_text):
		color_edit.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.6))
	else:
		color_edit.add_theme_color_override(&"font_color", Color(1.0, 0.6, 0.6))
