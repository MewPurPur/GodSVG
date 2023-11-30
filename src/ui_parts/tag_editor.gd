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
		var input_field: AttributeEditor = UnknownField.instantiate()
		input_field.attribute = attribute
		input_field.attribute_name = attribute.name
		unknown_container.add_child(input_field)
	# Continue with supported attributes.
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


func create_tag_context() -> Popup:
	var parent_tid := Utils.get_parent_tid(tid)
	var tag_count := SVG.root_tag.get_by_tid(parent_tid).get_child_count()
	var buttons_arr: Array[Button] = []
	
	var duplicate_button := Button.new()
	duplicate_button.text = tr(&"#duplicate")
	duplicate_button.icon = load("res://visual/icons/Duplicate.svg")
	duplicate_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	duplicate_button.pressed.connect(_on_duplicate_button_pressed)
	buttons_arr.append(duplicate_button)
	
	if tid[-1] > 0:
		var move_up_button := Button.new()
		move_up_button.text = tr(&"#move_up")
		move_up_button.icon = load("res://visual/icons/MoveUp.svg")
		move_up_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		move_up_button.pressed.connect(_on_move_up_button_pressed)
		buttons_arr.append(move_up_button)
	if tid[-1] < tag_count - 1:
		var move_down_button := Button.new()
		move_down_button.text = tr(&"#move_down")
		move_down_button.icon = load("res://visual/icons/MoveDown.svg")
		move_down_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		move_down_button.pressed.connect(_on_move_down_button_pressed)
		buttons_arr.append(move_down_button)
	
	var delete_button := Button.new()
	delete_button.text = tr(&"#delete")
	delete_button.icon = load("res://visual/icons/Delete.svg")
	delete_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	delete_button.pressed.connect(_on_delete_button_pressed)
	buttons_arr.append(delete_button)
	
	var tag_context := ContextPopup.instantiate()
	add_child(tag_context)
	tag_context.set_btn_array(buttons_arr)
	return tag_context


func _on_title_button_pressed() -> void:
	Indications.normal_select(tid)
	var tag_context := create_tag_context()
	Utils.popup_under_control_centered(tag_context, title_button)

func _on_move_up_button_pressed() -> void:
	SVG.root_tag.move_tags_in_parent([tid], false)

func _on_move_down_button_pressed() -> void:
	SVG.root_tag.move_tags_in_parent([tid], true)

func _on_delete_button_pressed() -> void:
	SVG.root_tag.delete_tags([tid])

func _on_duplicate_button_pressed() -> void:
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
			var tag_context := create_tag_context()
			Utils.popup_under_mouse(tag_context, get_global_mouse_position())


func _on_mouse_entered():
	if Indications.semi_hovered_tid != tid and\
		not Utils.is_tid_parent(tid, Indications.hovered_tid):
		Indications.set_hovered(tid)

func _on_mouse_exited():
	Indications.remove_hovered(tid)


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
