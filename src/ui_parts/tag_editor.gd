extends VBoxContainer

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const TagEditor = preload("tag_editor.tscn")
const TransformField = preload("res://src/ui_elements/transform_field.tscn")
const NumberField = preload("res://src/ui_elements/number_field.tscn")
const NumberSlider = preload("res://src/ui_elements/number_field_with_slider.tscn")
const ColorField = preload("res://src/ui_elements/color_field.tscn")
const PathField = preload("res://src/ui_elements/path_field.tscn")
const EnumField = preload("res://src/ui_elements/enum_field.tscn")
const UnknownField = preload("res://src/ui_elements/unknown_field.tscn")

@onready var v_box_container: VBoxContainer = $Content/MainContainer
@onready var paint_container: FlowContainer = %AttributeContainer/PaintAttributes
@onready var shape_container: FlowContainer = %AttributeContainer/ShapeAttributes
@onready var unknown_container: HFlowContainer = %AttributeContainer/UnknownAttributes
@onready var title_bar: PanelContainer = $Title
@onready var content: PanelContainer = $Content
@onready var title_icon: TextureRect = $Title/TitleBox/TitleIcon
@onready var title_label: Label = $Title/TitleBox/TitleLabel
@onready var title_button: Button = $Title/TitleBox/TitleButton

var tid: PackedInt32Array
var tag: Tag

enum DropState {INSIDE, UP, DOWN, OUTSIDE}
var drop_state := DropState.OUTSIDE:
	set(new_value):
		if drop_state != new_value:
			drop_state = new_value
			queue_redraw()

var surface := RenderingServer.canvas_item_create()  # Used for the drop indicator.

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	RenderingServer.canvas_item_set_z_index(surface, 1)
	title_label.text = tag.name
	Utils.set_max_text_width(title_label, 180.0, 0.0)  # Handle TagUnknown gracefully.
	title_icon.texture = tag.icon
	Indications.selection_changed.connect(determine_selection_highlight)
	Indications.hover_changed.connect(determine_selection_highlight)
	determine_selection_highlight()
	# Fill up the containers. Start with unknown attributes, if there are any.
	if not tag.unknown_attributes.is_empty():
		unknown_container.show()
	for attribute in tag.unknown_attributes:
		var input_field := UnknownField.instantiate()
		input_field.attribute = attribute
		input_field.attribute_name = attribute.name
		unknown_container.add_child(input_field)
	# Continue with supported attributes.
	for attribute_key in tag.attributes:
		var attribute: Attribute = tag.attributes[attribute_key]
		var input_field: Control
		if attribute is AttributeTransform:
			input_field = TransformField.instantiate()
		elif attribute is AttributeNumeric:
			match attribute.mode:
				AttributeNumeric.Mode.FLOAT:
					input_field = NumberField.instantiate()
				AttributeNumeric.Mode.UFLOAT:
					input_field = NumberField.instantiate()
					input_field.allow_lower = false
				AttributeNumeric.Mode.NFLOAT:
					input_field = NumberSlider.instantiate()
					input_field.allow_lower = false
					input_field.allow_higher = false
					input_field.slider_step = 0.01
		elif attribute is AttributeColor:
			input_field = ColorField.instantiate()
		elif attribute is AttributePath:
			input_field = PathField.instantiate()
		elif attribute is AttributeEnum:
			input_field = EnumField.instantiate()
		input_field.attribute = attribute
		input_field.attribute_name = attribute_key
		input_field.focused.connect(Indications.normal_select.bind(tid))
		# Add the attribute to its corresponding container.
		if attribute_key in tag.known_shape_attributes:
			shape_container.add_child(input_field)
		elif attribute_key in tag.known_inheritable_attributes:
			paint_container.add_child(input_field)
	
	if not tag.is_standalone():
		var child_tags_container := VBoxContainer.new()
		v_box_container.add_child(child_tags_container)
		
		for tag_idx in tag.get_child_count():
			var child_tag := tag.child_tags[tag_idx]
			var tag_editor := TagEditor.instantiate()
			tag_editor.tag = child_tag
			var new_tid := tid.duplicate()
			new_tid.append(tag_idx)
			tag_editor.tid = new_tid
			child_tags_container.add_child(tag_editor)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var data: Array[PackedInt32Array] = [tid.duplicate()]
	if tid in Indications.selected_tids:
		data = Indications.selected_tids.duplicate(true)
	data = Utils.filter_descendant_tids(data)
	var tags_container := VBoxContainer.new()
	for drag_tid in data:
		var preview := TagEditor.instantiate()
		preview.tag = SVG.root_tag.get_tag(drag_tid)
		preview.tid = drag_tid
		preview.custom_minimum_size.x = self.size.x
		tags_container.add_child(preview)
	tags_container.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(tags_container)
	return data

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# The data parameter is the TIDs.
	if not data is Array[PackedInt32Array]:
		return false
	for data_tid in data:
		if Utils.is_tid_parent(data_tid, tid) or data_tid == tid:
			return false
	
	var state := calculate_drop_location(get_global_mouse_position())
	if state == DropState.INSIDE:
		var new_tid := tid.duplicate()
		new_tid.append(0)
		if new_tid in data:
			return false
	drop_state = state
	return true

