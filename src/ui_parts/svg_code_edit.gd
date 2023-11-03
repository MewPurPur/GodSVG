# This changes a few things about the SVG TextEdit to make it nicer to use.
extends TextEdit

const code_font = preload("res://visual/fonts/FontMono.ttf")
const caret_color = Color("defd")

var surface := RenderingServer.canvas_item_create()
var timer := Timer.new()

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	add_child(timer)
	timer.timeout.connect(blink)

# I'd prefer to block non-ASCII inputs. SVG syntax is ASCII only, and while
# text blocks and comments allow non-ASCII, they are still difficult to deal with
# because they are two bytes long. <text> tags make the situation a whole lot harder,
# but for now they are not supported. Maybe in some future version I'll have them
# be translated directly into paths or have an abstraction over them, I don't know.
# Either way, not planning to support UTF-8, so I block it if the user tries to type it.
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		# Stuff like Space and Esc have ASCII as their first char so it's fine
		# (Probably? Dealing with is just the worst.)
		if OS.get_keycode_string(event.key_label).unicode_at(0) >= 127 and not\
		event.is_command_or_control_pressed():
			accept_event()


func _on_caret_changed() -> void:
	await get_tree().process_frame  # Buggy with backspace otherwise, likely a Godot bug.
	blonk = false
	blink()
	timer.start(0.6)
	RenderingServer.canvas_item_clear(surface)
	if has_focus():
		var char_size := code_font.get_char_size(69,
				get_theme_font_size(&"TextEdit", &"font_size"))
		for caret in get_caret_count():
			var caret_draw_pos := get_caret_draw_pos(caret)
			if is_overtype_mode_enabled():
				RenderingServer.canvas_item_add_line(surface, caret_draw_pos - Vector2(1, 0),
						caret_draw_pos + Vector2(char_size.x - 2, 0), caret_color, 1)
			else:
				RenderingServer.canvas_item_add_line(surface, caret_draw_pos - Vector2(0, 1),
						caret_draw_pos - Vector2(0, char_size.y - 2), caret_color, 1)


var blonk := true
func blink() -> void:
	blonk = not blonk
	RenderingServer.canvas_item_set_visible(surface, blonk)


func _on_focus_entered() -> void:
	timer.start(0.6)

func _on_focus_exited() -> void:
	timer.stop()
