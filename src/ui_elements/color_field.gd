## An editor to be tied to a color attribute.
extends AttributeEditor

const ColorPopup = preload("res://src/ui_elements/color_popup.tscn")
const checkerboard = preload("res://visual/ColorButtonBG.svg")

@onready var color_button: Button = $Button
@onready var color_edit: LineEdit = $LineEdit
@onready var color_popup: Popup

signal value_changed(new_value: String)
var _value: String  # Must not be updated directly.

func set_value(new_value: String, emit_value_changed := true):
	var old_value := _value
	_value = validate(new_value)
	set_text_tint()
	if _value != old_value and emit_value_changed:
		value_changed.emit(_value if (is_color_valid_non_hex(_value)) else "#" + _value)

func get_value() -> String:
	return _value


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		set_value(attribute.get_value())
	color_edit.text = get_value()
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
	color_popup = ColorPopup.instantiate()
	color_popup.current_value = get_value()
	add_child(color_popup)
	color_popup.color_picked.connect(_on_color_picked)
	Utils.popup_under_control(color_popup, color_edit)

func _draw() -> void:
	var button_size := color_button.get_size()
	var line_edit_size := color_edit.get_size()
	draw_set_transform(Vector2(line_edit_size.x, 1))
	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	if Utils.named_colors.has(get_value()):
		stylebox.bg_color = Utils.named_colors[get_value()]
	else:
		stylebox.bg_color = Color.from_string(get_value(), Color(0, 0, 0, 0))
	draw_texture(checkerboard, Vector2.ZERO)
	draw_style_box(stylebox, Rect2(Vector2.ZERO, button_size - Vector2(1, 2)))


func _on_focus_exited() -> void:
	set_value(color_edit.text)

func _on_text_submitted(new_text: String) -> void:
	set_value(new_text)


func _on_color_picked(new_color: String, close_picker: bool) -> void:
	set_value(new_color)
	if close_picker:
		color_popup.queue_free()

func is_color_valid_non_hex(color: String) -> bool:
	return color == "none" or Utils.named_colors.has(color) or\
	(color.begins_with("url(#") and color.ends_with(")"))

func is_color_valid(color: String) -> bool:
	return color.is_valid_html_color() or is_color_valid_non_hex(color)


func _on_button_resized() -> void:
	# Not sure why this is needed, but the button doesn't have a correct size at first
	# which screws with the drawing logic.
	queue_redraw()


func set_text_tint() -> void:
	if color_edit != null:
		if attribute != null and get_value() == attribute.default.trim_prefix("#"):
			color_edit.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
		else:
			color_edit.remove_theme_color_override(&"font_color")

func _on_line_edit_text_changed(new_text: String) -> void:
	if is_color_valid(new_text):
		color_edit.add_theme_color_override(&"font_color", Color(0.6, 1.0, 0.6))
	else:
		color_edit.add_theme_color_override(&"font_color", Color(1.0, 0.6, 0.6))
