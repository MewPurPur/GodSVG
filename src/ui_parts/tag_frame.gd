extends VBoxContainer

const code_font = preload("res://visual/fonts/FontMono.ttf")

static var TagFrame: PackedScene:
	get:
		if TagFrame == null:
			TagFrame = load("res://src/ui_parts/tag_frame.tscn")
		return TagFrame

const UnknownField = preload("res://src/ui_elements/unknown_field.tscn")
const TagContentUnknown = preload("res://src/ui_elements/tag_content_unknown.tscn")
const TagContentPath = preload("res://src/ui_elements/tag_content_path.tscn")

@onready var main_container: VBoxContainer = $Content/MainContainer
@onready var title_bar: Panel = $TitleBar
@onready var title_button: Button = $TitleBar/TitleButton
var child_tags_container: VBoxContainer  # Only created if there are child tags.
@onready var content: PanelContainer = $Content

var tid: PackedInt32Array
var tag: Tag

var surface := RenderingServer.canvas_item_create()  # Used for the drop indicator.
@onready var title_bar_ci := title_bar.get_canvas_item()

func _ready() -> void:
	title_bar.custom_minimum_size.y = title_button.size.y + 4
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	RenderingServer.canvas_item_set_z_index(surface, 1)
	Indications.selection_changed.connect(determine_selection_highlight)
	Indications.hover_changed.connect(determine_selection_highlight)
	Indications.proposed_drop_changed.connect(queue_redraw)
	determine_selection_highlight()
	title_bar.queue_redraw()
	
	# If there are unknown attributes, they would always be on top.
	if not tag.unknown_attributes.is_empty():
		var unknown_container := HFlowContainer.new()
		main_container.add_child(unknown_container)
		main_container.move_child(unknown_container, 0)
		for attribute in tag.unknown_attributes:
			var input_field := UnknownField.instantiate()
			input_field.attribute = attribute
			unknown_container.add_child(input_field)
	
	var tag_content: Control
	if tag is TagPath:
		tag_content = TagContentPath.instantiate()
	else:
		tag_content = TagContentUnknown.instantiate()
	tag_content.tag = tag
	tag_content.tid = tid
	main_container.add_child(tag_content)
	
	if not tag.is_standalone():
		child_tags_container = VBoxContainer.new()
		child_tags_container.mouse_filter = Control.MOUSE_FILTER_STOP
		main_container.add_child(child_tags_container)
		for tag_idx in tag.get_child_count():
			var child_tag := tag.child_tags[tag_idx]
			var tag_editor := TagFrame.instantiate()
			tag_editor.tag = child_tag
			var new_tid := tid.duplicate()
			new_tid.append(tag_idx)
			tag_editor.tid = new_tid
			child_tags_container.add_child(tag_editor)


# Logic for dragging.
func _get_drag_data(_at_position: Vector2) -> Variant:
	var data: Array[PackedInt32Array] = Utils.filter_descendant_tids(
			Indications.selected_tids.duplicate(true))
	# Set up a preview.
	var tags_container := VBoxContainer.new()
	for data_idx in range(data.size() - 1, -1, -1):
		var drag_tid := data[data_idx]
		var preview := TagFrame.instantiate()
		preview.tag = SVG.root_tag.get_tag(drag_tid)
		preview.tid = drag_tid
		preview.custom_minimum_size.x = size.x
		preview.z_index = 2
		tags_container.add_child(preview)
	tags_container.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(tags_container)
	modulate = Color(1, 1, 1, 0.55)
	return data

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate = Color(1, 1, 1)


func _on_title_button_pressed() -> void:
	# Update the selection immediately, since if this tag editor is
	# in a multi-selection, only the mouse button release would change the selection.
	Indications.normal_select(tid)
	var viewport := get_viewport()
	var title_button_rect := title_button.get_global_rect()
	HandlerGUI.popup_under_rect_center(Indications.get_selection_context(
			HandlerGUI.popup_under_rect_center.bind(title_button_rect, viewport)),
			title_button_rect, viewport)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == 0:
		if Indications.semi_hovered_tid != tid and\
		not Utils.is_tid_parent(tid, Indications.hovered_tid):
			Indications.set_hovered(tid)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if event.shift_pressed:
					Indications.shift_select(tid)
				elif event.is_command_or_control_pressed():
					Indications.ctrl_select(tid)
				elif not tid in Indications.selected_tids:
					Indications.normal_select(tid)
			elif event.is_released() and not event.shift_pressed and\
			not event.is_command_or_control_pressed() and\
			Indications.selected_tids.size() > 1 and tid in Indications.selected_tids:
				Indications.normal_select(tid)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if not tid in Indications.selected_tids:
				Indications.normal_select(tid)
			var viewport := get_viewport()
			var popup_pos := viewport.get_mouse_position()
			HandlerGUI.popup_under_pos(Indications.get_selection_context(
					HandlerGUI.popup_under_pos.bind(popup_pos, viewport)), popup_pos, viewport)
			accept_event()

func _on_mouse_exited() -> void:
	Indications.remove_hovered(tid)
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
	
	var is_selected := tid in Indications.selected_tids
	var is_hovered := Indications.hovered_tid == tid
	
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
	
	var depth := tid.size() - 1
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
	if Indications.proposed_drop_tid.is_empty():
		return
	
	for selected_tid in Indications.selected_tids:
		if Utils.is_tid_parent_or_self(selected_tid, tid):
			return
	
	var parent_tid := Utils.get_parent_tid(tid)
	# Draw the yellow indicator of drag and drop actions.
	var drop_sb := StyleBoxFlat.new()
	var proposed_drop_tid := Indications.proposed_drop_tid
	drop_sb.border_color = Color.YELLOW
	if proposed_drop_tid == parent_tid + PackedInt32Array([tid[-1]]):
		drop_sb.border_width_top = 2
	elif proposed_drop_tid == parent_tid + PackedInt32Array([tid[-1] + 1]):
		drop_sb.border_width_bottom = 2
	elif proposed_drop_tid == tid + PackedInt32Array([0]):
		drop_sb.set_border_width_all(2)
		if child_tags_container != null:
			drop_sb.border_color = Color(Color.YELLOW, 0.4)
	else:
		return
	
	drop_sb.draw_center = false
	drop_sb.set_corner_radius_all(4)
	drop_sb.draw(surface, Rect2(Vector2.ZERO, get_size()))

func _on_title_bar_draw() -> void:
	# Decorate the title bar.
	var tag_icon_size: Vector2 = tag.icon.get_size()
	var half_bar_width := title_bar.size.x / 2
	var title_width := code_font.get_string_size(tag.name,
			HORIZONTAL_ALIGNMENT_LEFT, 180, 12).x
	code_font.draw_string(title_bar_ci, Vector2(half_bar_width - title_width / 2, 18),
			tag.name, HORIZONTAL_ALIGNMENT_LEFT, 180, 12)
	title_button.position = title_bar.position +\
			Vector2(half_bar_width + title_width / 2 + 3, 4)
	title_button.reset_size()
	tag.icon.draw_rect(title_bar_ci, Rect2(Vector2(half_bar_width - title_width / 2 -\
			tag_icon_size.x - 4, 4).round(), tag_icon_size), false)

# Block dragging from starting when pressing the title button.
func _on_title_button_gui_input(event: InputEvent) -> void:
	title_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
