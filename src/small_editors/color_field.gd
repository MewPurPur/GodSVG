extends AttributeEditor

@onready var color_button: Button = $Button
@onready var color_edit: LineEdit = $LineEdit
@onready var color_picker: Popup = $ColorPopup

@export var checkerboard: Texture2D

signal value_changed(new_value: String)
var value: String:
	set(new_value):
		var old_value := value
		value = validate(new_value)
		if value != old_value:
			value_changed.emit(value if value == "none" else "#" + value)

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		value = attribute.value
	color_edit.text = value
	color_edit.tooltip_text = attribute_name

func validate(new_value: String) -> String:
	if new_value == "none" or new_value.is_valid_html_color():
		return new_value.trim_prefix("#")
	return "000"

func _on_value_changed(new_value: String) -> void:
	color_edit.text = new_value.trim_prefix("#")
	queue_redraw()
	if attribute != null:
		attribute.value = new_value

func _on_button_pressed() -> void:
	color_picker.popup(Utils.calculate_popup_rect(
			color_edit.global_position, color_edit.size, color_picker.size))

func _draw() -> void:
	var button_size := color_button.get_size()
	var line_edit_size := color_edit.get_size()
	draw_set_transform(Vector2(line_edit_size.x, 1))
	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.bg_color = Color.from_string(value, Color(0, 0, 0, 0))
	draw_texture(checkerboard, Vector2.ZERO)
	draw_style_box(stylebox, Rect2(Vector2.ZERO, button_size - Vector2(1, 2)))


# Hacks to make LineEdit bearable.

func _on_focus_entered() -> void:
	get_tree().paused = true

func _on_focus_exited() -> void:
	value = color_edit.text
	get_tree().paused = false

func _on_text_submitted(new_text: String) -> void:
	value = new_text
	color_edit.release_focus()

func _input(event: InputEvent) -> void:
	Utils.defocus_control_on_outside_click(color_edit, event)

func _on_color_picked(new_color: String) -> void:
	value = new_color


func _on_button_resized() -> void:
	# Not sure why this is needed, but the button doesn't have a correct size at first
	# which screws with the drawing logic.
	queue_redraw()
