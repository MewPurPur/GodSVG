# An editor for flags with the value of 0 or 1, not tied to an attribute.
extends Button

var ci := get_canvas_item()

var hovered := false

signal value_changed(new_value: int)
var _value: int

func set_value(new_value: int, emit_value_changed := true) -> void:
	if _value != new_value:
		_value = new_value
		if emit_value_changed:
			value_changed.emit(new_value)

func get_value() -> int:
	return _value


func _on_toggled(is_state_pressed: bool) -> void:
	set_value(1 if is_state_pressed else 0)

func _ready() -> void:
	toggled.connect(_on_toggled)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	value_changed.connect(_on_value_changed)
	_on_value_changed(get_value())

func _on_value_changed(new_value: int) -> void:
	button_pressed = (new_value == 1)


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
		hover_stylebox.corner_radius_top_left = 3
		hover_stylebox.corner_radius_top_right = 3
		hover_stylebox.border_width_bottom = 2
		hover_stylebox.border_color = Color(1, 1, 1, 0.2)
		hover_stylebox.draw(ci, Rect2(Vector2.ZERO, size))
		if button_pressed:
			ThemeUtils.mono_font.draw_char(ci, Vector2(5, 14), ord("1"), 14, get_theme_color("font_hover_pressed_color"))
		else:
			ThemeUtils.mono_font.draw_char(ci, Vector2(5, 14), ord("0"), 14, get_theme_color("font_hover_color"))
	else:
		if button_pressed:
			ThemeUtils.mono_font.draw_char(ci, Vector2(5, 14), ord("1"), 14, get_theme_color("font_pressed_color"))
		else:
			ThemeUtils.mono_font.draw_char(ci, Vector2(5, 14), ord("0"), 14, get_theme_color("font_color"))


func _make_custom_tooltip(for_text: String) -> Object:
	var label := Label.new()
	label.add_theme_font_override("font", ThemeUtils.mono_font)
	label.text = for_text
	return label
