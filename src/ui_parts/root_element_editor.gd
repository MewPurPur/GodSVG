extends VBoxContainer

const NumberEdit = preload("res://src/ui_widgets/number_edit.gd")

# So, about this editor. Width and height don't have default values, so they use NAN and
# use NumberEdit, rather than NumberField. Viewbox is a list and it also doesn't have a
# default value, so it uses 4 NumberEdits.

@onready var width_button: BetterButton = %Size/Width/WidthButton
@onready var height_button: BetterButton = %Size/Height/HeightButton
@onready var viewbox_button: BetterButton = %Viewbox/ViewboxButton
@onready var width_edit: NumberEdit = %Size/Width/WidthEdit
@onready var height_edit: NumberEdit = %Size/Height/HeightEdit
@onready var viewbox_edit_x: NumberEdit = %Viewbox/Rect/ViewboxEditX
@onready var viewbox_edit_y: NumberEdit = %Viewbox/Rect/ViewboxEditY
@onready var viewbox_edit_w: NumberEdit = %Viewbox/Rect/ViewboxEditW
@onready var viewbox_edit_h: NumberEdit = %Viewbox/Rect/ViewboxEditH
@onready var unknown_container: MarginContainer

func _ready() -> void:
	State.any_attribute_changed.connect(_on_any_attribute_changed)
	State.svg_unknown_change.connect(update_attributes)
	update_attributes()
	width_edit.value_changed.connect(_on_width_edit_value_changed)
	height_edit.value_changed.connect(_on_height_edit_value_changed)
	viewbox_edit_x.value_changed.connect(_on_viewbox_edit_x_value_changed)
	viewbox_edit_y.value_changed.connect(_on_viewbox_edit_y_value_changed)
	viewbox_edit_w.value_changed.connect(_on_viewbox_edit_w_value_changed)
	viewbox_edit_h.value_changed.connect(_on_viewbox_edit_h_value_changed)
	width_button.toggled.connect(_on_width_button_toggled)
	height_button.toggled.connect(_on_height_button_toggled)
	viewbox_button.toggled.connect(_on_viewbox_button_toggled)
	
	for control: Control in [width_edit, height_edit,
	viewbox_edit_x, viewbox_edit_y, viewbox_edit_w, viewbox_edit_h]:
		control.focus_entered.connect(State.clear_all_selections)
	
	for button: Button in [width_button, height_button, viewbox_button]:
		button.pressed.connect(State.clear_all_selections)

func _on_any_attribute_changed(xid: PackedInt32Array) -> void:
	if xid.is_empty():
		update_editable()


func update_attributes() -> void:
	# If there are unknown attributes, they would always be on top.
	if is_instance_valid(unknown_container):
		for child in unknown_container.get_children():
			child.queue_free()
	var has_unrecognized_attributes := false
	for attribute in State.root_element.get_all_attributes():
		# TODO separate unrecognized attributes from global defaults.
		if not attribute.name in ["width", "height", "viewBox", "xmlns"]:
			if not has_unrecognized_attributes:
				has_unrecognized_attributes = true
				if is_instance_valid(unknown_container):
					unknown_container.queue_free()
				unknown_container = MarginContainer.new()
				unknown_container.begin_bulk_theme_override()
				unknown_container.add_theme_constant_override("margin_left", 4)
				unknown_container.add_theme_constant_override("margin_right", 4)
				unknown_container.end_bulk_theme_override()
				var unknown_container_child := HFlowContainer.new()
				unknown_container.add_child(unknown_container_child)
				add_child(unknown_container)
				move_child(unknown_container, 0)
			
			var input_field := AttributeFieldBuilder.create(attribute.name, State.root_element)
			input_field.focus_entered.connect(State.clear_all_selections)
			unknown_container.get_child(0).add_child(input_field)
	if not has_unrecognized_attributes and is_instance_valid(unknown_container):
		unknown_container.queue_free()
	update_editable()


func update_editable() -> void:
	width_edit.set_value(State.root_element.width, false)
	height_edit.set_value(State.root_element.height, false)
	viewbox_edit_x.set_value(State.root_element.viewbox.position.x, false)
	viewbox_edit_y.set_value(State.root_element.viewbox.position.y, false)
	viewbox_edit_w.set_value(State.root_element.viewbox.size.x, false)
	viewbox_edit_h.set_value(State.root_element.viewbox.size.y, false)
	
	var is_width_valid := State.root_element.has_attribute("width")
	var is_height_valid := State.root_element.has_attribute("height")
	var is_viewbox_valid: bool = State.root_element.has_attribute("viewBox") and\
			State.root_element.get_attribute("viewBox").get_list_size() >= 4
	
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
	if is_finite(new_value) and State.root_element.get_attribute_num("width") != new_value:
		State.root_element.width = new_value
		State.root_element.set_attribute("width", new_value)
	else:
		State.root_element.set_attribute("width", State.root_element.width)
	State.queue_svg_save()

func _on_height_edit_value_changed(new_value: float) -> void:
	if is_finite(new_value) and State.root_element.get_attribute_num("height") != new_value:
		State.root_element.height = new_value
		State.root_element.set_attribute("height", new_value)
	else:
		State.root_element.set_attribute("height", State.root_element.height)
	State.queue_svg_save()

func _on_viewbox_edit_x_value_changed(new_value: float) -> void:
	if State.root_element.has_attribute("viewBox"):
		State.root_element.viewbox.position.x = new_value
		State.root_element.get_attribute("viewBox").set_list_element(0, new_value)
		State.queue_svg_save()

func _on_viewbox_edit_y_value_changed(new_value: float) -> void:
	if State.root_element.has_attribute("viewBox"):
		State.root_element.viewbox.position.y = new_value
		State.root_element.get_attribute("viewBox").set_list_element(1, new_value)
		State.queue_svg_save()

func _on_viewbox_edit_w_value_changed(new_value: float) -> void:
	if State.root_element.has_attribute("viewBox") and\
	State.root_element.get_attribute("viewBox").get_list_element(2) != new_value:
		State.root_element.viewbox.size.x = new_value
		State.root_element.get_attribute("viewBox").set_list_element(2, new_value)
		State.queue_svg_save()

func _on_viewbox_edit_h_value_changed(new_value: float) -> void:
	if State.root_element.has_attribute("viewBox") and\
	State.root_element.get_attribute("viewBox").get_list_element(3) != new_value:
		State.root_element.viewbox.size.y = new_value
		State.root_element.get_attribute("viewBox").set_list_element(3, new_value)
		State.queue_svg_save()

func _on_width_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		State.root_element.set_attribute("width", State.root_element.width)
		State.queue_svg_save()
	else:
		if State.root_element.get_attribute("viewBox").get_list_size() == 4:
			State.root_element.set_attribute("width", "")
			State.queue_svg_save()
		else:
			width_button.set_pressed_no_signal(true)

func _on_height_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		State.root_element.set_attribute("height", State.root_element.height)
		State.queue_svg_save()
	else:
		if State.root_element.get_attribute("viewBox").get_list_size() == 4:
			State.root_element.set_attribute("height", "")
			State.queue_svg_save()
		else:
			height_button.set_pressed_no_signal(true)

func _on_viewbox_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		State.root_element.set_attribute("viewBox",
				ListParser.rect_to_list(State.root_element.viewbox))
		State.queue_svg_save()
	else:
		if State.root_element.has_attribute("width") and\
		State.root_element.has_attribute("height"):
			State.root_element.set_attribute("viewBox", "")
			State.queue_svg_save()
		else:
			viewbox_button.set_pressed_no_signal(true)
