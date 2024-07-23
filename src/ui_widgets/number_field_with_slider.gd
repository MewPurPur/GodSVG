# An editor to be tied to a numeric attribute, plus a slider widget.
extends LineEditButton

var element: Element
var attribute_name: String  # May propagate.

var slider_step := 0.01
var min_value := 0.0
var max_value := 1.0
var allow_lower := true
var allow_higher := true

func set_value(new_value: String, save := false) -> void:
	if not new_value.is_empty():
		new_value = new_value.strip_edges()
		if not new_value.ends_with("%"):
			var numeric_value := NumberParser.evaluate(new_value)
			# Validate the value.
			if !is_finite(numeric_value):
				sync(element.get_attribute_value(attribute_name))
				return
			
			if not allow_higher and numeric_value > max_value:
				numeric_value = max_value
				new_value = NumberParser.num_to_text(numeric_value)
			elif not allow_lower and numeric_value < min_value:
				numeric_value = min_value
				new_value = NumberParser.num_to_text(numeric_value)
			
			new_value = NumberParser.num_to_text(numeric_value)
		sync(element.get_attribute(attribute_name).format(new_value))
	
	sync(element.get_attribute(attribute_name).format(new_value))
	element.set_attribute(attribute_name, new_value)
	if save:
		SVG.queue_save()

func set_num(new_number: float, save := false) -> void:
	set_value(NumberParser.num_to_text(new_number), save)

func setup_placeholder() -> void:
	placeholder_text = element.get_default(attribute_name)


func _ready() -> void:
	GlobalSettings.basic_colors_changed.connect(resync)
	set_value(element.get_attribute_value(attribute_name, true))
	element.attribute_changed.connect(_on_element_attribute_changed)
	if attribute_name in DB.propagated_attributes:
		element.ancestor_attribute_changed.connect(_on_element_ancestor_attribute_changed)
	text_submitted.connect(set_value.bind(true))
	focus_entered.connect(reset_font_color)
	tooltip_text = attribute_name
	setup_placeholder()


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		set_value(element.get_attribute_value(attribute_name, true))

func _on_element_ancestor_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		setup_placeholder()

func _on_text_change_canceled() -> void:
	set_value(element.get_attribute_value(attribute_name))

func resync() -> void:
	sync(text)

func sync(new_value: String) -> void:
	text = new_value
	reset_font_color()
	if new_value == element.get_default(attribute_name):
		font_color = GlobalSettings.basic_color_warning
	queue_redraw()


# Slider

var initial_slider_value: float
var slider_dragged := false:
	set(new_value):
		if slider_dragged != new_value:
			slider_dragged = new_value
			queue_redraw()
			if not slider_hovered:
				get_viewport().update_mouse_cursor_state()
				# FIXME workaround because "button_pressed" remains true
				# if you unclick while outside of the area, for some reason.
				# Couldn't replicate this in a minimal project.
				remove_child(temp_button)
				add_child(temp_button)

var slider_hovered := false:
	set(new_value):
		if slider_hovered != new_value:
			slider_hovered = new_value
			queue_redraw()

func _draw() -> void:
	super()
	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.bg_color = get_theme_stylebox("normal", "LineEdit").bg_color
	stylebox.draw(ci, Rect2(get_size().x - BUTTON_WIDTH,
			1, BUTTON_WIDTH - 2, get_size().y - 2))
	var fill_height: float = (get_size().y - 4) *\
			(element.get_attribute_num(attribute_name) - min_value) / max_value
	# Create a stylebox that'll occupy the exact amount of space.
	var fill_stylebox := StyleBoxFlat.new()
	fill_stylebox.bg_color = Color("#def")
	if not slider_dragged and slider_hovered:
		fill_stylebox.bg_color.a = 0.75
	elif not slider_hovered:
		fill_stylebox.bg_color.a = 0.5
	fill_stylebox.draw(ci, Rect2(get_size().x - BUTTON_WIDTH,
			get_size().y - 2 - fill_height, BUTTON_WIDTH - 2, fill_height))
	if slider_dragged:
		draw_button_border("pressed")
	elif slider_hovered:
		draw_button_border("hover")
	else:
		draw_button_border("normal")

func _on_slider_gui_input(event: InputEvent) -> void:
	if not temp_button.mouse_exited.is_connected(_on_slider_mouse_exited):
		temp_button.mouse_exited.connect(_on_slider_mouse_exited)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and\
	event.is_pressed():
		accept_event()
		Utils.throw_mouse_motion_event(get_viewport())
	else:
		temp_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
	
	if not slider_dragged:
		if event is InputEventMouseMotion and event.button_mask == 0:
			slider_hovered = true
		if Utils.is_event_drag_start(event):
			slider_dragged = true
			initial_slider_value = element.get_attribute_num(attribute_name)
			set_num(get_slider_value_at_y(event.position.y))
	else:
		if Utils.is_event_drag(event):
			set_num(get_slider_value_at_y(event.position.y))
		elif Utils.is_event_drag_end(event):
			slider_dragged = false
			var final_slider_value := get_slider_value_at_y(event.position.y)
			if initial_slider_value != final_slider_value:
				set_num(final_slider_value, true)

func _unhandled_input(event: InputEvent) -> void:
	if slider_dragged and Utils.is_event_drag_cancel(event):
		slider_dragged = false
		set_num(initial_slider_value)
		accept_event()

func get_slider_value_at_y(y_coord: float) -> float:
	return snappedf(lerpf(max_value, min_value,
			(y_coord - 4) / (temp_button.get_size().y - 4)), slider_step)

func _on_slider_mouse_exited() -> void:
	slider_hovered = false
