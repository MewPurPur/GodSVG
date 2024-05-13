# An editor to be tied to a numeric attribute, plus a slider widget.
extends LineEditButton

var attribute: AttributeNumeric

var slider_step := 0.01
var min_value := 0.0
var max_value := 1.0
var allow_lower := true
var allow_higher := true

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR) -> void:
	if not new_value.is_empty():
		var numeric_value := NumberParser.evaluate(new_value)
		# Validate the value.
		if !is_finite(numeric_value):
			sync(attribute.get_value())
			return
		
		if not allow_higher and numeric_value > max_value:
			numeric_value = max_value
			new_value = NumberParser.num_to_text(numeric_value)
		elif not allow_lower and numeric_value < min_value:
			numeric_value = min_value
			new_value = NumberParser.num_to_text(numeric_value)
		
		new_value = NumberParser.num_to_text(numeric_value)
		sync(attribute.format(new_value))
	
	sync(attribute.format(new_value))
	# Update the attribute.
	if new_value != attribute.get_value() or update_type == Utils.UpdateType.FINAL:
		match update_type:
			Utils.UpdateType.INTERMEDIATE:
				attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
			Utils.UpdateType.FINAL:
				attribute.set_value(new_value, Attribute.SyncMode.FINAL)
			_:
				attribute.set_value(new_value)

func set_num(new_number: float, update_type := Utils.UpdateType.REGULAR) -> void:
	set_value(NumberParser.num_to_text(new_number), update_type)


func _ready() -> void:
	set_value(attribute.get_value())
	attribute.value_changed.connect(set_value)
	tooltip_text = attribute.name
	placeholder_text = attribute.get_default()
	text_submitted.connect(set_value)
	focus_entered.connect(reset_font_color)

func _on_text_change_canceled() -> void:
	sync(attribute.get_value())

func sync(new_value: String) -> void:
	text = new_value
	reset_font_color()
	if new_value == attribute.get_default():
		font_color = GlobalSettings.basic_color_warning
	queue_redraw()

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.BASIC_COLORS_CHANGED:
		sync(text)


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
	var fill_height := (get_size().y - 4) * (attribute.get_num() - min_value) / max_value
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
			initial_slider_value = attribute.get_num()
			set_num(get_slider_value_at_y(event.position.y), Utils.UpdateType.INTERMEDIATE)
	else:
		if Utils.is_event_drag(event):
			set_num(get_slider_value_at_y(event.position.y), Utils.UpdateType.INTERMEDIATE)
		elif Utils.is_event_drag_end(event):
			slider_dragged = false
			var final_slider_value := get_slider_value_at_y(event.position.y)
			if initial_slider_value != final_slider_value:
				set_num(final_slider_value, Utils.UpdateType.FINAL)

func _unhandled_input(event: InputEvent) -> void:
	if slider_dragged and Utils.is_event_cancel(event):
		slider_dragged = false
		set_num(initial_slider_value, Utils.UpdateType.INTERMEDIATE)
		accept_event()

func get_slider_value_at_y(y_coord: float) -> float:
	return snappedf(lerpf(max_value, min_value,
			(y_coord - 4) / (temp_button.get_size().y - 4)), slider_step)

func _on_slider_mouse_exited() -> void:
	slider_hovered = false
