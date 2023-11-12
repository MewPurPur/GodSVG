extends PanelContainer

const shape_attributes = ["cx", "cy", "x", "y", "r", "rx", "ry", "width", "height", "d",
		"x1", "y1", "x2", "y2"]

const unknown_icon = preload("res://visual/icons/tag/unknown.svg")

const TagEditor = preload("tag_editor.tscn")
const NumberField = preload("res://src/ui_elements/number_field.tscn")
const NumberSlider = preload("res://src/ui_elements/number_field_with_slider.tscn")
const ColorField = preload("res://src/ui_elements/color_field.tscn")
const PathField = preload("res://src/ui_elements/path_field.tscn")
const EnumField = preload("res://src/ui_elements/enum_field.tscn")
const UnknownField = preload("res://src/ui_elements/unknown_field.tscn")

# This is needed for the hover detection hack.
@onready var first_ancestor_scroll_container := find_first_ancestor_scroll_container()

func find_first_ancestor_scroll_container() -> ScrollContainer:
	var ancestor := get_parent()
	while not ancestor is ScrollContainer:
		if not ancestor is Control:
			return null
		ancestor = ancestor.get_parent()
	return ancestor

@onready var paint_container: FlowContainer = %AttributeContainer/PaintAttributes
@onready var shape_container: FlowContainer = %AttributeContainer/ShapeAttributes
@onready var unknown_container: HFlowContainer = %AttributeContainer/UnknownAttributes
@onready var title_button: Button = %TitleButton
@onready var title_button_icon: TextureRect = %TitleButtonIcon
@onready var title_button_label: Label = %TitleButtonLabel
@onready var tag_context: Popup = $ContextPopup
@onready var margin_container: MarginContainer = $MarginContainer
@onready var child_tags_container: VBoxContainer = %ChildTags

var tid: PackedInt32Array
var tag: Tag

func _ready() -> void:
	determine_selection_highlight()
	tag.attribute_changed.connect(select_conditionally)
	Indications.selection_changed.connect(determine_selection_highlight)
	Indications.hover_changed.connect(determine_selection_highlight)
	# Fill up the containers. Start with unknown attributes, if there are any.
	if not tag.unknown_attributes.is_empty():
		unknown_container.show()
	for attribute in tag.unknown_attributes:
		var input_field: AttributeEditor = UnknownField.instantiate()
		input_field.attribute = attribute
		input_field.attribute_name = attribute.name
		unknown_container.add_child(input_field)
	# Continue with supported attributes.
	title_button_label.text = tag.name
	if title_button_label.text.length() > 7:
		title_button_label.add_theme_font_size_override(&"font_size", 11)
	title_button_icon.texture = unknown_icon if tag is TagUnknown\
			else load("res://visual/icons/tag/" + tag.name + ".svg")
	for attribute_key in tag.attributes:
		var attribute: Attribute = tag.attributes[attribute_key]
		var input_field: AttributeEditor
		match attribute.type:
			Attribute.Type.INT:
				input_field = NumberField.instantiate()
				input_field.is_float = false
			Attribute.Type.FLOAT:
				input_field = NumberField.instantiate()
			Attribute.Type.UFLOAT:
				input_field = NumberField.instantiate()
				input_field.allow_lower = false
			Attribute.Type.NFLOAT:
				input_field = NumberSlider.instantiate()
				input_field.allow_lower = false
				input_field.allow_higher = false
				input_field.slider_step = 0.01
			Attribute.Type.COLOR:
				input_field = ColorField.instantiate()
			Attribute.Type.PATHDATA:
				input_field = PathField.instantiate()
			Attribute.Type.ENUM:
				input_field = EnumField.instantiate()
		input_field.attribute = attribute
		input_field.attribute_name = attribute_key
		# Add the attribute to its corresponding container.
		if attribute_key in shape_attributes:
			shape_container.add_child(input_field)
		else:
			paint_container.add_child(input_field)
	
	determine_selection_highlight()
	
	if not tag.child_tags.is_empty():
		child_tags_container.show()
		
		for tag_idx in tag.get_child_count():
			var child_tag := tag.child_tags[tag_idx]
			var tag_editor := TagEditor.instantiate()
			tag_editor.tag = child_tag
			var new_tid := tid.duplicate()
			new_tid.append(tag_idx)
			tag_editor.tid = new_tid
			child_tags_container.add_child(tag_editor)


