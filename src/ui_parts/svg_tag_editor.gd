extends MarginContainer

const NumberField = preload("res://src/small_editors/number_field.tscn")
const RectField = preload("res://src/small_editors/rect_field.tscn")

signal viewbox_changed(w: float, h: float)

var tag := SVG.root_tag

@onready var h_box_container: HBoxContainer = $VBoxContainer/HBoxContainer

var width_edit: AttributeEditor
var height_edit: AttributeEditor
var viewbox_edit: AttributeEditor

func _ready() -> void:
	width_edit = NumberField.instantiate()
	width_edit.allow_higher = true
	width_edit.attribute = tag.attributes.width
	width_edit.attribute_name = "width"
	h_box_container.add_child(width_edit)
	width_edit.value_changed.connect(sync_dimensions_and_viewbox.unbind(1))
	
	height_edit = NumberField.instantiate()
	height_edit.allow_higher = true
	height_edit.attribute = tag.attributes.height
	height_edit.attribute_name = "height"
	h_box_container.add_child(height_edit)
	height_edit.value_changed.connect(sync_dimensions_and_viewbox.unbind(1))
	
	viewbox_edit = RectField.instantiate()
	viewbox_edit.attribute = tag.attributes.viewBox
	viewbox_edit.attribute_name = "viewBox"
	h_box_container.add_child(viewbox_edit)
	
	sync_dimensions_and_viewbox()
	update_viewbox()


func update_viewbox() -> void:
	width_edit.set_value(SVG.root_tag.attributes.width.value, false)
	height_edit.set_value(SVG.root_tag.attributes.height.value, false)
	viewbox_edit.set_value(SVG.root_tag.attributes.viewBox.value)

func sync_dimensions_and_viewbox() -> void:
	viewbox_edit.set_value(Rect2(0, 0, width_edit.get_value(), height_edit.get_value()))
