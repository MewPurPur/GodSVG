@icon("res://godot_only/icons/BetterLineEdit.svg")
class_name BetterLineEdit extends LineEdit
## A LineEdit with a few tweaks to make it nicer to use.

## Emitted when Esc is pressed to cancel the current text change.
signal text_change_canceled

var _hovered := false

## When turned on, uses the mono font for the tooltip.
@export var mono_font_tooltip := false

func _set(property: StringName, value: Variant) -> bool:
	if property == &"editable" and editable != value:
		editable = value
		update_theme()
		return true
	return false

func _init() -> void:
	context_menu_enabled = false
	caret_blink = true
	caret_blink_interval = 0.6
	focus_entered.connect(_on_base_class_focus_entered)
	focus_exited.connect(_on_base_class_focus_exited)
	mouse_exited.connect(_on_base_class_mouse_exited)
	text_submitted.connect(release_focus.unbind(1))
	GlobalSettings.theme_changed.connect(update_theme)

func update_theme() -> void:
	if editable:
		remove_theme_color_override("selection_color")
	else:
		add_theme_color_override("selection_color",
				get_theme_color("disabled_selection_color"))

var first_click := false
var text_before_focus := ""
var popup_level := -1  # Set when focused, as it can't be focused unless it's top level.

func _on_base_class_focus_entered() -> void:
	# Hack to check if focus entered was from a mouse click.
	if get_global_rect().has_point(get_viewport().get_mouse_position()) and\
	Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		first_click = true
	else:
		select_all()
	text_before_focus = text
	popup_level = HandlerGUI.popup_overlay_stack.size()

func _on_base_class_focus_exited() -> void:
	first_click = false
	if Input.is_action_pressed("ui_cancel"):
		text = text_before_focus
		text_change_canceled.emit()
	elif not Input.is_action_pressed("ui_accept"):
		# If ui_accept is pressed, text_submitted gets emitted anyway.
		text_submitted.emit(text)

func _on_base_class_mouse_exited() -> void:
	_hovered = false
	queue_redraw()


func _draw() -> void:
	if editable and _hovered and has_theme_stylebox("hover"):
		draw_style_box(get_theme_stylebox("hover"), Rect2(Vector2.ZERO, size))

func _make_custom_tooltip(for_text: String) -> Object:
	if mono_font_tooltip:
		var label := Label.new()
		label.begin_bulk_theme_override()
		label.add_theme_font_override("font", ThemeUtils.mono_font)
		label.add_theme_font_size_override("font_size", 13)
		label.end_bulk_theme_override()
		label.text = for_text
		return label
	else:
		return null


func _input(event: InputEvent) -> void:
	if not has_focus():
		return
	
	if event is InputEventMouseButton:
		if event.is_pressed() and not get_global_rect().has_point(event.position) and\
		popup_level == HandlerGUI.popup_overlay_stack.size():
			release_focus()
			accept_event()
		elif event.is_released() and first_click and not has_selection():
			first_click = false
			select_all()
	if first_click:
		first_click = false
		select_all()

func _gui_input(event: InputEvent) -> void:
	mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
	
	if event is InputEventMouseMotion and event.button_mask == 0:
		_hovered = true
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and\
	event.is_pressed():
		grab_focus()
		var btn_arr: Array[Button] = []
		var separator_arr: Array[int] = []
		if editable:
			btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Undo"),
					menu_option.bind(LineEdit.MENU_UNDO), false,
					load("res://visual/icons/Undo.svg"), "ui_undo"))
			btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Redo"),
					menu_option.bind(LineEdit.MENU_REDO), false,
					load("res://visual/icons/Redo.svg"), "ui_redo"))
			if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
				separator_arr = [2]
				btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Cut"),
						menu_option.bind(LineEdit.MENU_CUT), text.is_empty(),
						load("res://visual/icons/Cut.svg"), "ui_cut"))
				btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Copy"),
						menu_option.bind(LineEdit.MENU_COPY), text.is_empty(),
						load("res://visual/icons/Copy.svg"), "ui_copy"))
				btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Paste"),
						menu_option.bind(LineEdit.MENU_PASTE), !DisplayServer.clipboard_has(),
						load("res://visual/icons/Paste.svg"), "ui_paste"))
		else:
			btn_arr.append(ContextPopup.create_button( TranslationServer.translate("Copy"),
					menu_option.bind(LineEdit.MENU_COPY), text.is_empty(),
					load("res://visual/icons/Copy.svg"), "ui_copy"))
		
		var vp := get_viewport()
		var context_popup := ContextPopup.new()
		context_popup.setup(btn_arr, true, -1, separator_arr)
		HandlerGUI.popup_under_pos(context_popup, vp.get_mouse_position(), vp)
		accept_event()
		# Wow, no way to find out the column of a given click? Okay...
		# TODO Make it so LineEdit caret automatically moves to the clicked position
		# to finish the right-click logic.
