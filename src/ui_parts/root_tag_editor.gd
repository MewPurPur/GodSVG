extends VBoxContainer

# So, about this editor. Width and height don't have default values, so they use NAN and
# use NumberEdit, rather than NumberField. Viewbox is a list and it also doesn't have a
# default value, so it uses 4 NumberEdits.

const UnrecognizedField = preload("res://src/ui_elements/unrecognized_field.tscn")
const ColorField = preload("res://src/ui_elements/color_field.tscn")
const NumberField = preload("res://src/ui_elements/number_field.tscn")
const NumberSlider = preload("res://src/ui_elements/number_field_with_slider.tscn")
const IDField = preload("res://src/ui_elements/id_field.tscn")
const EnumField = preload("res://src/ui_elements/enum_field.tscn")
const TransformField = preload("res://src/ui_elements/transform_field.tscn")

const NumberEditType = preload("res://src/ui_elements/number_edit.gd")

@onready var width_button: Button = %Size/Width/WidthButton
@onready var height_button: Button = %Size/Height/HeightButton
@onready var viewbox_button: Button = %Viewbox/ViewboxButton
@onready var width_edit: NumberEditType = %Size/Width/WidthEdit
@onready var height_edit: NumberEditType = %Size/Height/HeightEdit
@onready var viewbox_edit_x: NumberEditType = %Viewbox/Rect/ViewboxEditX
@onready var viewbox_edit_y: NumberEditType = %Viewbox/Rect/ViewboxEditY
@onready var viewbox_edit_w: NumberEditType = %Viewbox/Rect/ViewboxEditW
@onready var viewbox_edit_h: NumberEditType = %Viewbox/Rect/ViewboxEditH
@onready var unknown_container: HFlowContainer

var root_tag: TagRoot

func _ready() -> void:
	root_tag = SVG.root_tag
	SVG.resized.connect(update_attributes)
	SVG.changed_unknown.connect(update_attributes)
	update_attributes()


func update_attributes() -> void:
	# If there are unknown attributes, they would always be on top.
	if is_instance_valid(unknown_container):
		for child in unknown_container.get_children():
			child.queue_free()
	var has_unrecognized_attributes := false
	for attribute in root_tag.attributes.values():
		# TODO separate unrecognized attributes from global defaults.
		if not attribute.name in ["width", "height", "viewBox", "xmlns"]:
			if not has_unrecognized_attributes:
				has_unrecognized_attributes = true
				if is_instance_valid(unknown_container):
					unknown_container.queue_free()
				unknown_container = HFlowContainer.new()
				add_child(unknown_container)
				move_child(unknown_container, 0)
			
			var input_field: Control
			match DB.get_attribute_type(attribute.name):
				DB.AttributeType.COLOR: input_field = ColorField.instantiate()
				DB.AttributeType.ENUM: input_field = EnumField.instantiate()
				DB.AttributeType.TRANSFORM_LIST: input_field = TransformField.instantiate()
				DB.AttributeType.ID: input_field = IDField.instantiate()
				DB.AttributeType.NUMERIC:
					var min_value: float = DB.attribute_numeric_bounds[attribute.name].x
					var max_value: float = DB.attribute_numeric_bounds[attribute.name].y
					if is_inf(max_value):
						input_field = NumberField.instantiate()
						if not is_inf(min_value):
							input_field.allow_lower = false
							input_field.min_value = min_value
					else:
						input_field = NumberSlider.instantiate()
						input_field.allow_lower = false
						input_field.allow_higher = false
						input_field.min_value = min_value
						input_field.max_value = max_value
						input_field.slider_step = 0.01
				_: input_field = UnrecognizedField.instantiate()
			input_field.tag = root_tag
			input_field.attribute_name = attribute.name
			unknown_container.add_child(input_field)
	if not has_unrecognized_attributes and is_instance_valid(unknown_container):
		unknown_container.queue_free()
	
	width_edit.set_value(root_tag.width, false)
	height_edit.set_value(root_tag.height, false)
	viewbox_edit_x.set_value(root_tag.viewbox.position.x, false)
	viewbox_edit_y.set_value(root_tag.viewbox.position.y, false)
	viewbox_edit_w.set_value(root_tag.viewbox.size.x, false)
	viewbox_edit_h.set_value(root_tag.viewbox.size.y, false)
	update_editable()


