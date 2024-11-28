extends VBoxContainer

const warning_icon = preload("res://visual/icons/Warning.svg")

const element_content_types = {
	"path": preload("res://src/ui_widgets/element_content_path.tscn"),
	"polygon": preload("res://src/ui_widgets/element_content_polyshape.tscn"),
	"polyline": preload("res://src/ui_widgets/element_content_polyshape.tscn"),
	"circle": preload("res://src/ui_widgets/element_content_basic_shape.tscn"),
	"ellipse": preload("res://src/ui_widgets/element_content_basic_shape.tscn"),
	"rect": preload("res://src/ui_widgets/element_content_basic_shape.tscn"),
	"line": preload("res://src/ui_widgets/element_content_basic_shape.tscn"),
	"stop": preload("res://src/ui_widgets/element_content_stop.tscn"),
	"g": preload("res://src/ui_widgets/element_content_g.tscn"),
	"svg": preload("res://src/ui_widgets/element_content_g.tscn"),
	"linearGradient": preload("res://src/ui_widgets/element_content_linear_gradient.tscn"),
	"radialGradient": preload("res://src/ui_widgets/element_content_radial_gradient.tscn"),
}
const ElementContentUnrecognized = preload("res://src/ui_widgets/element_content_unrecognized.tscn")

@onready var main_container: VBoxContainer = $Content/MainContainer
@onready var title_bar: Panel = $TitleBar
var child_xnodes_container: VBoxContainer  # Only created if there are child xnodes.
@onready var content: PanelContainer = $Content

var element: Element

var surface := RenderingServer.canvas_item_create()  # Used for the drop indicator.
@onready var title_bar_ci := title_bar.get_canvas_item()

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	RenderingServer.canvas_item_set_z_index(surface, 1)
	Indications.selection_changed.connect(determine_selection_highlight)
	Indications.hover_changed.connect(determine_selection_highlight)
	Indications.proposed_drop_changed.connect(queue_redraw)
	title_bar.draw.connect(_on_title_bar_draw)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	element.descendant_attribute_changed.connect(title_bar.queue_redraw.unbind(1))
	element.attribute_changed.connect(title_bar.queue_redraw.unbind(1))
	determine_selection_highlight()
	title_bar.queue_redraw()
	
	# If there are unrecognized attributes, they would always be on top.
	var has_unrecognized_attributes := false
	var unknown_container: HFlowContainer
	for attribute in element.get_all_attributes():
		if DB.is_attribute_recognized(element.name, attribute.name):
			continue
		
		if not has_unrecognized_attributes:
			has_unrecognized_attributes = true
			unknown_container = HFlowContainer.new()
			main_container.add_child(unknown_container)
			main_container.move_child(unknown_container, 0)
		unknown_container.add_child(AttributeFieldBuilder.create(attribute.name, element))
	
	var element_content: Control
	if element.name in element_content_types:
		element_content = element_content_types[element.name].instantiate()
	else:
		element_content = ElementContentUnrecognized.instantiate()
	element_content.element = element
	main_container.add_child(element_content)
	
	if element.has_children():
		child_xnodes_container = VBoxContainer.new()
		child_xnodes_container.mouse_filter = Control.MOUSE_FILTER_STOP
		main_container.add_child(child_xnodes_container)
		for xnode_editor in XNodeChildrenBuilder.create(element):
			child_xnodes_container.add_child(xnode_editor)

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
	# Update the selection immediately, since if this element editor is
	# in a multi-selection, only the mouse button release would change the selection.
	Indications.normal_select(element.xid)
	var viewport := get_viewport()
	var rect := title_bar.get_global_rect()
	HandlerGUI.popup_under_rect_center(Indications.get_selection_context(
			HandlerGUI.popup_under_rect_center.bind(rect, viewport),
			Indications.Context.LIST), rect, viewport)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == 0:
		if Indications.semi_hovered_xid != element.xid and\
		not XIDUtils.is_parent(element.xid, Indications.hovered_xid):
			Indications.set_hovered(element.xid)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if event.shift_pressed:
					Indications.shift_select(element.xid)
				elif event.is_command_or_control_pressed():
					Indications.ctrl_select(element.xid)
				elif not element.xid in Indications.selected_xids:
					Indications.normal_select(element.xid)
			elif event.is_released() and not event.shift_pressed and\
			not event.is_command_or_control_pressed() and\
			Indications.selected_xids.size() > 1 and element.xid in Indications.selected_xids:
				Indications.normal_select(element.xid)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if not element.xid in Indications.selected_xids:
				Indications.normal_select(element.xid)
			var viewport := get_viewport()
			var popup_pos := viewport.get_mouse_position()
			HandlerGUI.popup_under_pos(Indications.get_selection_context(
					HandlerGUI.popup_under_pos.bind(popup_pos, viewport),
					Indications.Context.LIST), popup_pos, viewport)
			accept_event()

