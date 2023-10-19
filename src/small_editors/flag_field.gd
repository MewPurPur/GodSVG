extends Button

var hovered := false

signal value_changed(new_value: int)
var _value: int

func set_value(new_value: int, emit_value_changed := true):
	if _value != new_value:
		_value = new_value
		if emit_value_changed:
			value_changed.emit(new_value)

func get_value() -> int:
	return _value


func _on_toggled(is_state_pressed: bool) -> void:
	set_value(1 if is_state_pressed else 0)

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	button_pressed = (get_value() == 1)
	text = str(get_value())

func _on_value_changed(new_value: int) -> void:
	button_pressed = new_value == 1
	text = str(new_value)


func _on_mouse_entered() -> void:
	hovered = true
	queue_redraw()

func _on_mouse_exited() -> void:
	hovered = false
	queue_redraw()

func _draw() -> void:
	if hovered:
		var hover_stylebox := StyleBoxFlat.new()
		hover_stylebox.draw_center = false
		hover_stylebox.set_corner_radius_all(5)
		hover_stylebox.set_border_width_all(2)
		hover_stylebox.border_color = Color(1, 1, 1, 0.15)
		draw_style_box(hover_stylebox, Rect2(Vector2.ZERO, size))
