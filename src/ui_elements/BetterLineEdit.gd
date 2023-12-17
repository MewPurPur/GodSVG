## A LineEdit with a few tweaks to make it nicer to use.
class_name BetterLineEdit extends LineEdit

const code_font = preload("res://visual/fonts/FontMono.ttf")
const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")

var hovered := false

@export var hover_stylebox: StyleBox  ## Overlayed on top when you hover the LineEdit.
@export var focus_stylebox: StyleBox  ## Overlayed on top when the LineEdit is focused.
@export var code_font_tooltip := false  ## Use the mono font for the tooltip.

func _init() -> void:
	context_menu_enabled = false
	caret_blink = true
	caret_blink_interval = 0.6

func _ready() -> void:
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	text_submitted.connect(release_focus.unbind(1))
	gui_input.connect(_on_gui_input)

func _input(event: InputEvent) -> void:
	if has_focus() and event is InputEventMouseButton:
		if event.is_pressed() and not get_global_rect().has_point(event.position):
			release_focus()
		elif event.is_released() and first_click and not has_selection():
			select_all()

var tree_was_paused_before := false
var first_click := false

func _on_focus_entered() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	tree_was_paused_before = get_tree().paused
	first_click = true
	if not tree_was_paused_before:
		get_tree().paused = true

func _on_focus_exited() -> void:
	process_mode = PROCESS_MODE_INHERIT
	first_click = false
	if not tree_was_paused_before:
		get_tree().paused = false

func _on_mouse_entered() -> void:
	hovered = true
	queue_redraw()

func _on_mouse_exited() -> void:
	hovered = false
	queue_redraw()

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
		label.add_theme_font_size_override(&"font_size", 13)
		label.text = for_text
		return label
	else:
		return null


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			grab_focus()
			var context_popup := ContextPopup.instantiate()
			var btn_arr: Array[Button] = [
				Utils.create_btn(tr(&"#undo"), menu_option.bind(LineEdit.MENU_UNDO)),
				Utils.create_btn(tr(&"#redo"), menu_option.bind(LineEdit.MENU_REDO)),
				Utils.create_btn(tr(&"#copy"), menu_option.bind(LineEdit.MENU_COPY),
						text.is_empty()),
				Utils.create_btn(tr(&"#paste"), menu_option.bind(LineEdit.MENU_PASTE),
						!DisplayServer.clipboard_has()),
				Utils.create_btn(tr(&"#cut"), menu_option.bind(LineEdit.MENU_CUT),
						text.is_empty()),
			]
			
			add_child(context_popup)
			context_popup.set_button_array(btn_arr, true, 72)
			Utils.popup_under_mouse(
					context_popup, get_viewport().get_screen_transform().get_origin() /\
					get_tree().get_root().content_scale_factor + get_global_mouse_position())
			accept_event()
