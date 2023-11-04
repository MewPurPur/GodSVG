## A LineEdit with a few tweaks to make it nicer to use.
class_name BetterLineEdit extends LineEdit

const code_font = preload("res://visual/fonts/FontMono.ttf")

var hovered := false

@export var hover_stylebox: StyleBox
@export var focus_stylebox: StyleBox
@export var code_font_tooltip := false

func _ready() -> void:
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	text_submitted.connect(_on_text_submitted)

func _input(event: InputEvent) -> void:
	if has_focus() and event is InputEventMouseButton and\
	not get_global_rect().has_point(event.position):
		release_focus()

func _on_focus_entered() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	get_tree().paused = true

func _on_focus_exited() -> void:
	get_tree().paused = false
	process_mode = PROCESS_MODE_INHERIT

func _on_mouse_entered() -> void:
	hovered = true
	queue_redraw()

func _on_mouse_exited() -> void:
	hovered = false
	queue_redraw()

func _on_text_submitted(_new_text: String) -> void:
	release_focus()

func _draw() -> void:
	if editable:
		if has_focus() and focus_stylebox != null:
			draw_style_box(focus_stylebox, Rect2(Vector2.ZERO, size))
		elif hovered and hover_stylebox != null:
			draw_style_box(hover_stylebox, Rect2(Vector2.ZERO, size))

func _make_custom_tooltip(for_text: String) -> Object:
	if code_font_tooltip:
		var label := Label.new()
		label.add_theme_font_override(&"font", code_font)
		label.add_theme_font_size_override(&"font_size", 12)
		label.text = for_text
		return label
	else:
		return null
