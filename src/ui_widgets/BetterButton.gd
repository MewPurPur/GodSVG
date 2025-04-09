@icon("res://godot_only/icons/BetterButton.svg")
class_name BetterButton extends Button
## A regular Button with some helpers for hover + press theming situations and shortcuts.

const HIGHLIGHT_TIME = 0.2

var just_pressed := false
var timer: SceneTreeTimer

var _hovered := false

## Overlaid on top when the Button is hovered while pressed.
@export var hover_pressed_stylebox: StyleBox
## Overlaid on top when the Button is hovered while pressed.
@export var hover_pressed_font_color := Color.TRANSPARENT

## A shortcut that corresponds to the same action that this button does.
@export var action := ""


func _ready() -> void:
	if not action.is_empty() and not toggle_mode:
		pressed.connect(_on_pressed)
	
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
	if _hovered and not disabled and button_pressed and\
	is_instance_valid(hover_pressed_stylebox):
		draw_style_box(hover_pressed_stylebox, Rect2(Vector2.ZERO, size))


func _make_custom_tooltip(_for_text: String) -> Object:
	if action.is_empty():
		return null
	
	var action_showcase_text := ShortcutUtils.get_action_showcase_text(action)
	
	var main_label := Label.new()
	main_label.add_theme_font_size_override("font_size",
			get_theme_font_size("font_size", "TooltipLabel"))
	main_label.add_theme_color_override("font_color",
			get_theme_color("font_color", "TooltipLabel"))
	main_label.text = TranslationUtils.get_action_description(action, true)
	
	if action_showcase_text.is_empty():
		return main_label
	
	var shortcut_label := Label.new()
	shortcut_label.add_theme_font_size_override("font_size",
			get_theme_font_size("font_size", "TooltipLabel"))
	shortcut_label.add_theme_color_override("font_color",
			ThemeUtils.common_subtle_text_color)
	shortcut_label.text = "(%s)" % action_showcase_text
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.add_child(main_label)
	hbox.add_child(shortcut_label)
	return hbox

func _on_pressed() -> void:
	just_pressed = true
	set_deferred("just_pressed", false)
	HandlerGUI.throw_action_event(action)

func _unhandled_input(event: InputEvent) -> void:
	if action.is_empty() or toggle_mode:
		return
	
	if not just_pressed and ShortcutUtils.is_action_pressed(event, action) and\
	not is_instance_valid(timer):
		add_theme_color_override("icon_normal_color", get_theme_color("icon_pressed_color"))
		add_theme_color_override("icon_hover_color", get_theme_color("icon_pressed_color"))
		add_theme_stylebox_override("normal", get_theme_stylebox("pressed"))
		timer = get_tree().create_timer(HIGHLIGHT_TIME)
		timer.timeout.connect(end_highlight)

func end_highlight() -> void:
	remove_theme_color_override("icon_normal_color")
	remove_theme_color_override("icon_hover_color")
	remove_theme_stylebox_override("normal")
	timer = null
