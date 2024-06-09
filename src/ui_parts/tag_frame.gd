extends VBoxContainer

const code_font = preload("res://visual/fonts/FontMono.ttf")
const warning_icon = preload("res://visual/icons/TagWarning.svg")

# FIXME this seems like a not us issue.
static var TagFrame: PackedScene:
	get:
		if !is_instance_valid(TagFrame):
			TagFrame = load("res://src/ui_parts/tag_frame.tscn")
		return TagFrame

const UnrecognizedField = preload("res://src/ui_elements/unrecognized_field.tscn")
const ColorField = preload("res://src/ui_elements/color_field.tscn")
const NumberField = preload("res://src/ui_elements/number_field.tscn")
const NumberSlider = preload("res://src/ui_elements/number_field_with_slider.tscn")
const IDField = preload("res://src/ui_elements/id_field.tscn")
const EnumField = preload("res://src/ui_elements/enum_field.tscn")
const TransformField = preload("res://src/ui_elements/transform_field.tscn")

const tag_content_types = {
	"path": preload("res://src/ui_elements/tag_content_path.tscn"),
	"circle": preload("res://src/ui_elements/tag_content_basic_shape.tscn"),
	"ellipse": preload("res://src/ui_elements/tag_content_basic_shape.tscn"),
	"rect": preload("res://src/ui_elements/tag_content_basic_shape.tscn"),
	"line": preload("res://src/ui_elements/tag_content_basic_shape.tscn"),
	"stop": preload("res://src/ui_elements/tag_content_stop.tscn"),
	"g": preload("res://src/ui_elements/tag_content_g.tscn"),
	"linearGradient": preload("res://src/ui_elements/tag_content_linear_gradient.tscn"),
	"radialGradient": preload("res://src/ui_elements/tag_content_radial_gradient.tscn"),
}
const TagContentUnrecognized = preload("res://src/ui_elements/tag_content_unrecognized.tscn")

@onready var main_container: VBoxContainer = $Content/MainContainer
@onready var title_bar: Panel = $TitleBar
var child_tags_container: VBoxContainer  # Only created if there are child tags.
@onready var content: PanelContainer = $Content

var tag: Tag

var surface := RenderingServer.canvas_item_create()  # Used for the drop indicator.
@onready var title_bar_ci := title_bar.get_canvas_item()

func _ready() -> void:
	RenderingServer.canvas_item_set_parent(surface, get_canvas_item())
	RenderingServer.canvas_item_set_z_index(surface, 1)
	Indications.selection_changed.connect(determine_selection_highlight)
	Indications.hover_changed.connect(determine_selection_highlight)
	Indications.proposed_drop_changed.connect(queue_redraw)
	determine_selection_highlight()
	title_bar.queue_redraw()
	
	# If there are unrecognized attributes, they would always be on top.
	var has_unrecognized_attributes := false
	var unknown_container: HFlowContainer
	for attribute in tag.attributes.values():
		if not DB.is_attribute_recognized(tag.name, attribute.name):
			if not has_unrecognized_attributes:
				has_unrecognized_attributes = true
				unknown_container = HFlowContainer.new()
				main_container.add_child(unknown_container)
				main_container.move_child(unknown_container, 0)
			
			var input_field: Control
			match DB.get_attribute_type(attribute.name):
				DB.AttributeType.COLOR: input_field = ColorField.instantiate()
				DB.AttributeType.ENUM: input_field = EnumField.instantiate()
				DB.AttributeType.TRANSFORM_LIST: input_field = TransformField.instantiate()
				DB.AttributeType.ID: input_field = IDField.instantiate()
				DB.AttributeType.NUMERIC:
					var min_value: float = DB.attribute_numeric_bounds[attribute.name].x
					var max_value: float = DB.attribute_numeric_bounds[attribute.name].y
					if is_inf(max_value):
						input_field = NumberField.instantiate()
						if not is_inf(min_value):
							input_field.allow_lower = false
							input_field.min_value = min_value
					else:
						input_field = NumberSlider.instantiate()
						input_field.allow_lower = false
						input_field.allow_higher = false
						input_field.min_value = min_value
						input_field.max_value = max_value
						input_field.slider_step = 0.01
				_: input_field = UnrecognizedField.instantiate()
			input_field.tag = tag
			input_field.attribute_name = attribute.name
			unknown_container.add_child(input_field)
	
	var tag_content: Control
	if tag.name in tag_content_types:
		tag_content = tag_content_types[tag.name].instantiate()
	else:
		tag_content = TagContentUnrecognized.instantiate()
	tag_content.tag = tag
	main_container.add_child(tag_content)
	
	if not tag.is_standalone():
		child_tags_container = VBoxContainer.new()
		child_tags_container.mouse_filter = Control.MOUSE_FILTER_STOP
		main_container.add_child(child_tags_container)
		for tag_idx in tag.get_child_count():
			var child_tag := tag.child_tags[tag_idx]
			var tag_editor := TagFrame.instantiate()
			tag_editor.tag = child_tag
			child_tags_container.add_child(tag_editor)

func _exit_tree() -> void:
	RenderingServer.free_rid(surface)