func tag_context_populate() -> void:
	var parent_tid := Utils.get_parent_tid(tid)
	var tag_count := SVG.root_tag.get_by_tid(parent_tid).get_child_count()
	var buttons_arr: Array[Button] = []
	
	var duplicate_button := Button.new()
	duplicate_button.text = tr(&"#duplicate")
	duplicate_button.icon = load("res://visual/icons/Duplicate.svg")
	duplicate_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	duplicate_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	duplicate_button.pressed.connect(_on_duplicate_button_pressed)
	buttons_arr.append(duplicate_button)
	
	if tid[-1] > 0:
		var move_up_button := Button.new()
		move_up_button.text = tr(&"#move_up")
		move_up_button.icon = load("res://visual/icons/MoveUp.svg")
		move_up_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		move_up_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		move_up_button.pressed.connect(_on_move_up_button_pressed)
		buttons_arr.append(move_up_button)
	if tid[-1] < tag_count - 1:
		var move_down_button := Button.new()
		move_down_button.text = tr(&"#move_down")
		move_down_button.icon = load("res://visual/icons/MoveDown.svg")
		move_down_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		move_down_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		move_down_button.pressed.connect(_on_move_down_button_pressed)
		buttons_arr.append(move_down_button)
	
	var delete_button := Button.new()
	delete_button.text = tr(&"#delete")
	delete_button.icon = load("res://visual/icons/Delete.svg")
	delete_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	delete_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	delete_button.pressed.connect(_on_delete_button_pressed)
	buttons_arr.append(delete_button)
	
	tag_context.set_btn_array(buttons_arr)

func _on_title_button_pressed() -> void:
	Indications.normal_select(tid)
	tag_context_populate()
	Utils.popup_under_control(tag_context, title_button)

func _on_move_up_button_pressed() -> void:
	tag_context.hide()
	SVG.root_tag.move_tags_in_parent([tid], false)

func _on_move_down_button_pressed() -> void:
	tag_context.hide()
	SVG.root_tag.move_tags_in_parent([tid], true)

func _on_delete_button_pressed() -> void:
	tag_context.hide()
	SVG.root_tag.delete_tags([tid])

func _on_duplicate_button_pressed() -> void:
	tag_context.hide()
	SVG.root_tag.duplicate_tags([tid])


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.ctrl_pressed:
				Indications.ctrl_select(tid)
			elif event.shift_pressed:
				Indications.shift_select(tid)
			else:
				Indications.normal_select(tid)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			Indications.normal_select(tid)
			tag_context_populate()
			tag_context.popup(Rect2(get_global_mouse_position() +\
					Vector2(-tag_context.size.x / 2, 0), tag_context.size))


var mouse_inside := false:
	set(new_value):
		if mouse_inside != new_value:
			mouse_inside = new_value
			if mouse_inside:
				Indications.set_hovered(tid)
			else:
				Indications.remove_hovered(tid)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == 0:
		mouse_inside = get_global_rect().has_point(get_global_mouse_position()) and\
				first_ancestor_scroll_container.get_global_rect().has_point(
				get_global_mouse_position()) and Indications.semi_hovered_tid != tid and\
				not Utils.is_tid_parent(tid, Indications.hovered_tid)


func determine_selection_highlight() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.set_corner_radius_all(4)
	stylebox.set_border_width_all(2)
	
	var is_selected := tid in Indications.selected_tids
	var is_hovered := Indications.hovered_tid == tid
	
	if is_selected:
		if is_hovered:
			stylebox.bg_color = Color.from_hsv(0.625, 0.48, 0.27)
		else:
			stylebox.bg_color = Color.from_hsv(0.625, 0.5, 0.25)
		stylebox.border_color = Color.from_hsv(0.6, 0.7, 0.54)
	elif is_hovered:
		stylebox.bg_color = Color.from_hsv(0.625, 0.57, 0.19)
		stylebox.border_color = Color.from_hsv(0.625, 0.5, 0.3)
	else:
		stylebox.bg_color = Color.from_hsv(0.625, 0.6, 0.16)
		stylebox.border_color = Color.from_hsv(0.625, 0.56, 0.25)
	
	var depth := tid.size() - 1
	if depth > 0:
		stylebox.bg_color = Color.from_hsv(stylebox.bg_color.h + depth * 0.12,
				stylebox.bg_color.s, stylebox.bg_color.v)
		stylebox.border_color = Color.from_hsv(stylebox.border_color.h + depth * 0.12,
				stylebox.border_color.s, stylebox.border_color.v)
	add_theme_stylebox_override(&"panel", stylebox)

func select_conditionally() -> void:
	if Indications.semi_selected_tid != tid:
		Indications.normal_select(tid)


func _on_title_button_container_draw() -> void:
	title_button.custom_minimum_size = title_button.get_child(0).size
