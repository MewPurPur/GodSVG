extends VBoxContainer

const geometry_attributes = ["cx", "cy", "x", "y", "r", "rx", "ry", "width", "height",
		"d", "x1", "y1", "x2", "y2"]

const unknown_icon = preload("res://visual/icons/tag/unknown.svg")

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const TagEditor = preload("tag_editor.tscn")
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

func _ready() -> void:
	title_label.text = tag.name
	title_icon.texture = unknown_icon if tag is TagUnknown\
			else load("res://visual/icons/tag/" + tag.name + ".svg")
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
		if attribute is AttributeNumeric:
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
		if attribute_key in geometry_attributes:
			shape_container.add_child(input_field)
		else:
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


func _on_title_button_pressed() -> void:
	Utils.popup_under_control_centered(create_tag_context(), title_button)

func create_tag_context() -> Popup:
	var parent_tid := Utils.get_parent_tid(tid)
	var tag_count := SVG.root_tag.get_by_tid(parent_tid).get_child_count()
	var btn_array: Array[Button] = []
	
	btn_array.append(Utils.create_btn(tr(&"#duplicate"), Indications.duplicate_selected,
			false, load("res://visual/icons/Duplicate.svg")))
	
	if !tag.possible_conversions.is_empty():
		btn_array.append(Utils.create_btn(tr(&"#convert_to"), popup_convert_to_context,
				false, load("res://visual/icons/Reload.svg")))
	if tid[-1] > 0:
		btn_array.append(Utils.create_btn(tr(&"#move_up"), Indications.move_up_selected,
				false, load("res://visual/icons/MoveUp.svg")))
	if tid[-1] < tag_count - 1:
		btn_array.append(Utils.create_btn(tr(&"#move_down"), Indications.move_down_selected,
				false, load("res://visual/icons/MoveDown.svg")))
	
	btn_array.append(Utils.create_btn(tr(&"#delete"), Indications.delete_selected,
				false, load("res://visual/icons/Delete.svg")))
	
	var tag_context := ContextPopup.instantiate()
	add_child(tag_context)
	tag_context.set_button_array(btn_array, true)
	return tag_context


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_released():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.ctrl_pressed:
				Indications.ctrl_select(tid)
			elif event.shift_pressed:
				Indications.shift_select(tid)
			else:
				Indications.normal_select(tid)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not tid in Indications.selected_tids:
				Indications.normal_select(tid)
			Utils.popup_under_mouse(create_tag_context(), get_global_mouse_position())


func _on_mouse_exited() -> void:
	Indications.remove_hovered(tid)

func popup_convert_to_context() -> void:
	var btn_arr: Array[Button] = []
	for tag_name in tag.possible_conversions:
		var btn := Utils.create_btn(tag_name, _convert_to.bind(tag_name),
				!tag.can_replace(tag_name), load("res://visual/icons/tag/%s.svg" % tag_name))
		btn.add_theme_font_override(&"font", load("res://visual/fonts/FontMono.ttf"))
		btn_arr.append(btn)
	var context_popup := ContextPopup.instantiate()
	add_child(context_popup)
	context_popup.set_button_array(btn_arr, true)
	Utils.popup_under_control_centered(context_popup, title_button)

func _convert_to(tag_name: String) -> void:
	SVG.root_tag.replace_tag(tid, tag.get_replacement(tag_name))


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

#region drag and drop
func _get_drag_data(_at_position: Vector2) -> Variant:
	var data:Array[PackedInt32Array] = [tid]
	if tid in Indications.selected_tids:
		data = Indications.selected_tids
	var tags_container:VBoxContainer = VBoxContainer.new()
	for drag_tid in data:
		var preview = TagEditor.instantiate()
		preview.tag = SVG.root_tag.get_by_tid(drag_tid)
		preview.tid = drag_tid
		preview.custom_minimum_size.x = self.size.x
		preview.custom_minimum_size.y = self.size.y
		tags_container.add_child(preview)
	tags_container.modulate = Color('#ffffffd3')
	set_drag_preview(tags_container)
	return data

enum DropState{
	Inside = 0,
	Up,
	Down,
	Outside,
}

func _can_drop_data(_at_position: Vector2, current_tid: Variant) -> bool:
	if current_tid is Array and not  tid in current_tid:
		var state:DropState = drop_location_calculator(get_global_mouse_position())
		if state == DropState.Inside:
			var new_tid:PackedInt32Array = tid.duplicate()
			new_tid.append(0)
			if new_tid in current_tid: return false #is idx 0 child draged on parent
		drop_location_indicator(state)
		return true
	return false

func drop_location_calculator(at_position: Vector2) -> DropState:# returns inside,up,down,outside
	var top_bottom_margin:float = 0.18 # 0 - 1
	var tag_editor_area:Rect2 = Rect2(get_global_rect())
	if not tag_editor_area.has_point(at_position):
		return DropState.Outside
	var shrink_ratio:float = top_bottom_margin * float(tag_editor_area.size.y)
	tag_editor_area = tag_editor_area.grow_individual(0,- shrink_ratio,0,- shrink_ratio)
	if tag_editor_area.has_point(at_position):
		return DropState.Inside
	if tag_editor_area.position.y > at_position.y:
		return DropState.Up
	else:
		return DropState.Down
	return DropState.Outside

func drop_location_indicator(state: DropState) -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.set_corner_radius_all(4)
	stylebox.set_border_width_all(2)
	stylebox.set_content_margin_all(5)
	stylebox.bg_color = Color.from_hsv(0.625, 0.5, 0.25)
	stylebox.border_color = Color("yellow")
	match state:
		DropState.Inside:# adds as a child
			add_theme_stylebox_override(&"panel", stylebox)
			pass
		DropState.Up:# adds above its self
			stylebox.set_border_width_all(0)
			stylebox.border_width_top = 2
			add_theme_stylebox_override(&"panel", stylebox)
			pass
		DropState.Down:# adds down its self
			stylebox.set_border_width_all(0)
			stylebox.border_width_bottom = 2
			add_theme_stylebox_override(&"panel", stylebox)
			pass

func _drop_data(_at_position: Vector2, current_tid: Variant):
	var state:DropState = drop_location_calculator(get_global_mouse_position())
	var new_tid:PackedInt32Array = tid.duplicate()
	match state:
		DropState.Inside:
			new_tid.append(0)
		DropState.Up:
			new_tid[-1] -= 1 
		DropState.Down:
			new_tid[-1] += 1
	SVG.root_tag.move_tags_to(current_tid,new_tid)
#endregion
