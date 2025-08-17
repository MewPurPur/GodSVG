# An editor to be tied to a color attribute.
extends LineEditButton

const ColorFieldPopup = preload("res://src/ui_widgets/color_field_popup.gd")

var element: Element
var attribute_name: String:  # May propagate.
	set(new_value):
		attribute_name = new_value
		cached_allow_url = attribute_name in DB.COLOR_ATTRIBUTES_WITH_URL_ALLOWED
		cached_allow_none = attribute_name in DB.COLOR_ATTRIBUTES_WITH_NONE_ALLOWED
		cached_allow_current_color = attribute_name in DB.COLOR_ATTRIBUTES_WITH_CURRENT_COLOR_ALLOWED

var cached_allow_url: bool
var cached_allow_none: bool
var cached_allow_current_color: bool

const ColorFieldPopupScene = preload("res://src/ui_widgets/color_field_popup.tscn")
const checkerboard = preload("res://assets/icons/CheckerboardColorButton.svg")

var color_popup: ColorFieldPopup
var gradient_texture: SVGTexture

func set_value(new_value: String, save := false) -> void:
	if not new_value.is_empty():
		# Validate the value.
		if not is_valid(new_value):
			sync()
			return
	new_value = ColorParser.add_hash_if_hex(new_value)
	element.set_attribute(attribute_name, new_value)
	sync()
	if save:
		State.queue_svg_save()

func setup_placeholder() -> void:
	placeholder_text = element.get_default(attribute_name).trim_prefix("#")


func _ready() -> void:
	Configs.basic_colors_changed.connect(sync)
	sync()
	element.attribute_changed.connect(_on_element_attribute_changed)
	if attribute_name in DB.PROPAGATED_ATTRIBUTES:
		element.ancestor_attribute_changed.connect(_on_element_ancestor_attribute_changed)
	text_submitted.connect(set_value.bind(true))
	focus_entered.connect(reset_font_color)
	text_changed.connect(_on_text_changed)
	text_change_canceled.connect(sync)
	pressed.connect(_on_pressed)
	button_gui_input.connect(_on_button_gui_input)
	# URLs and currentColor require to always listen for changes to the SVG.
	element.root.any_attribute_changed.connect(_on_svg_changed.unbind(1))
	element.root.xnode_layout_changed.connect(_on_svg_changed)
	tooltip_text = attribute_name
	setup_placeholder()


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync()

func _on_element_ancestor_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		setup_placeholder()
		sync()

# Redraw in case the gradient might have changed.
func _on_svg_changed() -> void:
	if cached_allow_url and ColorParser.is_valid_url(element.get_implied_attribute_value(attribute_name)):
		update_gradient_texture()
		queue_redraw()
	elif element.get_attribute_value(attribute_name) == "currentColor":
		queue_redraw()

func _on_pressed() -> void:
	color_popup = ColorFieldPopupScene.instantiate()
	color_popup.current_value = element.get_attribute_value(attribute_name)
	color_popup.effective_color = ColorParser.text_to_color(
			element.get_attribute_true_color(attribute_name))
	color_popup.show_url = cached_allow_url
	# If it's a color attribute, or there's no color attribute children of this element,
	# mark the current color keyword as uninteresting (won't be shown in palettes).
	if not cached_allow_current_color:
		color_popup.current_color_availability = color_popup.CurrentColorAvailability.UNAVAILABLE
	else:
		var has_color_attribute_parent := false
		for element_depth in range(0, element.xid.size()):
			var checked_xid := element.xid.duplicate()
			checked_xid.resize(element_depth)
			if State.root_element.get_xnode(checked_xid).has_attribute("color"):
				has_color_attribute_parent = true
				break
		color_popup.current_color_availability = color_popup.CurrentColorAvailability.INTERESTING if has_color_attribute_parent\
				else color_popup.CurrentColorAvailability.UNINTERESTING
	color_popup.current_color = element.get_default("color")
	color_popup.is_none_keyword_available = cached_allow_none
	color_popup.color_picked.connect(_on_color_picked)
	HandlerGUI.popup_under_rect(color_popup, get_global_rect(), get_viewport())

