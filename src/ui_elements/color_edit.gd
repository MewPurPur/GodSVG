## A color editor, not tied to any attribute.
extends AttributeEditor

const ColorPopup = preload("res://src/ui_elements/color_popup.tscn")
const ColorPickerPopup = preload("res://src/ui_elements/color_picker_popup.tscn")
const checkerboard = preload("res://visual/ColorButtonBG.svg")

@onready var color_button: Button = $Button
@onready var color_edit: LineEdit = $LineEdit
@onready var color_picker: Popup

@export var enable_palettes := true

signal value_changed(new_value: String)
var current_value: String:
	set(new_value):
		current_value = validate(new_value)
		value_changed.emit(new_value)


func _ready() -> void:
	color_edit.text = current_value
	color_edit.tooltip_text = attribute_name

func validate(new_value: String) -> String:
	if is_color_valid_non_hex(new_value) or new_value.is_valid_html_color():
		return new_value.trim_prefix("#")
	return "000"

func _on_value_changed(new_value: String) -> void:
	color_edit.text = new_value.trim_prefix("#")
	queue_redraw()
	if attribute != null:
		attribute.set_value(new_value)

func _on_button_pressed() -> void:
	if enable_palettes:
		color_picker = ColorPopup.instantiate()
	else:
		color_picker = ColorPickerPopup.instantiate()
	color_picker.current_value = current_value
	add_child(color_picker)
	color_picker.color_picked.connect(_on_color_picked)
	Utils.popup_under_control(color_picker, color_edit)

func _draw() -> void:
	var button_size := color_button.get_size()
	var line_edit_size := color_edit.get_size()
	draw_set_transform(Vector2(line_edit_size.x, 1))
	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	if Utils.named_colors.has(current_value):
		stylebox.bg_color = Utils.named_colors[current_value]
	else:
		stylebox.bg_color = Color.from_string(current_value, Color.TRANSPARENT)
	draw_texture(checkerboard, Vector2.ZERO)
	draw_style_box(stylebox, Rect2(Vector2.ZERO, button_size - Vector2(1, 2)))


func _on_focus_exited() -> void:
	current_value = color_edit.text

func _on_text_submitted(new_text: String) -> void:
	current_value = new_text


func _on_color_picked(new_color: String, close_picker: bool) -> void:
	current_value = new_color
	if close_picker:
		color_picker.queue_free()

func is_color_valid_non_hex(color: String) -> bool:
	return color == "none" or Utils.named_colors.has(color) or\
	(color.begins_with("url(#") and color.ends_with(")"))

func is_color_valid(color: String) -> bool:
	return color.is_valid_html_color() or is_color_valid_non_hex(color)


func _on_button_resized() -> void:
	# Not sure why this is needed, but the button doesn't have a correct size at first
	# which screws with the drawing logic.
	queue_redraw()

func _on_line_edit_text_changed(new_text: String) -> void:
	if is_color_valid(new_text):
		color_edit.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.6))
	else:
		color_edit.add_theme_color_override(&"font_color", Color(1.0, 0.6, 0.6))
