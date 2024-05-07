@icon("res://godot_only/icons/BetterLineEdit.svg")
class_name BetterLineEdit extends LineEdit
## A LineEdit with a few tweaks to make it nicer to use.

## Emitted when Esc is pressed to cancel the current text change.
signal text_change_canceled

const code_font = preload("res://visual/fonts/FontMono.ttf")

var _hovered := false

## When turned on, uses the mono font for the tooltip.
@export var code_font_tooltip := false

func _init() -> void:
	context_menu_enabled = false
	caret_blink = true
	caret_blink_interval = 0.6

func _ready() -> void:
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_exited.connect(_on_mouse_exited)
	text_submitted.connect(_on_text_submitted)

func _input(event: InputEvent) -> void:
	if has_focus():
		if event is InputEventMouseButton:
			if event.is_pressed() and not get_global_rect().has_point(event.position):
				release_focus()
				text_submitted.emit(text)
			elif event.is_released() and first_click and not has_selection():
				first_click = false
				select_all()
		elif first_click:
			first_click = false
			select_all()
		elif event.is_action_pressed("ui_focus_next") || event.is_action_pressed("ui_focus_prev"):
			text_submitted.emit(text)

var tree_was_paused_before := false
var first_click := false
var text_before_focus := ""

func _on_focus_entered() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	tree_was_paused_before = get_tree().paused
	first_click = true
	text_before_focus = text
	if not tree_was_paused_before:
		get_tree().paused = true

func _on_focus_exited() -> void:
	process_mode = PROCESS_MODE_INHERIT
	first_click = false
	if not tree_was_paused_before:
		get_tree().paused = false
	if Input.is_action_pressed("ui_cancel"):
		text = text_before_focus
		text_change_canceled.emit()

func _on_text_submitted(_submitted_text) -> void:
	if not Input.is_action_just_pressed("ui_focus_next") and not Input.is_action_just_pressed("ui_focus_prev"):
		release_focus()


func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()

func _draw() -> void:
	if editable and _hovered and has_theme_stylebox("hover"):
		draw_style_box(get_theme_stylebox("hover"), Rect2(Vector2.ZERO, size))

func _make_custom_tooltip(for_text: String) -> Object:
	if code_font_tooltip:
		var label := Label.new()
		label.begin_bulk_theme_override()
		label.add_theme_font_override("font", code_font)
		label.add_theme_font_size_override("font_size", 13)
		label.end_bulk_theme_override()
		label.text = for_text
		return label
	else:
		return null


func _gui_input(event: InputEvent) -> void:
	mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
	
	if event is InputEventMouseMotion and event.button_mask == 0:
		_hovered = true
		queue_redraw()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			grab_focus()
			var btn_arr: Array[Button] = []
			var separator_arr: Array[int] = []
			if editable:
				btn_arr.append(Utils.create_btn(TranslationServer.translate("Undo"),
						menu_option.bind(LineEdit.MENU_UNDO),
						false, load("res://visual/icons/Undo.svg")))
				btn_arr.append(Utils.create_btn(TranslationServer.translate("Redo"),
						menu_option.bind(LineEdit.MENU_REDO),
						false, load("res://visual/icons/Redo.svg")))
				if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
					separator_arr = [2]
					btn_arr.append(Utils.create_btn(TranslationServer.translate("Cut"),
							menu_option.bind(LineEdit.MENU_CUT),
							text.is_empty(), load("res://visual/icons/Cut.svg")))
					btn_arr.append(Utils.create_btn(TranslationServer.translate("Copy"),
							menu_option.bind(LineEdit.MENU_COPY),
							text.is_empty(), load("res://visual/icons/Copy.svg")))
					btn_arr.append(Utils.create_btn(TranslationServer.translate("Paste"),
							menu_option.bind(LineEdit.MENU_PASTE),
							!DisplayServer.clipboard_has(),
							load("res://visual/icons/Paste.svg")))
			else:
				btn_arr.append(Utils.create_btn(TranslationServer.translate("Copy"),
						menu_option.bind(LineEdit.MENU_COPY),
						text.is_empty(), load("res://visual/icons/Copy.svg")))
			
			var vp := get_viewport()
			var context_popup := ContextPopup.new()
			context_popup.setup(btn_arr, true, -1, separator_arr)
			HandlerGUI.popup_under_pos(context_popup, vp.get_mouse_position(), vp)
			accept_event()
			# Wow, no way to find out the column of a given click? Okay...
			# TODO Make it so LineEdit caret automatically moves to the clicked position.
