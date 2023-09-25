extends AttributeEditor

@onready var color_button: Button = $Button
@onready var color_edit: LineEdit = $LineEdit
@onready var color_picker: Popup = $ColorPopup

signal value_changed(new_value: String)
var value: String:
	set(new_value):
		var old_value := value
		value = validate(new_value, old_value)
		if value != old_value:
			value_changed.emit(new_value)

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		value = attribute.value
	color_edit.text = value
	color_edit.tooltip_text = attribute_name

func validate(new_value: String, old_value: String) -> String:
	if new_value == "none" or (new_value.is_valid_html_color() and\
	not new_value.begins_with("#")):
		return new_value
	else:
		return old_value

func _on_value_changed(new_value: String) -> void:
	color_edit.text = new_value
	queue_redraw()
	if attribute != null:
		attribute.value = new_value

func _on_button_pressed() -> void:
	color_picker.popup(Rect2(color_edit.global_position + Vector2(0, color_edit.size.y),
			color_picker.size))

func _draw() -> void:
	var button_size := color_button.get_size()
	var line_edit_size := color_edit.get_size()
	var col := Color.from_string(value, Color(0, 0, 0, 0))
	draw_rect(Rect2(Vector2(line_edit_size.x, 1), button_size - Vector2(5, 2)), col)
	draw_rect(Rect2(Vector2(line_edit_size.x + button_size.x - 5, 5), Vector2(3, 12)), col)
	draw_circle(Vector2(line_edit_size.x + button_size.x - 8, 7), 6, col)
	draw_circle(Vector2(line_edit_size.x + button_size.x - 8, 15), 6, col)


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
	if (color_edit.has_focus() and event is InputEventMouseButton and\
	not color_edit.get_global_rect().has_point(event.position)):
		color_edit.release_focus()


func _on_text_changed(new_text: String) -> void:
	# TODO
	if new_text == "#":
		color_edit.delete_char_at_caret()

func _on_color_picked(new_color: String) -> void:
	value = new_color
