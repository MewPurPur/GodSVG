extends MarginContainer

# So, about this editor. Width and height don't have real default values, so they use NAN
# and are NumberEdits, rather than NumberFields. Viewbox is its own thing and since
# it's made of four numbers, and also since I want a coupling functionality with width
# and height, I didn't make an AttributeEditor for it. It's just 4 NumberEdits.

const NumberEditType = preload("res://src/ui_elements/number_edit.gd")

const coupled_icon = preload("res://visual/icons/Coupled.svg")
const decoupled_icon = preload("res://visual/icons/Decoupled.svg")

var true_width: float
var true_height: float
var true_viewbox: Rect2

@onready var tag := SVG.root_tag
@onready var couple_button: Button = $Edits/CoupleButton
@onready var width_button: Button = $Edits/Size/Width/WidthButton
@onready var height_button: Button = $Edits/Size/Height/HeightButton
@onready var viewbox_button: Button = $Edits/Viewbox/ViewboxButton
@onready var width_edit: NumberEditType = $Edits/Size/Width/WidthEdit
@onready var height_edit: NumberEditType = $Edits/Size/Height/HeightEdit
@onready var viewbox_edit_x: NumberEditType = $Edits/Viewbox/Rect/ViewboxEditX
@onready var viewbox_edit_y: NumberEditType = $Edits/Viewbox/Rect/ViewboxEditY
@onready var viewbox_edit_w: NumberEditType = $Edits/Viewbox/Rect/ViewboxEditW
@onready var viewbox_edit_h: NumberEditType = $Edits/Viewbox/Rect/ViewboxEditH

func _ready() -> void:
	SVG.root_tag.resized.connect(_on_resized)
	SVG.root_tag.changed_unknown.connect(_on_unknown_changed)
	update_attributes(true)


func _on_resized() -> void:
	update_attributes()

func update_attributes(configure_coupling := false) -> void:
	if configure_coupling:
		update_coupling_config()
	true_width = SVG.root_tag.get_width()
	true_height = SVG.root_tag.get_height()
	true_viewbox = SVG.root_tag.get_viewbox()
	width_edit.set_value(true_width, false)
	height_edit.set_value(true_height, false)
	viewbox_edit_x.set_value(true_viewbox.position.x, false)
	viewbox_edit_y.set_value(true_viewbox.position.y, false)
	viewbox_edit_w.set_value(true_viewbox.size.x, false)
	viewbox_edit_h.set_value(true_viewbox.size.y, false)

func _on_unknown_changed() -> void:
	if GlobalSettings.save_data.viewbox_coupling and (SVG.root_tag.get_viewbox() !=\
	Rect2(Vector2.ZERO, SVG.root_tag.get_size())):
		GlobalSettings.modify_save_data(&"viewbox_coupling", false)
	update_attributes(true)


func _on_couple_button_toggled(toggled_on: bool) -> void:
	GlobalSettings.modify_save_data(&"viewbox_coupling", toggled_on)
	update_coupling_config()

func update_coupling_config() -> void:
	if SVG.root_tag.attributes.width.get_value().is_empty() or\
	SVG.root_tag.attributes.height.get_value().is_empty() or\
	SVG.root_tag.attributes.viewBox.get_value().is_empty():
		couple_button.disabled = true
		couple_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		couple_button.icon = coupled_icon
	else:
		couple_button.disabled = false
		couple_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var coupling_on := GlobalSettings.save_data.viewbox_coupling
		couple_button.button_pressed = coupling_on
		couple_button.icon = coupled_icon if coupling_on else decoupled_icon
		if coupling_on:
			SVG.root_tag.attributes.viewBox.set_list(PackedFloat32Array([
					0.0, 0.0, SVG.root_tag.get_width(), SVG.root_tag.get_height()]))
	update_editable()


