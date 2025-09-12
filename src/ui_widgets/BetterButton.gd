## A regular Button with some helpers for hover + press theming situations and shortcuts.
@icon("res://godot_only/icons/BetterButton.svg")
class_name BetterButton extends Button

const HIGHLIGHT_TIME = 0.2

var just_pressed := false
var timer: SceneTreeTimer

## A shortcut that corresponds to the same action that this button does.
@export var action := ""
var shortcuts_bind: ShortcutsRegistration:
	set(new_value):
		shortcuts_bind = new_value
		if is_instance_valid(shortcuts_bind):
			shortcuts_bind.activated.connect(_on_shortcut_activated)


func _ready() -> void:
	if not action.is_empty() and not toggle_mode:
		pressed.connect(_on_pressed)


func _make_custom_tooltip(_for_text: String) -> Object:
	if action.is_empty():
		return null
	
	var action_showcase_text := ShortcutUtils.get_action_showcase_text(action)
	
	var main_label := Label.new()
	main_label.add_theme_font_size_override("font_size", get_theme_font_size("font_size", "TooltipLabel"))
	main_label.add_theme_color_override("font_color", get_theme_color("font_color", "TooltipLabel"))
	main_label.text = TranslationUtils.get_action_description(action, true)
	
	if action_showcase_text.is_empty():
		return main_label
	
	var shortcut_label := Label.new()
	shortcut_label.add_theme_font_size_override("font_size", get_theme_font_size("font_size", "TooltipLabel"))
	shortcut_label.add_theme_color_override("font_color", ThemeUtils.subtle_text_color)
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

func _on_shortcut_activated(activated_action: String) -> void:
	if activated_action != action or toggle_mode or just_pressed:
		return
	
	begin_bulk_theme_override()
	add_theme_color_override("icon_normal_color", get_theme_color("icon_pressed_color"))
	add_theme_color_override("icon_hover_color", get_theme_color("icon_pressed_color"))
	add_theme_stylebox_override("normal", get_theme_stylebox("pressed"))
	add_theme_stylebox_override("hover", get_theme_stylebox("hover_pressed"))
	end_bulk_theme_override()
	if is_instance_valid(timer):
		timer.timeout.disconnect(end_highlight)
	timer = get_tree().create_timer(HIGHLIGHT_TIME)
	timer.timeout.connect(end_highlight)

func end_highlight() -> void:
	begin_bulk_theme_override()
	remove_theme_color_override("icon_normal_color")
	remove_theme_color_override("icon_hover_color")
	remove_theme_stylebox_override("normal")
	remove_theme_stylebox_override("hover")
	end_bulk_theme_override()
	timer = null
