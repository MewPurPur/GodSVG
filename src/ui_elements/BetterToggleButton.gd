## A regular Button that overlays a stylebox when hovered while pressed.
class_name BetterToggleButton extends Button

var hovered := false

## Overlayed on top when the Button is hovered while pressed.
@export var hover_pressed_stylebox: StyleBox

@export var font_hover_pressed_color: Color

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	hovered = true
	if not font_hover_pressed_color == Color.BLACK and button_pressed:
		add_theme_color_override("font_pressed_color", font_hover_pressed_color)
	queue_redraw()

func _on_mouse_exited() -> void:
	hovered = false
	remove_theme_color_override("font_pressed_color")
	queue_redraw()

func _draw() -> void:
	if not disabled and button_pressed and hovered and hover_pressed_stylebox != null:
		draw_style_box(hover_pressed_stylebox, Rect2(Vector2.ZERO, size))
