class_name BetterToggleButton extends Button
## A regular Button that overlays a stylebox when hovered while pressed.

var _hovered := false

# Overlayed on top when the Button is hovered while pressed.
@export var hover_pressed_stylebox: StyleBox
@export var hover_pressed_font_color: Color

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	add_theme_color_override("font_hover_color", get_theme_color(
			"font_hover_color", "Button").blend(hover_pressed_font_color))

func _on_mouse_entered() -> void:
	_hovered = true
	if not disabled and hover_pressed_font_color != Color.BLACK:
		add_theme_color_override("font_pressed_color", get_theme_color(
				"font_pressed_color", "Button").blend(hover_pressed_font_color))
	queue_redraw()

func _on_mouse_exited() -> void:
	_hovered = false
	remove_theme_color_override("font_pressed_color")
	queue_redraw()

func _draw() -> void:
	if not disabled and button_pressed and _hovered and\
	is_instance_valid(hover_pressed_stylebox):
		draw_style_box(hover_pressed_stylebox, Rect2(Vector2.ZERO, size))
