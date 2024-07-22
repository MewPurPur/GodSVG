# An editor to be tied to a color attribute.
extends LineEditButton

var element: Element
var attribute_name: String  # May propagate.

const ColorPopup = preload("res://src/ui_elements/color_popup.tscn")
const checkerboard = preload("res://visual/icons/backgrounds/ColorButtonBG.svg")

@onready var color_popup: Control

var gradient_texture: GradientTexture2D

func set_value(new_value: String, save := false) -> void:
	if not new_value.is_empty():
		# Validate the value.
		if not is_valid(new_value):
			sync(element.get_attribute_value(attribute_name))
			return
	new_value = ColorParser.add_hash_if_hex(new_value)
	sync(element.get_attribute(attribute_name).format(new_value))
	element.set_attribute(attribute_name, new_value)
	if save:
		SVG.queue_save()

func setup_placeholder() -> void:
	placeholder_text = element.get_default(attribute_name).trim_prefix("#")


func _ready() -> void:
	set_value(element.get_attribute_value(attribute_name, true))
	element.attribute_changed.connect(_on_element_attribute_changed)
	if attribute_name in DB.propagated_attributes:
		element.ancestor_attribute_changed.connect(_on_element_ancestor_attribute_changed)
	text_submitted.connect(set_value.bind(true))
	focus_entered.connect(reset_font_color)
	SVG.text_changed.connect(_on_svg_text_changed)
	tooltip_text = attribute_name
	setup_placeholder()


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		set_value(element.get_attribute_value(attribute_name, true))

func _on_element_ancestor_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		setup_placeholder()

# Redraw in case the gradient might have changed.
func _on_svg_text_changed() -> void:
	if ColorParser.is_valid_url(element.get_attribute_value(attribute_name, false)):
		update_gradient_texture()
		queue_redraw()

func _on_pressed() -> void:
	color_popup = ColorPopup.instantiate()
	color_popup.current_value = element.get_attribute_value(attribute_name)
	color_popup.color_picked.connect(_on_color_picked)
	HandlerGUI.popup_under_rect(color_popup, get_global_rect(), get_viewport())

func _draw() -> void:
	super()
	var h_offset := size.x - BUTTON_WIDTH
	var r := 5
	checkerboard.draw(ci, Vector2(h_offset, 1))
	# Draw the color or gradient.
	var drawn := false
	var color_value := element.get_attribute_value(attribute_name, false)
	if ColorParser.is_valid_url(color_value):
		var id := color_value.substr(5, color_value.length() - 6)
		var gradient_element := SVG.root_element.get_element_by_id(id)
		if gradient_element != null:
			# Complex drawing logic, because StyleBoxTexture isn't advanced enough.
			var points := PackedVector2Array()
			var colors := PackedColorArray()
			var uvs := PackedVector2Array()
			
			var initial_pts := PackedVector2Array([Vector2(0, 1), Vector2(0, size.y - 1)])
			for deg in range(90, -1, -15):
				var rad := deg_to_rad(deg)
				initial_pts.append(Vector2(BUTTON_WIDTH - 1 - r + r * cos(rad),
						size.y - 1 - r + r * sin(rad)))
			for deg in range(0, -91, -15):
				var rad := deg_to_rad(deg)
				initial_pts.append(Vector2(BUTTON_WIDTH - 1 - r + r * cos(rad),
						r + 1 + r * sin(rad)))
			for pt in initial_pts:
				points.append(pt + Vector2(h_offset, 0))
				colors.append(Color.WHITE)
				uvs.append(pt / Vector2(BUTTON_WIDTH - 1, size.y - 1))
			draw_polygon(points, colors, uvs, gradient_texture)
			drawn = true
	
	if not drawn:
		var stylebox := StyleBoxFlat.new()
		stylebox.corner_radius_top_right = r
		stylebox.corner_radius_bottom_right = r
		stylebox.bg_color = ColorParser.text_to_color(color_value)
		stylebox.draw(ci, Rect2(h_offset, 1, BUTTON_WIDTH - 1, size.y - 2))
	# Draw the button border.
	if is_instance_valid(temp_button) and temp_button.button_pressed:
		draw_button_border("pressed")
	elif is_instance_valid(temp_button) and temp_button.get_global_rect().has_point(
	get_viewport().get_mouse_position()):
		draw_button_border("hover")
	else:
		draw_button_border("normal")


func _on_text_change_canceled() -> void:
	sync(element.get_attribute_value(attribute_name))


func _on_color_picked(new_color: String, close_picker: bool) -> void:
	set_value(new_color, close_picker)
	if close_picker:
		color_popup.queue_free()

func is_valid(color_text: String) -> bool:
	return ColorParser.is_valid(ColorParser.add_hash_if_hex(color_text))


func _on_text_changed(new_text: String) -> void:
	font_color = GlobalSettings.get_validity_color(!is_valid(new_text))

func sync(new_value: String) -> void:
	reset_font_color()
	if new_value == element.get_default(attribute_name):
		font_color = GlobalSettings.basic_color_warning
	text = new_value.trim_prefix("#")
	update_gradient_texture()
	queue_redraw()

# TODO remove this method when #94584 is fixed.
func update_gradient_texture() -> void:
	var color_value := element.get_attribute_value(attribute_name, false)
	if ColorParser.is_valid_url(color_value):
		var id := color_value.substr(5, color_value.length() - 6)
		var gradient_element := SVG.root_element.get_element_by_id(id)
		if gradient_element != null:
			gradient_texture = gradient_element.generate_texture()
	else:
		gradient_texture = null

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.BASIC_COLORS_CHANGED:
		sync(text)


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and\
	event.is_pressed():
		accept_event()
		Utils.throw_mouse_motion_event(get_viewport())
	else:
		temp_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
		queue_redraw()
