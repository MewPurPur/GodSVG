extends Control

var ci := get_canvas_item()
var element: Element

func _ready() -> void:
	State.selection_changed.connect(queue_redraw)
	State.hover_changed.connect(queue_redraw)
	mouse_exited.connect(State.remove_hovered.bind(element.xid))

func _get_minimum_size() -> Vector2:
	return Vector2(0, 24)

func _draw() -> void:
	var is_selected := State.is_selected(element.xid)
	var is_hovered := State.is_hovered(element.xid)
	if is_selected:
		if is_hovered:
			get_theme_stylebox("hovered_selected", "ItemList").draw(ci, Rect2(Vector2.ZERO, size))
		else:
			get_theme_stylebox("selected", "ItemList").draw(ci, Rect2(Vector2.ZERO, size))
	elif is_hovered:
		get_theme_stylebox("hovered", "ItemList").draw(ci, Rect2(Vector2.ZERO, size))
	DB.get_element_icon(element.name).draw(ci, Vector2(3, 3), ThemeUtils.tinted_contrast_color)
	
	var text_line := TextLine.new()
	text_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_line.width = 180
	text_line.add_string(element.name, ThemeUtils.mono_font, 13)
	var text_color := ThemeUtils.highlighted_text_color if (is_selected and is_hovered) else ThemeUtils.text_color
	text_line.draw(ci, Vector2(24, 3), text_color)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == 0:
		if State.semi_hovered_xid != element.xid:
			State.set_hovered(element.xid)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if event.shift_pressed:
					State.shift_select(element.xid)
				elif event.is_command_or_control_pressed():
					State.ctrl_select(element.xid)
				elif not element.xid in State.selected_xids:
					State.normal_select(element.xid)
			elif event.is_released() and not event.shift_pressed and not event.is_command_or_control_pressed() and\
			State.selected_xids.size() > 1 and element.xid in State.selected_xids:
				State.normal_select(element.xid)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if not element.xid in State.selected_xids:
				State.normal_select(element.xid)
			var viewport := get_viewport()
			var popup_pos := viewport.get_mouse_position()
			HandlerGUI.popup_under_pos(State.get_selection_context(HandlerGUI.popup_under_pos.bind(popup_pos, viewport),
					Utils.LayoutPart.INSPECTOR), popup_pos, viewport)
			accept_event()