func update_editable() -> void:
	var is_width_valid := root_tag.attributes.has("width")
	var is_height_valid := root_tag.attributes.has("height")
	var is_viewbox_valid: bool = root_tag.attributes.has("viewBox") and\
			root_tag.get_attribute("viewBox").get_list_size() >= 4
	
	width_button.set_pressed_no_signal(is_width_valid)
	height_button.set_pressed_no_signal(is_height_valid)
	viewbox_button.set_pressed_no_signal(is_viewbox_valid)
	
	width_edit.editable = is_width_valid
	height_edit.editable = is_height_valid
	viewbox_edit_x.editable = is_viewbox_valid
	viewbox_edit_y.editable = is_viewbox_valid
	viewbox_edit_w.editable = is_viewbox_valid
	viewbox_edit_h.editable = is_viewbox_valid


func _on_width_edit_value_changed(new_value: float) -> void:
	if is_finite(new_value) and root_tag.get_attribute("width").get_num() != new_value:
		root_tag.width = new_value
		root_tag.set_attribute("width", new_value)
	else:
		root_tag.set_attribute("width", root_tag.width, false)

func _on_height_edit_value_changed(new_value: float) -> void:
	if is_finite(new_value) and root_tag.get_attribute("height").get_num() != new_value:
		root_tag.height = new_value
		root_tag.set_attribute("height", new_value)
	else:
		root_tag.set_attribute("height", root_tag.height, false)

func _on_viewbox_edit_x_value_changed(new_value: float) -> void:
	if root_tag.attributes.has("viewBox"):
		root_tag.viewbox.position.x = new_value
		root_tag.get_attribute("viewBox").set_list_element(0, new_value)

func _on_viewbox_edit_y_value_changed(new_value: float) -> void:
	if root_tag.attributes.has("viewBox"):
		root_tag.viewbox.position.y = new_value
		root_tag.get_attribute("viewBox").set_list_element(1, new_value)

func _on_viewbox_edit_w_value_changed(new_value: float) -> void:
	if root_tag.attributes.has("viewBox") and\
	root_tag.get_attribute("viewBox").get_list_element(2) != new_value:
		root_tag.viewbox.size.x = new_value
		root_tag.get_attribute("viewBox").set_list_element(2, new_value)

func _on_viewbox_edit_h_value_changed(new_value: float) -> void:
	if root_tag.attributes.has("viewBox") and\
	root_tag.get_attribute("viewBox").get_list_element(3) != new_value:
		root_tag.viewbox.size.y = new_value
		root_tag.get_attribute("viewBox").set_list_element(3, new_value)

func _on_width_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		root_tag.set_attribute("width", root_tag.width)
	else:
		if root_tag.get_attribute("viewBox").get_list_size() == 4:
			root_tag.set_attribute("width", NAN)
		else:
			width_button.set_pressed_no_signal(true)

func _on_height_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		root_tag.set_attribute("height", root_tag.height)
	else:
		if root_tag.get_attribute("viewBox").get_list_size() == 4:
			root_tag.set_attribute("height", NAN)
		else:
			height_button.set_pressed_no_signal(true)

func _on_viewbox_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		root_tag.set_attribute("viewBox", root_tag.viewbox)
	else:
		if not root_tag.attributes.has("width") and not root_tag.attributes.has("height"):
			root_tag.get_attribute_mutable("viewBox").set_value("")
		else:
			viewbox_button.set_pressed_no_signal(true)
