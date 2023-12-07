## A LineEdit with a few tweaks to make it nicer to use.
class_name BetterLineEdit extends LineEdit

const code_font = preload("res://visual/fonts/FontMono.ttf")
const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")

var hovered := false

@export var hover_stylebox: StyleBox  ## Overlayed on top when you hover the LineEdit.
@export var focus_stylebox: StyleBox  ## Overlayed on top when the LineEdit is focused.
@export var code_font_tooltip := false  ## Use the mono font for the tooltip.

func _ready() -> void:
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	text_submitted.connect(release_focus.unbind(1))
	gui_input.connect(_on_gui_input)

func _input(event: InputEvent) -> void:
	if has_focus() and event is InputEventMouseButton and\
	not get_global_rect().has_point(event.position):
		release_focus()

var tree_was_paused_before := false
func _on_focus_entered() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	tree_was_paused_before = get_tree().paused
	if not tree_was_paused_before:
		get_tree().paused = true

func _on_focus_exited() -> void:
	process_mode = PROCESS_MODE_INHERIT
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
			var context_popup := ContextPopup.instantiate()
			var btn_arr: Array[Button] = []
			
			var undo_button := Button.new()
			undo_button.text = tr(&"#undo")
			undo_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			undo_button.pressed.connect(menu_option.bind(LineEdit.MENU_UNDO))
			btn_arr.append(undo_button)
			
			var redo_button := Button.new()
			redo_button.text = tr(&"#redo")
			redo_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			redo_button.pressed.connect(menu_option.bind(LineEdit.MENU_REDO))
			btn_arr.append(redo_button)
			
			var copy_button := Button.new()
			copy_button.text = tr(&"#copy")
			copy_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			copy_button.pressed.connect(menu_option.bind(LineEdit.MENU_COPY))
			btn_arr.append(copy_button)
			
			var paste_button := Button.new()
			paste_button.text = tr(&"#paste")
			if not DisplayServer.clipboard_has():
				paste_button.disabled = true
			paste_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			paste_button.pressed.connect(menu_option.bind(LineEdit.MENU_PASTE))
			btn_arr.append(paste_button)
			
			var cut_button := Button.new()
			cut_button.text = tr(&"#cut")
			cut_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			cut_button.pressed.connect(menu_option.bind(LineEdit.MENU_CUT))
			btn_arr.append(cut_button)
			
			add_child(context_popup)
			context_popup.set_min_width(72.0)
			context_popup.set_btn_array(btn_arr)
			Utils.popup_under_mouse(
					context_popup, get_viewport().get_screen_transform().get_origin() /\
					get_tree().get_root().content_scale_factor + get_global_mouse_position())
