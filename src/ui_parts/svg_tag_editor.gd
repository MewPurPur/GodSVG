extends MarginContainer

var coupled_viewbox := true

const NumberField = preload("res://src/small_editors/number_field.tscn")
const RectField = preload("res://src/small_editors/rect_field.tscn")

signal viewbox_changed(w: float, h: float)

@onready var tag := SVG.root_tag
@onready var width_container: VBoxContainer = $Edits/Size/Width
@onready var height_container: VBoxContainer = $Edits/Size/Height
@onready var viewbox_container: VBoxContainer = $Edits/ViewBox

var width_edit: AttributeEditor
var height_edit: AttributeEditor
var viewbox_edit: AttributeEditor

func _ready() -> void:
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
	update_svg_attributes()