# Logic for dragging.
func _get_drag_data(_at_position: Vector2) -> Variant:
	var data: Array[PackedInt32Array] = Utils.filter_descendant_xids(
			Indications.selected_xids.duplicate(true))
	# Set up a preview.
	var tags_container := VBoxContainer.new()
	for data_idx in range(data.size() - 1, -1, -1):
		var drag_xid := data[data_idx]
		var preview := TagFrame.instantiate()
		preview.tag = SVG.root_tag.get_tag(drag_xid)
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
	Indications.normal_select(tag.xid)
	var viewport := get_viewport()
	var rect := title_bar.get_global_rect()
	HandlerGUI.popup_under_rect_center(Indications.get_selection_context(
			HandlerGUI.popup_under_rect_center.bind(rect, viewport),
			Indications.Context.TAG_EDITOR), rect, viewport)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == 0:
		if Indications.semi_hovered_xid != tag.xid and\
		not Utils.is_xid_parent(tag.xid, Indications.hovered_xid):
			Indications.set_hovered(tag.xid)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if event.shift_pressed:
					Indications.shift_select(tag.xid)
				elif event.is_command_or_control_pressed():
					Indications.ctrl_select(tag.xid)
				elif not tag.xid in Indications.selected_xids:
					Indications.normal_select(tag.xid)
			elif event.is_released() and not event.shift_pressed and\
			not event.is_command_or_control_pressed() and\
			Indications.selected_xids.size() > 1 and tag.xid in Indications.selected_xids:
				Indications.normal_select(tag.xid)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if not tag.xid in Indications.selected_xids:
				Indications.normal_select(tag.xid)
			var viewport := get_viewport()
			var popup_pos := viewport.get_mouse_position()
			HandlerGUI.popup_under_pos(Indications.get_selection_context(
					HandlerGUI.popup_under_pos.bind(popup_pos, viewport),
					Indications.Context.TAG_EDITOR), popup_pos, viewport)
			accept_event()

func _on_mouse_entered() -> void:
	var tag_icon_size := DB.get_tag_icon(tag.name).get_size()
	var half_bar_width := title_bar.size.x / 2
	var title_width := code_font.get_string_size(tag.name,
			HORIZONTAL_ALIGNMENT_LEFT, 180, 12).x
	# Add button.
	var title_button := Button.new()
	title_button.focus_mode = Control.FOCUS_NONE
	title_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	title_button.mouse_filter = Control.MOUSE_FILTER_PASS
	title_button.theme_type_variation = "FlatButton"
	title_button.position = title_bar.position +\
			Vector2(half_bar_width - title_width / 2 - tag_icon_size.x / 2 - 6, 3)
	title_button.size = Vector2(title_width + 28, 20)
	title_bar.add_child(title_button)
	title_button.gui_input.connect(_on_title_button_gui_input.bind(title_button))
	title_button.pressed.connect(_on_title_button_pressed)
	mouse_exited.connect(title_button.queue_free)
	# Add warning button.
	var tag_warnings := tag.get_config_warnings()
	if not tag_warnings.is_empty():
		var warning_sign := TextureRect.new()
		warning_sign.tooltip_text = "\n".join(tag_warnings)
		warning_sign.texture = warning_icon
		warning_sign.size = Vector2(warning_icon.get_size())
		warning_sign.position = title_bar.position + Vector2(title_bar.size.x - 23, 4)
		title_bar.add_child(warning_sign)
		mouse_exited.connect(warning_sign.queue_free)

func _on_mouse_exited() -> void:
	Indications.remove_hovered(tag.xid)
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
	
	var is_selected := tag.xid in Indications.selected_xids
	var is_hovered := Indications.hovered_xid == tag.xid
	
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
	
	var depth := tag.xid.size() - 1
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
		if Utils.is_xid_parent_or_self(selected_xid, tag.xid):
			return
	
	var parent_xid := Utils.get_parent_xid(tag.xid)
	# Draw the yellow indicator of drag and drop actions.
	var drop_sb := StyleBoxFlat.new()
	var proposed_drop_xid := Indications.proposed_drop_xid
	drop_sb.border_color = Color.GREEN
	if proposed_drop_xid == parent_xid + PackedInt32Array([tag.xid[-1]]):
		drop_sb.border_width_top = 2
	elif proposed_drop_xid == parent_xid + PackedInt32Array([tag.xid[-1] + 1]):
		drop_sb.border_width_bottom = 2
	elif proposed_drop_xid == tag.xid + PackedInt32Array([0]):
		drop_sb.set_border_width_all(2)
		if is_instance_valid(child_tags_container):
			drop_sb.border_color = Color(Color.GREEN, 0.4)
	else:
		return
	
	drop_sb.draw_center = false
	drop_sb.set_corner_radius_all(4)
	drop_sb.draw(surface, Rect2(Vector2.ZERO, get_size()))

func _on_title_bar_draw() -> void:
	var tag_icon := DB.get_tag_icon(tag.name)
	var tag_icon_size: Vector2 = tag_icon.get_size()
	var half_bar_width := title_bar.size.x / 2
	var title_width := code_font.get_string_size(tag.name,
			HORIZONTAL_ALIGNMENT_LEFT, 180, 12).x
	code_font.draw_string(title_bar_ci, Vector2(half_bar_width - title_width / 2 +\
			tag_icon_size.x / 2, 18),
			tag.name, HORIZONTAL_ALIGNMENT_LEFT, 180, 12)
	tag_icon.draw_rect(title_bar_ci, Rect2(Vector2(half_bar_width - title_width / 2 -\
			tag_icon_size.x + 6, 4).round(), tag_icon_size), false)
	
	var tag_warnings := tag.get_config_warnings()
	if not tag_warnings.is_empty():
		warning_icon.draw_rect(title_bar_ci, Rect2(Vector2(title_bar.size.x - 23, 4),
				warning_icon.get_size()), false)

# Block dragging from starting when pressing the title button.
func _on_title_button_gui_input(event: InputEvent, title_button: Button) -> void:
	title_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
