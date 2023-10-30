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
	SVG.root_tag.changed_unknown.connect(determine_coupling)
	
	width_edit = NumberField.instantiate()
	width_edit.allow_lower = false
	width_edit.attribute = tag.attributes.width
	width_edit.attribute_name = "width"
	width_container.add_child(width_edit)
	width_edit.value_changed.connect(update_svg_attributes.unbind(1))
	
	height_edit = NumberField.instantiate()
	height_edit.allow_lower = false
	height_edit.attribute = tag.attributes.height
	height_edit.attribute_name = "height"
	height_container.add_child(height_edit)
	height_edit.value_changed.connect(update_svg_attributes.unbind(1))
	
	viewbox_edit = RectField.instantiate()
	viewbox_edit.attribute = tag.attributes.viewBox
	viewbox_edit.attribute_name = "viewBox"
	viewbox_container.add_child(viewbox_edit)
	viewbox_edit.value_changed.connect(update_svg_attributes.unbind(1))
	determine_coupling()


func update_svg_attributes() -> void:
	var new_width_value: float = SVG.root_tag.attributes.width.get_value()
	var new_height_value: float = SVG.root_tag.attributes.height.get_value()
	width_edit.set_value(new_width_value, false)
	height_edit.set_value(new_height_value, false)
	if coupled_viewbox:
		viewbox_edit.set_value(Rect2(0, 0, new_width_value, new_height_value))
	else:
		viewbox_edit.set_value(SVG.root_tag.attributes.viewBox.get_value())


func _on_couple_button_toggled(toggled_on: bool) -> void:
	coupled_viewbox = toggled_on
	determine_viewbox_edit()

func determine_viewbox_edit() -> void:
	for number_edit in viewbox_edit.get_children():
		number_edit.num_edit.editable = not coupled_viewbox
	couple_button.icon = coupled_icon if coupled_viewbox else decoupled_icon
	couple_button.button_pressed = coupled_viewbox
	update_svg_attributes()

func determine_coupling() -> void:
	var svg_attrib := SVG.root_tag.attributes
	if coupled_viewbox and (svg_attrib.viewBox.get_value() !=\
	Rect2(0, 0, svg_attrib.width.get_value(), svg_attrib.height.get_value())):
		coupled_viewbox = false
	determine_viewbox_edit()
