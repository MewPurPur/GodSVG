extends PanelContainer

const shape_attributes = ["cx", "cy", "x", "y", "r", "rx", "ry", "width", "height", "d",
		"x1", "y1", "x2", "y2"]

const NumberField = preload("res://src/small_editors/number_field.tscn")
const NumberSlider = preload("res://src/small_editors/number_field_with_slider.tscn")
const ColorField = preload("res://src/small_editors/color_field.tscn")
const PathField = preload("res://src/small_editors/path_field.tscn")
const EnumField = preload("res://src/small_editors/enum_field.tscn")

@onready var paint_container: FlowContainer = %AttributeContainer/PaintAttributes
@onready var shape_container: FlowContainer = %AttributeContainer/ShapeAttributes
@onready var title_button: Button = %TitleButton
@onready var tag_context: Popup = $ContextPopup
@onready var margin_container: MarginContainer = $MarginContainer

var tag_index: int
var tag: Tag
var old_value_tag:Tag

func _ready() -> void:
	old_value_tag = tag.duplicate()
	determine_selection_highlight()
	tag.attribute_changed.connect(select_conditionally)
	Interactions.selection_changed.connect(determine_selection_highlight)
	Interactions.hover_changed.connect(determine_selection_highlight)
	# Fill up the containers.
	title_button.text = tag.title
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
		input_field.value_changed.connect(input_field_undo_redo_action.bind(
			input_field),CONNECT_REFERENCE_COUNTED)
		if attribute_key in shape_attributes:
			shape_container.add_child(input_field)
		else:
			paint_container.add_child(input_field)
		
func input_field_undo_redo_action(new_value,input_field:AttributeEditor):
	var old_value = old_value_tag.attributes[input_field.attribute_name].value
	old_value_tag.attributes[input_field.attribute_name].value = new_value
	# Works with Attribute.Type : INT, FLOAT, UFLOAT, COLOR, ENUM, NFLOAT and PATHDATA
	UndoRedoManager.undo_redo.create_action(
	tag.title + " change: " + input_field.attribute_name)
	UndoRedoManager.undo_redo.add_do_reference(input_field)
	UndoRedoManager.undo_redo.add_undo_reference(input_field)
	UndoRedoManager.undo_redo.add_do_method(input_field.set_value.bind(
		new_value,false))
	UndoRedoManager.undo_redo.add_undo_method(input_field.set_value.bind(
		old_value,false))
	UndoRedoManager.undo_redo.commit_action(false)

func tag_context_populate() -> void:
	var tag_count := SVG.root_tag.get_child_count()
	var buttons_arr: Array[Button] = []
	
	var duplicate_button := Button.new()
	duplicate_button.text = tr(&"#duplicate")
	duplicate_button.icon = load("res://visual/icons/Duplicate.svg")
	duplicate_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	duplicate_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	duplicate_button.pressed.connect(_on_duplicate_button_pressed)
	buttons_arr.append(duplicate_button)
	
	if tag_index > 0:
		var move_up_button := Button.new()
		move_up_button.text = tr(&"#move_up")
		move_up_button.icon = load("res://visual/icons/MoveUp.svg")
		move_up_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		move_up_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		move_up_button.pressed.connect(_on_move_up_button_pressed)
		buttons_arr.append(move_up_button)
	if tag_index < tag_count - 1:
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
	Interactions.set_selection(tag_index)
	tag_context_populate()
	tag_context.popup(Utils.calculate_popup_rect(title_button.global_position,
			title_button.size, tag_context.size))

func _on_move_up_button_pressed() -> void:
	tag_context.hide()
	SVG.root_tag.move_tag(tag_index, tag_index - 1)

func _on_move_down_button_pressed() -> void:
	tag_context.hide()
	SVG.root_tag.move_tag(tag_index, tag_index + 1)

func _on_delete_button_pressed() -> void:
	tag_context.hide()
	SVG.root_tag.delete_tag(tag_index)

func _on_duplicate_button_pressed() -> void:
	tag_context.hide()
	SVG.root_tag.duplicate_tag(tag_index)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.ctrl_pressed:
				Interactions.toggle_selection(tag_index)
			else:
				Interactions.set_selection(tag_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			Interactions.set_selection(tag_index)
			tag_context_populate()
			tag_context.popup(Utils.calculate_popup_rect(get_global_mouse_position(),
					Vector2.ZERO, tag_context.size, true))


var mouse_inside := false:
	set(new_value):
		if mouse_inside != new_value:
			mouse_inside = new_value
			if mouse_inside:
				Interactions.set_hovered(tag_index)
			else:
				Interactions.remove_hovered(tag_index)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if get_global_rect().has_point(get_global_mouse_position()) and\
		Interactions.tag_with_inner_hovered != tag_index:
			mouse_inside = true
		else:
			mouse_inside = false


func determine_selection_highlight() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.set_corner_radius_all(4)
	stylebox.set_border_width_all(2)
	if tag_index in Interactions.selected_tags:
		if Interactions.hovered_tag == tag_index:
			stylebox.bg_color = Color(0.12, 0.15, 0.24).lightened(0.015)
		else:
			stylebox.bg_color = Color(0.12, 0.15, 0.24)
		stylebox.border_color = Color(0.18, 0.28, 0.44)
	elif Interactions.hovered_tag == tag_index:
		stylebox.bg_color = Color(0.065, 0.085, 0.15).lightened(0.02)
		stylebox.border_color = Color(0.065, 0.085, 0.15).lightened(0.08)
	else:
		stylebox.bg_color = Color(0.065, 0.085, 0.15)
		stylebox.border_color = Color(0.065, 0.085, 0.15).lightened(0.04)
	add_theme_stylebox_override(&"panel", stylebox)

func select_conditionally() -> void:
	if Interactions.tag_with_inner_selections != tag_index:
		Interactions.set_selection(tag_index)