func _on_mouse_entered() -> void:
	var element_icon_size := DB.get_element_icon(element.name).get_size()
	var half_bar_width := title_bar.size.x / 2
	var title_width := ThemeUtils.mono_font.get_string_size(element.name,
			HORIZONTAL_ALIGNMENT_LEFT, 180, 12).x
	# Add button.
	var title_button := Button.new()
	title_button.focus_mode = Control.FOCUS_NONE
	title_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	title_button.mouse_filter = Control.MOUSE_FILTER_PASS
	title_button.theme_type_variation = "FlatButton"
	title_button.position = title_bar.position +\
			Vector2(half_bar_width - title_width / 2 - element_icon_size.x / 2 - 6, 3)
	title_button.size = Vector2(title_width + 28, 20)
	title_bar.add_child(title_button)
	title_button.gui_input.connect(_on_title_button_gui_input.bind(title_button))
	title_button.pressed.connect(_on_title_button_pressed)
	mouse_exited.connect(title_button.queue_free)
	# Add warning button.
	var element_warnings := element.get_config_warnings()
	if not element_warnings.is_empty():
		var warning_sign := Control.new()
		warning_sign.mouse_filter = Control.MOUSE_FILTER_PASS
		warning_sign.tooltip_text = "\n".join(element_warnings)
		warning_sign.size = Vector2(warning_icon.get_size()) + Vector2(4, 4)
		warning_sign.position = title_bar.position + Vector2(title_bar.size.x - 25, 2)
		title_bar.add_child(warning_sign)
		mouse_exited.connect(warning_sign.queue_free)

func _on_mouse_exited() -> void:
	Indications.remove_hovered(element.xid)
	determine_selection_highlight()


func determine_selection_highlight() -> void:
	var title_sb := StyleBoxFlat.new()
	title_sb.corner_radius_top_left = 4
	title_sb.corner_radius_top_right = 4
	title_sb.set_border_width_all(2)
	title_sb.set_content_margin_all(4)
	
	var content_sb := StyleBoxFlat.new()
	content_sb.corner_radius_bottom_left = 4
	content_sb.corner_radius_bottom_right = 4
	content_sb.border_width_left = 2
	content_sb.border_width_right = 2
	content_sb.border_width_bottom = 2
	content_sb.content_margin_top = 5
	content_sb.content_margin_left = 7
	content_sb.content_margin_bottom = 7
	content_sb.content_margin_right = 7
	
	var is_selected := element.xid in Indications.selected_xids
	var is_hovered := Indications.hovered_xid == element.xid
	
	if is_selected:
		if is_hovered:
			content_sb.bg_color = Color.from_hsv(0.625, 0.48, 0.27)
			title_sb.bg_color = Color.from_hsv(0.625, 0.5, 0.38)
		else:
			content_sb.bg_color = Color.from_hsv(0.625, 0.5, 0.25)
			title_sb.bg_color = Color.from_hsv(0.625, 0.6, 0.35)
		content_sb.border_color = Color.from_hsv(0.6, 0.75, 0.75)
		title_sb.border_color = Color.from_hsv(0.6, 0.75, 0.75)
	elif is_hovered:
		content_sb.bg_color = Color.from_hsv(0.625, 0.57, 0.19)
		title_sb.bg_color = Color.from_hsv(0.625, 0.4, 0.2)
		content_sb.border_color = Color.from_hsv(0.6, 0.55, 0.45)
		title_sb.border_color = Color.from_hsv(0.6, 0.55, 0.45)
	else:
		content_sb.bg_color = Color.from_hsv(0.625, 0.6, 0.16)
		title_sb.bg_color = Color.from_hsv(0.625, 0.45, 0.17)
		content_sb.border_color = Color.from_hsv(0.6, 0.5, 0.35)
		title_sb.border_color = Color.from_hsv(0.6, 0.5, 0.35)
	
	var depth := element.xid.size() - 1
	var depth_tint := depth * 0.12
	if depth > 0:
		content_sb.bg_color = Color.from_hsv(content_sb.bg_color.h + depth_tint,
				content_sb.bg_color.s, content_sb.bg_color.v)
		content_sb.border_color = Color.from_hsv(content_sb.border_color.h + depth_tint,
				content_sb.border_color.s, content_sb.border_color.v)
		title_sb.bg_color = Color.from_hsv(title_sb.bg_color.h + depth_tint,
				title_sb.bg_color.s, title_sb.bg_color.v)
		title_sb.border_color = Color.from_hsv(title_sb.border_color.h + depth_tint,
				title_sb.border_color.s, title_sb.border_color.v)
	content.add_theme_stylebox_override("panel", content_sb)
	title_bar.add_theme_stylebox_override("panel", title_sb)