func update_editable() -> void:
	var is_width_valid := is_finite(SVG.root_tag.attributes.width.get_num())
	var is_height_valid := is_finite(SVG.root_tag.attributes.height.get_num())
	var is_viewbox_valid: bool = !SVG.root_tag.attributes.viewBox.get_value().is_empty()
	var coupling_on := GlobalSettings.save_data.viewbox_coupling and\
			not couple_button.disabled
	
	width_button.set_pressed_no_signal(is_width_valid)
	height_button.set_pressed_no_signal(is_height_valid)
	viewbox_button.set_pressed_no_signal(is_viewbox_valid)
	
	width_edit.editable = is_width_valid
	height_edit.editable = is_height_valid
	viewbox_edit_x.editable = is_viewbox_valid and not coupling_on
	viewbox_edit_y.editable = is_viewbox_valid and not coupling_on
	viewbox_edit_w.editable = is_viewbox_valid
	viewbox_edit_h.editable = is_viewbox_valid


func _on_width_edit_value_changed(new_value: float) -> void:
	if is_finite(new_value) and SVG.root_tag.attributes.width.get_num() != new_value:
		true_width = new_value
		if GlobalSettings.save_data.viewbox_coupling:
			SVG.root_tag.attributes.width.set_num(new_value,
					Attribute.SyncMode.NO_PROPAGATION)
			SVG.root_tag.attributes.viewBox.set_list_element(2, new_value)
		else:
			SVG.root_tag.attributes.width.set_num(new_value)
	else:
		SVG.root_tag.attributes.width.set_num(SVG.root_tag.get_width(), false)

func _on_height_edit_value_changed(new_value: float) -> void:
	if is_finite(new_value) and SVG.root_tag.attributes.height.get_num() != new_value:
		true_height = new_value
		if GlobalSettings.save_data.viewbox_coupling:
			SVG.root_tag.attributes.height.set_num(new_value,
					Attribute.SyncMode.NO_PROPAGATION)
			SVG.root_tag.attributes.viewBox.set_list_element(3, new_value)
		else:
			SVG.root_tag.attributes.height.set_num(new_value)
	else:
		SVG.root_tag.attributes.height.set_num(SVG.root_tag.get_height(), false)

func _on_viewbox_edit_x_value_changed(new_value: float) -> void:
	if SVG.root_tag.attributes.viewBox.get_value() != null:
		true_viewbox.position.x = new_value
		SVG.root_tag.attributes.viewBox.set_list_element(0, new_value)

func _on_viewbox_edit_y_value_changed(new_value: float) -> void:
	if SVG.root_tag.attributes.viewBox.get_value() != null:
		true_viewbox.position.y = new_value
		SVG.root_tag.attributes.viewBox.set_list_element(1, new_value)

func _on_viewbox_edit_w_value_changed(new_value: float) -> void:
	if SVG.root_tag.attributes.viewBox.get_value() != null and\
	SVG.root_tag.attributes.viewBox.get_list_element(2) != new_value:
		true_viewbox.size.x = new_value
		if GlobalSettings.save_data.viewbox_coupling:
			SVG.root_tag.attributes.viewBox.set_list_element(2, new_value,
					Attribute.SyncMode.NO_PROPAGATION)
			SVG.root_tag.attributes.width.set_num(new_value)
		else:
			SVG.root_tag.attributes.viewBox.set_list_element(2, new_value)

func _on_viewbox_edit_h_value_changed(new_value: float) -> void:
	if SVG.root_tag.attributes.viewBox.get_value() != null and\
	SVG.root_tag.attributes.viewBox.get_list_element(3) != new_value:
		true_viewbox.size.y = new_value
		if GlobalSettings.save_data.viewbox_coupling:
			SVG.root_tag.attributes.viewBox.set_list_element(3, new_value,
					Attribute.SyncMode.NO_PROPAGATION)
			SVG.root_tag.attributes.height.set_num(new_value)
		else:
			SVG.root_tag.attributes.viewBox.set_list_element(3, new_value)

func _on_width_button_toggled(toggled_on: bool) -> void:
	SVG.root_tag.attributes.width.set_num(true_width if toggled_on else NAN)
	update_coupling_config()

func _on_height_button_toggled(toggled_on: bool) -> void:
	SVG.root_tag.attributes.height.set_num(true_height if toggled_on else NAN)
	update_coupling_config()

func _on_viewbox_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		SVG.root_tag.attributes.viewBox.set_rect(true_viewbox)
	else:
		SVG.root_tag.attributes.viewBox.set_value("")
	update_coupling_config()