func _drop_data(_at_position: Vector2, current_tid: Variant):
	var state := calculate_drop_location(get_global_mouse_position())
	var new_tid := tid.duplicate()
	match state:
		DropState.INSIDE:
			new_tid.append(0)
		DropState.DOWN:
			new_tid[-1] += 1
	SVG.root_tag.move_tags_to(current_tid, new_tid)


func _on_title_button_pressed() -> void:
	Utils.popup_under_control_centered(Indications.get_selection_context(), title_button)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == 0:
		if Indications.semi_hovered_tid != tid and\
		not Utils.is_tid_parent(tid, Indications.hovered_tid):
			Indications.set_hovered(tid)
	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.shift_pressed:
				Indications.shift_select(tid)
			elif event.ctrl_pressed:
				Indications.ctrl_select(tid)
			elif not tid in Indications.selected_tids:
				Indications.normal_select(tid)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not tid in Indications.selected_tids:
				Indications.normal_select(tid)
			Utils.popup_under_mouse(Indications.get_selection_context(),
					get_global_mouse_position())
	elif event is InputEventMouseButton and event.is_released() and\
	not event.ctrl_pressed and not event.shift_pressed:
		if tid in Indications.selected_tids:
			Indications.normal_select(tid)

func _on_mouse_exited() -> void:
	Indications.remove_hovered(tid)
	drop_state = DropState.OUTSIDE
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
	content.add_theme_stylebox_override(&"panel", content_sb)
	title_bar.add_theme_stylebox_override(&"panel", title_sb)

func _draw() -> void:
	# Draw the yellow indicator of drag and drop actions.
	RenderingServer.canvas_item_clear(surface)
	if drop_state == DropState.OUTSIDE:
		return
	
	var drop_sb := StyleBoxFlat.new()
	drop_sb.border_color = Color.YELLOW
	drop_sb.draw_center = false
	drop_sb.set_corner_radius_all(4)
	match drop_state:
		DropState.INSIDE:
			drop_sb.set_border_width_all(2)
		DropState.UP:
			drop_sb.border_width_top = 2
		DropState.DOWN:
			drop_sb.border_width_bottom = 2
	
	drop_sb.draw(surface, Rect2(Vector2.ZERO, get_size()))


func calculate_drop_location(at_position: Vector2) -> DropState:
	var tag_editor_area := get_global_rect()
	if not tag_editor_area.has_point(at_position):
		return DropState.OUTSIDE
	
	var drop_border := minf(get_size().y / 3, 24)
	tag_editor_area = tag_editor_area.grow_individual(0, -drop_border, 0, -drop_border)
	if tag_editor_area.has_point(at_position):
		return DropState.INSIDE
	if tag_editor_area.position.y > at_position.y:
		return DropState.UP
	else:
		return DropState.DOWN
