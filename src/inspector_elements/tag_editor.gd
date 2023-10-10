extends PanelContainer

const shape_attributes = ["cx", "cy", "x", "y", "r", "rx", "ry", "width", "height", "d",
		"x1", "y1", "x2", "y2"]

const NumberField = preload("number_field.tscn")
const ColorField = preload("color_field.tscn")
const PathField = preload("path_field.tscn")
const EnumField = preload("enum_field.tscn")

@onready var paint_container: FlowContainer = %AttributeContainer/PaintAttributes
@onready var shape_container: FlowContainer = %AttributeContainer/ShapeAttributes
@onready var title_button: Button = %TitleButton
@onready var tag_context: Popup = $ContextPopup
@onready var selected_highlight: Panel = $Panel

signal selected

var is_selected := false:
	set(value):
		is_selected = value
		selected_highlight.visible = value
		if is_selected:
			selected.emit(tag_index)

var tag_index: int
var tag: SVGTag

func _ready() -> void:
	# Fill up the containers.
	title_button.text = tag.title
	for attribute_key in tag.attributes:
		var attribute_value: SVGAttribute = tag.attributes[attribute_key]
		var input_field: AttributeEditor
		match attribute_value.type:
			SVGAttribute.Type.INT:
				input_field = NumberField.instantiate()
				input_field.remove_limits()
			SVGAttribute.Type.FLOAT:
				input_field = NumberField.instantiate()
				input_field.is_float = true
				input_field.min_value = -1024
				input_field.remove_limits()
			SVGAttribute.Type.UFLOAT:
				input_field = NumberField.instantiate()
				input_field.is_float = true
				input_field.allow_higher = true
			SVGAttribute.Type.NFLOAT:
				input_field = NumberField.instantiate()
				input_field.is_float = true
				input_field.max_value = 1
				input_field.step = 0.01
			SVGAttribute.Type.COLOR:
				input_field = ColorField.instantiate()
			SVGAttribute.Type.PATHDATA:
				input_field = PathField.instantiate()
			SVGAttribute.Type.ENUM:
				input_field = EnumField.instantiate()
		input_field.attribute = attribute_value
		input_field.attribute_name = attribute_key
		# Add the attribute to its corresponding container.
		if attribute_key in shape_attributes:
			shape_container.add_child(input_field)
		else:
			paint_container.add_child(input_field)


func _on_delete_button_pressed() -> void:
	SVG.data.delete_tag(tag_index)
	queue_free()

func _on_title_button_pressed() -> void:
	var tag_count := SVG.data.get_tag_count()
	if tag_count <= 1:
		return
	
	tag_context.reset()
	if tag_index != 0:
		var move_up_button := Button.new()
		move_up_button.text = "Move up"
		move_up_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		move_up_button.pressed.connect(_on_move_up_button_pressed)
		tag_context.add_button(move_up_button)
	if tag_index != tag_count - 1:
		var move_down_button := Button.new()
		move_down_button.text = "Move down"
		move_down_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		move_down_button.pressed.connect(_on_move_down_button_pressed)
		tag_context.add_button(move_down_button)
	tag_context.popup(Utils.calculate_popup_rect(title_button.global_position,
			title_button.size, tag_context.size))

func _on_move_up_button_pressed() -> void:
	tag_context.hide()
	SVG.data.move_tag(tag_index, tag_index - 1)

func _on_move_down_button_pressed() -> void:
	tag_context.hide()
	SVG.data.move_tag(tag_index, tag_index + 1)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and\
	event.button_index == MOUSE_BUTTON_LEFT:
		is_selected = not is_selected
