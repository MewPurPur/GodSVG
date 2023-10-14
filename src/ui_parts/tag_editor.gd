extends PanelContainer

const shape_attributes = ["cx", "cy", "x", "y", "r", "rx", "ry", "width", "height", "d",
		"x1", "y1", "x2", "y2"]

const NumberField = preload("res://src/small_editors/number_field.tscn")
const ColorField = preload("res://src/small_editors/color_field.tscn")
const PathField = preload("res://src/small_editors/path_field.tscn")
const EnumField = preload("res://src/small_editors/enum_field.tscn")

@onready var paint_container: FlowContainer = %AttributeContainer/PaintAttributes
@onready var shape_container: FlowContainer = %AttributeContainer/ShapeAttributes
@onready var title_button: Button = %TitleButton
@onready var tag_context: Popup = $ContextPopup
@onready var selected_highlight: Panel = $Panel

var tag_index: int
var tag: Tag

func _ready() -> void:
	Selections.selection_changed.connect(_on_selection_changed)
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
				input_field = NumberField.instantiate()
				input_field.allow_lower = false
				input_field.allow_higher = false
				input_field.show_slider = true
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


func _on_delete_button_pressed() -> void:
	SVG.root_tag.delete_tag(tag_index)
	queue_free()

func _on_title_button_pressed() -> void:
	var tag_count := SVG.root_tag.get_children_count()
	if tag_count <= 1:
		return
	
	tag_context.reset()
	var buttons_arr: Array[Button] = []
	if tag_index != 0:
		var move_up_button := Button.new()
		move_up_button.text = "Move up"
		move_up_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		move_up_button.pressed.connect(_on_move_up_button_pressed)
		buttons_arr.append(move_up_button)
	if tag_index != tag_count - 1:
		var move_down_button := Button.new()
		move_down_button.text = "Move down"
		move_down_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		move_down_button.pressed.connect(_on_move_down_button_pressed)
		buttons_arr.append(move_down_button)
	tag_context.set_btn_array(buttons_arr)
	tag_context.popup(Utils.calculate_popup_rect(title_button.global_position,
			title_button.size, tag_context.size))

func _on_move_up_button_pressed() -> void:
	tag_context.hide()
	SVG.root_tag.move_tag(tag_index, tag_index - 1)

func _on_move_down_button_pressed() -> void:
	tag_context.hide()
	SVG.root_tag.move_tag(tag_index, tag_index + 1)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and\
	event.button_index == MOUSE_BUTTON_LEFT:
		if event.ctrl_pressed:
			Selections.toggle_index(tag_index)
		else:
			Selections.set_selection(tag_index)

func _on_selection_changed() -> void:
	selected_highlight.visible = tag_index in Selections.selected_tags
