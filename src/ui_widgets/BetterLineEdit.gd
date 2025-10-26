## A LineEdit with a few tweaks to make it nicer to use.
@icon("res://godot_only/icons/BetterLineEdit.svg")
class_name BetterLineEdit extends LineEdit

## Emitted when Esc is pressed to cancel the current text change.
signal text_change_canceled

## When turned on, uses the mono font for the tooltip.
@export var mono_font_tooltip := false

func _set(property: StringName, value: Variant) -> bool:
	if property == &"editable" and editable != value:
		editable = value
		sync_theming()
		return true
	return false

func _init() -> void:
	# Solves an issue where Ctrl+S would type an "s" and handle the input.
	# We want anything with Ctrl to not be handled, but other keys to still be handled.
	set_process_unhandled_key_input(false)
	
	context_menu_enabled = false
	caret_blink = true
	caret_blink_interval = 0.6
	focus_entered.connect(_on_base_class_focus_entered)
	focus_exited.connect(_on_base_class_focus_exited)
	mouse_exited.connect(queue_redraw)
	text_submitted.connect(release_focus.unbind(1))
	Configs.theme_changed.connect(sync_theming)
	sync_theming()

func sync_theming() -> void:
	add_theme_color_override("selection_color", ThemeDB.get_default_theme().get_color(
			"selection_color" if editable else "disabled_selection_color", "LineEdit"))

var first_click := false
var text_before_focus := ""

func _on_base_class_focus_entered() -> void:
	# Hack to check if focus entered was from a mouse click.
	if get_global_rect().has_point(get_viewport().get_mouse_position()) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		first_click = true
	else:
		select_all()
	text_before_focus = text

func _on_base_class_focus_exited() -> void:
	first_click = false
	deselect()
	if Input.is_action_pressed("ui_cancel"):
		text = text_before_focus
		text_change_canceled.emit()
	elif not Input.is_action_pressed("ui_accept"):
		# If ui_accept is pressed, text_submitted gets emitted anyway.
		text_submitted.emit(text)


func _draw() -> void:
	if editable and get_viewport().gui_get_hovered_control() == self and has_theme_stylebox("hover"):
		draw_style_box(get_theme_stylebox("hover"), Rect2(Vector2.ZERO, size))

func _make_custom_tooltip(for_text: String) -> Object:
	if mono_font_tooltip:
		var label := Label.new()
		label.add_theme_font_override("font", ThemeUtils.mono_font)
		label.text = for_text
		return label
	else:
		return null


func _input(event: InputEvent) -> void:
	if not has_focus():
		return
	
	if event is InputEventMouseButton and (event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]):
		if event.is_pressed() and not get_global_rect().has_point(event.position) and HandlerGUI.is_node_on_top_menu_or_popup(self):
			release_focus()
		elif event.is_released() and first_click and not has_selection():
			first_click = false
			select_all()
	if first_click:
		first_click = false
		select_all()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("evaluate"):
		var numstring_evaluation := NumstringParser.evaluate(get_selected_text() if has_selection() else text)
		if not is_nan(numstring_evaluation):
			if has_selection():
				var selection_start := get_selection_from_column()
				var caret_column_was_at_start := (selection_start == caret_column)
				var result := Utils.num_simple(numstring_evaluation, Utils.MAX_NUMERIC_PRECISION)
				var new_selection_end := selection_start + result.length()
				
				text = text.left(selection_start) + result + text.right(-get_selection_to_column())
				select(selection_start, new_selection_end)
				caret_column = selection_start if caret_column_was_at_start else new_selection_end
			else:
				text = Utils.num_simple(numstring_evaluation, Utils.MAX_NUMERIC_PRECISION)
				caret_column = text.length()
		accept_event()
		return
	
	if event.is_action_pressed("select_all"):
		menu_option(MENU_SELECT_ALL)
		accept_event()
		return
	
	if event.is_action_pressed("ui_cancel"):
		release_focus()
		accept_event()
		return
	
	mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
	
	if event is InputEventMouseMotion and event.button_mask == 0:
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		grab_focus()
		var btn_arr: Array[Button] = []
		var separator_arr := PackedInt32Array()
		
		var is_text_empty := text.is_empty()
		
		if editable:
			var text_to_evaluate := get_selected_text() if has_selection() else text
			var selection_evaluation := NumstringParser.evaluate(text_to_evaluate)
			if not is_nan(selection_evaluation) and Utils.num_simple(selection_evaluation, Utils.MAX_NUMERIC_PRECISION) != text_to_evaluate:
				btn_arr.append(ContextPopup.create_shortcut_button("evaluate"))
			
			if not btn_arr.is_empty():
				separator_arr.append(btn_arr.size())
			
			btn_arr.append(ContextPopup.create_shortcut_button("ui_undo", not has_undo()))
			btn_arr.append(ContextPopup.create_shortcut_button("ui_redo", not has_redo()))
			if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
				separator_arr.append(btn_arr.size())
				btn_arr.append(ContextPopup.create_shortcut_button("ui_cut", is_text_empty))
				btn_arr.append(ContextPopup.create_shortcut_button("ui_copy", is_text_empty))
				btn_arr.append(ContextPopup.create_shortcut_button("ui_paste", not Utils.has_clipboard_web_safe()))
				btn_arr.append(ContextPopup.create_shortcut_button("select_all", is_text_empty))
		else:
			btn_arr.append(ContextPopup.create_shortcut_button("ui_copy", is_text_empty))
			btn_arr.append(ContextPopup.create_shortcut_button("select_all", is_text_empty))
		
		var vp := get_viewport()
		var context_popup := ContextPopup.new()
		context_popup.setup(btn_arr, true, -1, separator_arr)
		HandlerGUI.popup_under_pos(context_popup, vp.get_mouse_position(), vp)
		accept_event()
		# Wow, no way to find out the column of a given click? Okay...
		# TODO Make it so LineEdit caret automatically moves to the clicked position
		# to finish the right-click logic.
