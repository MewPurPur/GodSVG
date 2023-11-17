extends MarginContainer

const NumberField = preload("res://src/ui_elements/number_field.tscn")
const RectField = preload("res://src/ui_elements/rect_field.tscn")

const coupled_icon = preload("res://visual/icons/Coupled.svg")
const decoupled_icon = preload("res://visual/icons/Decoupled.svg")

@onready var tag := SVG.root_tag
@onready var width_container: VBoxContainer = $Edits/Size/Width
@onready var height_container: VBoxContainer = $Edits/Size/Height
@onready var viewbox_container: VBoxContainer = $Edits/ViewBox
@onready var couple_button: Button = $Edits/CoupleButton

var width_edit: AttributeEditor
var height_edit: AttributeEditor
var viewbox_edit: AttributeEditor

func _ready() -> void:
	SVG.root_tag.changed_unknown.connect(_on_unknown_change)
	
	width_edit = NumberField.instantiate()
	width_edit.allow_lower = false
	width_edit.attribute = tag.attributes.width
	width_edit.attribute_name = "width"
	width_container.add_child(width_edit)
	width_edit.value_changed.connect(_on_attribute_changed.unbind(1))
	
	height_edit = NumberField.instantiate()
	height_edit.allow_lower = false
	height_edit.attribute = tag.attributes.height
	height_edit.attribute_name = "height"
	height_container.add_child(height_edit)
	height_edit.value_changed.connect(_on_attribute_changed.unbind(1))
	
	viewbox_edit = RectField.instantiate()
	viewbox_edit.attribute = tag.attributes.viewBox
	viewbox_edit.attribute_name = "viewBox"
	viewbox_container.add_child(viewbox_edit)
	viewbox_edit.value_changed.connect(_on_attribute_changed.unbind(1))
	update_coupling_config()


func _on_attribute_changed() -> void:
	width_edit.set_value(SVG.root_tag.attributes.width.get_value(), false)
	height_edit.set_value(SVG.root_tag.attributes.height.get_value(), false)
	couple_viewbox()

func _on_unknown_change() -> void:
	var svg_attrib := SVG.root_tag.attributes
	if GlobalSettings.save_data.viewbox_coupling and (svg_attrib.viewBox.get_value() !=\
	Rect2(0, 0, svg_attrib.width.get_value(), svg_attrib.height.get_value())):
		GlobalSettings.modify_save_data(&"viewbox_coupling", false)
	width_edit.set_value(SVG.root_tag.attributes.width.get_value(), false)
	height_edit.set_value(SVG.root_tag.attributes.height.get_value(), false)
	viewbox_edit.set_value(SVG.root_tag.attributes.viewBox.get_value())
	update_coupling_config()


func _on_couple_button_toggled(toggled_on: bool) -> void:
	GlobalSettings.modify_save_data(&"viewbox_coupling", toggled_on)
	update_coupling_config()
	couple_viewbox()

func update_coupling_config() -> void:
	var coupling_on := GlobalSettings.save_data.viewbox_coupling
	couple_button.button_pressed = coupling_on
	for number_edit in viewbox_edit.get_children():
		number_edit.editable = not coupling_on
	couple_button.icon = coupled_icon if coupling_on else decoupled_icon

func couple_viewbox() -> void:
	if GlobalSettings.save_data.viewbox_coupling:
		viewbox_edit.set_value(Rect2(0, 0, width_edit.get_value(), height_edit.get_value()))
