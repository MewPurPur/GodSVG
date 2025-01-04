extends HTitledPanel

@onready var text_edit: BetterTextEdit = $TextEdit
@onready var title_bar: Control = $TitleBar

var xnode: BasicXNode

var surface := RenderingServer.canvas_item_create()  # Used for the drop indicator.
@onready var title_bar_ci := title_bar.get_canvas_item()

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	RenderingServer.canvas_item_set_z_index(surface, 1)
	Indications.selection_changed.connect(determine_selection_highlight)
	Indications.hover_changed.connect(determine_selection_highlight)
	Indications.proposed_drop_changed.connect(queue_redraw)
	title_bar.draw.connect(_on_title_bar_draw)
	mouse_exited.connect(_on_mouse_exited)
	determine_selection_highlight()
	title_bar.queue_redraw()
	text_edit.text_set.connect(_on_text_modified)
	text_edit.text_changed.connect(_on_text_modified)
	text_edit.initialize_text(xnode.get_text())

func _exit_tree() -> void:
	RenderingServer.free_rid(surface)

# Logic for dragging.
func _get_drag_data(_at_position: Vector2) -> Variant:
	if Indications.selected_xids.is_empty():
		return null
	
	var data: Array[PackedInt32Array] = XIDUtils.filter_descendants(
			Indications.selected_xids.duplicate(true))
	set_drag_preview(XNodeChildrenBuilder.generate_drag_preview(data))
	return data

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate = Color(1, 1, 1)


func _on_title_button_pressed() -> void:
	# Update the selection immediately, since if this xnode editor is
	# in a multi-selection, only the mouse button release would change the selection.
	Indications.normal_select(xnode.xid)
	var viewport := get_viewport()
	var rect := title_bar.get_global_rect()
	HandlerGUI.popup_under_rect_center(Indications.get_selection_context(
			HandlerGUI.popup_under_rect_center.bind(rect, viewport),
			Indications.Context.LIST), rect, viewport)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == 0:
		if Indications.semi_hovered_xid != xnode.xid and\
		not XIDUtils.is_parent(xnode.xid, Indications.hovered_xid):
			Indications.set_hovered(xnode.xid)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if event.shift_pressed:
					Indications.shift_select(xnode.xid)
				elif event.is_command_or_control_pressed():
					Indications.ctrl_select(xnode.xid)
				elif not xnode.xid in Indications.selected_xids:
					Indications.normal_select(xnode.xid)
			elif event.is_released() and not event.shift_pressed and\
			not event.is_command_or_control_pressed() and\
			Indications.selected_xids.size() > 1 and xnode.xid in Indications.selected_xids:
				Indications.normal_select(xnode.xid)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if not xnode.xid in Indications.selected_xids:
				Indications.normal_select(xnode.xid)
			var viewport := get_viewport()
			var popup_pos := viewport.get_mouse_position()
			HandlerGUI.popup_under_pos(Indications.get_selection_context(
					HandlerGUI.popup_under_pos.bind(popup_pos, viewport),
					Indications.Context.LIST), popup_pos, viewport)
			accept_event()

func _on_mouse_exited() -> void:
	Indications.remove_hovered(xnode.xid)
	determine_selection_highlight()


func determine_selection_highlight() -> void:
	var is_selected := xnode.xid in Indications.selected_xids
	var is_hovered := Indications.hovered_xid == xnode.xid
	
	if is_selected:
		if is_hovered:
			color = Color.from_hsv(0.625, 0.48, 0.27)
			title_color = Color.from_hsv(0.625, 0.5, 0.38)
		else:
			color = Color.from_hsv(0.625, 0.5, 0.25)
			title_color = Color.from_hsv(0.625, 0.6, 0.35)
		border_color = Color.from_hsv(0.6, 0.75, 0.75)
	elif is_hovered:
		color = Color.from_hsv(0.625, 0.57, 0.19)
		title_color = Color.from_hsv(0.625, 0.4, 0.2)
		border_color = Color.from_hsv(0.6, 0.55, 0.45)
	else:
		color = Color.from_hsv(0.625, 0.6, 0.16)
		title_color = Color.from_hsv(0.625, 0.45, 0.17)
		border_color = Color.from_hsv(0.6, 0.5, 0.35)
	
	var depth := xnode.xid.size() - 1
	var depth_tint := depth * 0.12
	if depth > 0:
		color.h += depth_tint
		border_color.h += depth_tint
		title_color.h += depth_tint
	queue_redraw()

func _draw() -> void:
	RenderingServer.canvas_item_clear(surface)
	
	# There's only stuff to draw if there are drag-and-drop actions.
	if Indications.proposed_drop_xid.is_empty():
		return
	
	for selected_xid in Indications.selected_xids:
		if XIDUtils.is_parent_or_self(selected_xid, xnode.xid):
			return
	
	var parent_xid := XIDUtils.get_parent_xid(xnode.xid)
	# Draw the indicator of drag and drop actions.
	var drop_sb := StyleBoxFlat.new()
	var drop_xid := Indications.proposed_drop_xid
	
	var drop_element := xnode.root.get_xnode(XIDUtils.get_parent_xid(drop_xid))
	var are_all_children_valid := true
	for xid in Indications.selected_xids:
		var selected_xnode := xnode.root.get_xnode(xid)
		if not selected_xnode.is_element():
			continue
		if !DB.is_child_element_valid(drop_element.name, selected_xnode.name):
			are_all_children_valid = false
			break
	
	var drop_border_color := Configs.savedata.get_validity_color(false,
			not are_all_children_valid)
	drop_border_color.s = lerpf(drop_border_color.s, 1.0, 0.5)
	drop_sb.border_color = drop_border_color
	if drop_xid == parent_xid + PackedInt32Array([xnode.xid[-1]]):
		drop_sb.border_width_top = 2
	elif drop_xid == parent_xid + PackedInt32Array([xnode.xid[-1] + 1]):
		drop_sb.border_width_bottom = 2
	else:
		return
	
	drop_sb.draw_center = false
	drop_sb.set_corner_radius_all(4)
	drop_sb.draw(surface, Rect2(Vector2.ZERO, get_size()))

func _on_title_bar_draw() -> void:
	var xnode_icon := DB.get_xnode_icon(xnode.get_type())
	var xnode_icon_size := xnode_icon.get_size()
	xnode_icon.draw_rect(title_bar_ci, Rect2(title_bar.size / 2 - xnode_icon_size / 2,
			xnode_icon_size), false)

func _on_text_modified() -> void:
	# TODO figure out a way to make this work.
	#if text_edit.get_line_count() >= 3 or (text_edit.get_line_count() == 2 and\
	#text_edit.get_line_wrap_count(0) + text_edit.get_line_wrap_count(1) >= 1) or\
	#(text_edit.get_line_count() == 1 and text_edit.get_line_wrap_count(0) >= 2):
		#size.y = 36 + text_edit.get_line_height() * 2
	#elif text_edit.get_line_count() >= 2 or (text_edit.get_line_count() == 1 and\
	#text_edit.get_line_wrap_count(0) >= 1):
		#size.y = 36 + text_edit.get_line_height()
	#else:
		#size.y = 36
	
	if xnode.check_text_validity(text_edit.text):
		xnode.set_text(text_edit.text)
		text_edit.remove_theme_color_override("font_color")
	else:
		text_edit.add_theme_color_override("font_color", Configs.savedata.basic_color_error)