func _draw() -> void:
	super()
	var h_offset := size.x - button_width
	var r := 5
	checkerboard.draw(ci, Vector2(h_offset, 1))
	# Draw the color or gradient.
	var drawn := false
	var color_value := element.get_implied_attribute_value(attribute_name)
	if cached_allow_url and ColorParser.is_valid_url(color_value):
		var id := color_value.substr(5, color_value.length() - 6)
		var gradient_element := State.root_element.get_element_by_id(id)
		if is_instance_valid(gradient_element) and gradient_element is ElementBaseGradient:
			# Complex drawing logic, because StyleBoxTexture isn't advanced enough.
			var points := PackedVector2Array()
			var colors := PackedColorArray()
			var uvs := PackedVector2Array()
			
			var initial_pts := PackedVector2Array([Vector2(0, 1), Vector2(0, size.y - 1)])
			for deg in range(90, -1, -15):
				var rad := deg_to_rad(deg)
				initial_pts.append(Vector2(button_width - 1 - r + r * cos(rad),
						size.y - 1 - r + r * sin(rad)))
			for deg in range(0, -91, -15):
				var rad := deg_to_rad(deg)
				initial_pts.append(Vector2(button_width - 1 - r + r * cos(rad),
						r + 1 + r * sin(rad)))
			for pt in initial_pts:
				points.append(pt + Vector2(h_offset, 0))
				colors.append(Color.WHITE)
				uvs.append(pt / Vector2(button_width - 1, size.y - 1))
			RenderingServer.canvas_item_add_polygon(ci, points, colors, uvs, gradient_texture)
			drawn = true
	
	if not drawn:
		var stylebox := StyleBoxFlat.new()
		stylebox.corner_radius_top_right = r
		stylebox.corner_radius_bottom_right = r
		stylebox.bg_color = ColorParser.text_to_color(
				element.get_attribute_true_color(attribute_name), Color.TRANSPARENT)
		stylebox.draw(ci, Rect2(h_offset, 1, button_width - 1, size.y - 2))
	# Draw the button border.
	if is_instance_valid(temp_button) and temp_button.button_pressed:
		draw_button_border("pressed")
	elif is_instance_valid(temp_button) and temp_button.get_global_rect().has_point(get_viewport().get_mouse_position()):
		draw_button_border("hover")
	else:
		draw_button_border("normal")


func _on_color_picked(new_color: String, close_picker: bool) -> void:
	set_value(new_color, close_picker)

func is_valid(color_text: String) -> bool:
	return ColorParser.is_valid(ColorParser.add_hash_if_hex(color_text), false, cached_allow_url, cached_allow_none, cached_allow_current_color)


func _on_text_changed(new_text: String) -> void:
	font_color = Configs.savedata.get_validity_color(not is_valid(new_text))

func sync() -> void:
	var new_value := element.get_attribute_value(attribute_name)
	reset_font_color()
	if ColorParser.add_hash_if_hex(new_value) == element.get_default(attribute_name):
		font_color = Configs.savedata.basic_color_warning
	text = new_value.trim_prefix("#")
	if cached_allow_url:
		update_gradient_texture()
	queue_redraw()

# TODO remove this method when #94584 is fixed.
func update_gradient_texture() -> void:
	var color_value := element.get_implied_attribute_value(attribute_name)
	if ColorParser.is_valid_url(color_value):
		var id := color_value.substr(5, color_value.length() - 6)
		var gradient_element := State.root_element.get_element_by_id(id)
		if is_instance_valid(gradient_element) and gradient_element is ElementBaseGradient:
			gradient_texture = gradient_element.generate_texture()
	else:
		gradient_texture = null

func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		accept_event()
		HandlerGUI.throw_mouse_motion_event()
	else:
		temp_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
		queue_redraw()
