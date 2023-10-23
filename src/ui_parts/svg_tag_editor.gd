extends MarginContainer

var coupled_viewbox := true

const NumberField = preload("res://src/small_editors/number_field.tscn")
const RectField = preload("res://src/small_editors/rect_field.tscn")

const coupled_icon = preload("res://visual/icons/Coupled.svg")
const decoupled_icon = preload("res://visual/icons/Decoupled.svg")

signal viewbox_changed(w: float, h: float)

@onready var tag := SVG.root_tag
@onready var width_container: VBoxContainer = $Edits/Size/Width
@onready var height_container: VBoxContainer = $Edits/Size/Height
@onready var viewbox_container: VBoxContainer = $Edits/ViewBox
@onready var couple_button: Button = $Edits/CoupleButton

var width_edit: AttributeEditor
var height_edit: AttributeEditor
var viewbox_edit: AttributeEditor

func _ready() -> void:
	width_edit = NumberField.instantiate()
	width_edit.allow_lower = false
	width_edit.attribute = tag.attributes.width.duplicate()
	width_edit.attribute_name = "width"
	width_container.add_child(width_edit)
	width_edit.value_changed.connect(set_svg_width_attribute.unbind(1))
	
	height_edit = NumberField.instantiate()
	height_edit.allow_lower = false
	height_edit.attribute = tag.attributes.height.duplicate()
	height_edit.attribute_name = "height"
	height_container.add_child(height_edit)
	height_edit.value_changed.connect(set_svg_height_attribute.unbind(1))
	
	viewbox_edit = RectField.instantiate()
	viewbox_edit.attribute = tag.attributes.viewBox.duplicate()
	viewbox_edit.attribute_name = "viewBox"
	viewbox_container.add_child(viewbox_edit)
	viewbox_edit.value_changed.connect(set_svg_viewbox_attribute.unbind(1))
	
	determine_viewbox_edit()
	update_svg_attributes()

func update_svg_attributes() -> void:
	var new_width_value: float= SVG.root_tag.attributes.width.value
	var new_height_value: float = SVG.root_tag.attributes.height.value
	width_edit.set_value(new_width_value, false)
	height_edit.set_value(new_height_value, false)
	if coupled_viewbox:
		viewbox_edit.set_value(Rect2(0, 0, new_width_value, new_height_value))
	else:
		viewbox_edit.set_value(SVG.root_tag.attributes.viewBox.value)

func _on_couple_button_toggled(toggled_on: bool) -> void:
	coupled_viewbox = toggled_on
	determine_viewbox_edit()

func determine_viewbox_edit() -> void:
	for number_edit in viewbox_edit.get_children():
		number_edit.num_edit.editable = not coupled_viewbox
	couple_button.icon = coupled_icon if coupled_viewbox else decoupled_icon
	update_svg_attributes()

func svg_undo_redo_action(name:String,tag_attribute:Attribute,do_value) ->void:
	UndoRedoManager.create_action(name)
	UndoRedoManager.add_do_method(set_svg_attribute.bind(
		tag_attribute,do_value))
	UndoRedoManager.add_undo_method(set_svg_attribute.bind(
		tag_attribute,tag_attribute.value))
	UndoRedoManager.commit_action()

func  set_svg_attribute(tag_attribute:Attribute,value) -> void:
	tag_attribute.value = value
	update_svg_attributes()

func  set_svg_width_attribute() -> void:
	svg_undo_redo_action(
		"Change SVG width attribute",
		tag.attributes.width,
		width_edit.attribute.value)

func  set_svg_height_attribute() -> void:
	svg_undo_redo_action(
		"Change SVG height attribute",
		tag.attributes.height,
		height_edit.attribute.value)

func  set_svg_viewbox_attribute() -> void:
	if coupled_viewbox:
		set_svg_attribute(tag.attributes.viewBox,viewbox_edit.attribute.value)
	else:
		svg_undo_redo_action(
			"Change SVG width attribute",
			tag.attributes.viewBox,
			viewbox_edit.attribute.value)
