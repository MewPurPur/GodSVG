extends Control

# Autoscroll area on drag and drop. As a factor from edge to center.
const autoscroll_frac = 0.35  # 35% of the screen will be taken by the autoscroll areas.
const autoscroll_speed = 1500.0

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var xnodes: VBoxContainer = %RootChildren
@onready var covering_rect: Control = $MoveToOverlay

func _ready():
	State.requested_scroll_to_element_editor.connect(scroll_to_view_element_editor)

func _process(delta: float) -> void:
	if State.proposed_drop_xid.is_empty():
		return
	
	# Autoscroll when the dragged object is near the edge of the screen.
	var full_area := scroll_container.get_global_rect()
	var mouse_y := get_global_mouse_position().y
	var center_y := full_area.get_center().y
	# A factor in the range [-1, 1] for how far away the mouse is from the center.
	var factor := (mouse_y - center_y) / (full_area.size.y / 2)
	# Remap values from [0, 1] to [1 - autoscroll_area, 1].
	var scroll_amount := maxf((absf(factor) - 1 + autoscroll_frac) / autoscroll_frac, 0)
	# Increase autoscroll speed the closer to the edge of the container.
	var scroll_value := int(delta * signf(factor) * scroll_amount * autoscroll_speed)
	# Check if autoscrolling happened; if it did, the drop location may need updating.
	var old_scroll_vertical := scroll_container.scroll_vertical
	scroll_container.scroll_vertical += scroll_value
	if scroll_container.scroll_vertical != old_scroll_vertical:
		update_proposed_xid()

func update_proposed_xid() -> void:
	var y_pos := get_local_mouse_position().y + scroll_container.scroll_vertical
	var in_top_buffer := false
	var in_bottom_buffer := false
	# Keep track of the last element editor whose position is before y_pos.
	var prev_xid := PackedInt32Array([-1])
	var prev_y := -INF
	# Keep track of the first element editor whose end is after y_pos.
	var next_xid := PackedInt32Array([State.root_element.get_child_count()])
	var next_y := INF
	
	for xnode in State.root_element.get_all_xnode_descendants():
		var xnode_rect := get_xnode_editor_rect(xnode.xid)
		var xnode_start := xnode_rect.position.y
		var xnode_end := xnode_rect.end.y
		var buffer := minf(xnode_rect.size.y / 3, 26) if xnode.is_element() else\
				xnode_rect.size.y / 2 + 1
		if y_pos < xnode_end and xnode_end < next_y:
			next_y = xnode_end
			next_xid = xnode.xid
			if y_pos > xnode_end - buffer:
				in_bottom_buffer = true
		if y_pos > xnode_start and xnode_start > prev_y:
			prev_y = xnode_start
			prev_xid = xnode.xid
			if y_pos < xnode_start + buffer:
				in_top_buffer = true
	# Set the proposed drop XID based on what the previous and next element editors are.
	if in_top_buffer:
		State.set_proposed_drop_xid(prev_xid)
	elif in_bottom_buffer:
		State.set_proposed_drop_xid(XIDUtils.get_parent_xid(next_xid) +\
				PackedInt32Array([next_xid[-1] + 1]))
	elif next_xid[0] >= State.root_element.get_child_count():
		State.set_proposed_drop_xid(next_xid)
	elif XIDUtils.is_parent_or_self(prev_xid, next_xid):
		for i in range(prev_xid.size(), next_xid.size()):
			if next_xid[i] != 0:
				return
		State.set_proposed_drop_xid(prev_xid + PackedInt32Array([0]))


var dragged_xnode_editors: Array[Control] = []

func _notification(what: int) -> void:
	if is_inside_tree() and HandlerGUI.menu_stack.is_empty():
		if what == NOTIFICATION_DRAG_BEGIN:
			covering_rect.show()
			for selected_xid in State.selected_xids:
				var xnode_editor := get_xnode_editor(selected_xid)
				dragged_xnode_editors.append(xnode_editor)
				xnode_editor.modulate.a = 0.55
			update_proposed_xid()
		elif what == NOTIFICATION_DRAG_END:
			covering_rect.hide()
			for xnode_editor in dragged_xnode_editors:
				xnode_editor.modulate.a = 1.0
			dragged_xnode_editors.clear()
			State.clear_proposed_drop_xid()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and\
		not (event.ctrl_pressed or event.shift_pressed):
			State.clear_all_selections()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			# Find where the new element should be added.
			var location := 0
			var y_pos := get_local_mouse_position().y + scroll_container.scroll_vertical
			while location < State.root_element.get_child_count() and\
			get_xnode_editor_rect(PackedInt32Array([location])).end.y < y_pos:
				location += 1
			# Create the context popup.
			var btn_array: Array[Button] = []
			for element_name in ["path", "circle", "ellipse", "rect", "line", "polygon",
			"polyline", "g", "linearGradient", "radialGradient", "stop"]:
				var btn := ContextPopup.create_button(element_name,
						add_element.bind(element_name, location), false,
						DB.get_element_icon(element_name))
				btn.add_theme_font_override("font", ThemeUtils.mono_font)
				btn_array.append(btn)
			
			var separation_indices := PackedInt32Array([1, 4, 7])
			
			var add_popup := ContextPopup.new()
			add_popup.setup_with_title(btn_array, Translator.translate("New element"),
					true, -1, -1, separation_indices)
			var vp := get_viewport()
			HandlerGUI.popup_under_pos(add_popup, vp.get_mouse_position(), vp)

func add_element(element_name: String, element_idx: int) -> void:
	State.root_element.add_xnode(DB.element_with_setup(element_name, []),
			PackedInt32Array([element_idx]))
	State.queue_svg_save()

func get_xnode_editor(xid: PackedInt32Array) -> Control:
	if xid.is_empty():
		return null
	
	var xnode_editor: Control = xnodes.get_child(xid[0])
	for i in range(1, xid.size()):
		xnode_editor = xnode_editor.child_xnodes_container.get_child(xid[i])
	return xnode_editor

func get_xnode_editor_rect(xid: PackedInt32Array, inner_index := -1) -> Rect2:
	var xnode_editor := get_xnode_editor(xid)
	if not is_instance_valid(xnode_editor):
		return Rect2()
	
	# Position relative to the element container.
	var xid_position := Vector2(xnode_editor.global_position -\
			scroll_container.global_position) + Vector2(0, scroll_container.scroll_vertical)
	
	if inner_index == -1:
		return Rect2(xid_position, xnode_editor.size)
	else:
		var inner_rect: Rect2 = xnode_editor.get_inner_rect(inner_index) if\
				State.root_element.get_xnode(xid).is_element() else Rect2()
		return Rect2(xid_position + inner_rect.position, inner_rect.size)

# This function assumes there exists a element editor for the corresponding XID.
func scroll_to_view_element_editor(xid: PackedInt32Array, inner_idx := -1) -> void:
	scroll_container.get_v_scroll_bar().value =\
			get_xnode_editor_rect(xid, inner_idx).position.y - scroll_container.size.y / 5