func _draw() -> void:
	RenderingServer.canvas_item_clear(surface)
	
	# There's only stuff to draw if there are drag-and-drop actions.
	if Indications.proposed_drop_xid.is_empty():
		return
	
	for selected_xid in Indications.selected_xids:
		if XIDUtils.is_parent_or_self(selected_xid, element.xid):
			return
	
	var parent_xid := XIDUtils.get_parent_xid(element.xid)
	# Draw the indicator of drag and drop actions.
	var drop_sb := StyleBoxFlat.new()
	var drop_xid := Indications.proposed_drop_xid
	
	var root_element := element.root
	var drop_tag := root_element.get_xnode(XIDUtils.get_parent_xid(drop_xid))
	var are_all_children_valid := true
	for xid in Indications.selected_xids:
		var xnode := root_element.get_xnode(xid)
		if xnode.is_element() and !DB.is_child_element_valid(drop_tag.name, xnode.name):
			are_all_children_valid = false
			break
	
	var drop_border_color := GlobalSettings.get_validity_color(false,
			not are_all_children_valid)
	drop_border_color.s = lerpf(drop_border_color.s, 1.0, 0.5)
	drop_sb.border_color = drop_border_color
	if drop_xid == parent_xid + PackedInt32Array([element.xid[-1]]):
		drop_sb.border_width_top = 2
	elif drop_xid == parent_xid + PackedInt32Array([element.xid[-1] + 1]):
		drop_sb.border_width_bottom = 2
	elif drop_xid == element.xid + PackedInt32Array([0]):
		drop_sb.set_border_width_all(2)
		if is_instance_valid(child_xnodes_container):
			drop_sb.border_color.a *= 0.4
	else:
		return
	
	drop_sb.draw_center = false
	drop_sb.set_corner_radius_all(4)
	drop_sb.draw(surface, Rect2(Vector2.ZERO, get_size()))

func _on_title_bar_draw() -> void:
	var element_icon := DB.get_element_icon(element.name)
	var element_icon_size := element_icon.get_size()
	var half_bar_width := title_bar.size.x / 2
	var half_title_width := ThemeUtils.mono_font.get_string_size(element.name,
			HORIZONTAL_ALIGNMENT_LEFT, 180, 12).x / 2
	ThemeUtils.mono_font.draw_string(title_bar_ci, Vector2(half_bar_width -\
			half_title_width + element_icon_size.x / 2, 18), element.name,
			HORIZONTAL_ALIGNMENT_LEFT, 180, 12)
	element_icon.draw_rect(title_bar_ci, Rect2(Vector2(half_bar_width - half_title_width -\
			element_icon_size.x + 6, 4).round(), element_icon_size), false)
	
	var element_warnings := element.get_config_warnings()
	if not element_warnings.is_empty():
		warning_icon.draw_rect(title_bar_ci, Rect2(Vector2(title_bar.size.x - 23, 4),
				warning_icon.get_size()), false)

# Block dragging from starting when pressing the title button.
func _on_title_button_gui_input(event: InputEvent, title_button: Button) -> void:
	title_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
