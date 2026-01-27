# An editor to be tied to a numeric attribute, plus a slider widget.
extends LineEditButton

var attribute_name: String  # May propagate.

# Could be made to not be constants if needed.
const SLIDER_STEP := 0.01
const MIN_VALUE := 0.0
const MAX_VALUE := 1.0

func set_value(new_value: String, save := false) -> void:
	if not new_value.is_empty():
		if not AttributeNumeric.text_check_percentage(new_value):
			var numeric_value := NumstringParser.evaluate(new_value)
			# Validate the value.
			if not is_finite(numeric_value):
				sync()
				return
			
			numeric_value = clampf(numeric_value, MIN_VALUE, MAX_VALUE)
			new_value = NumberParser.num_to_text(numeric_value, Configs.savedata.editor_formatter)
	
	State.set_selected_attribute(attribute_name, new_value)
	sync()
	if save:
		State.save_svg()

func set_num(new_number: float, save := false) -> void:
	set_value(NumberParser.num_to_text(new_number, Configs.savedata.editor_formatter), save)


func _ready() -> void:
	Configs.basic_colors_changed.connect(sync)
	sync()
	for xid in State.selected_xids:
		var xnode := State.root_element.get_xnode(xid)
		if xnode.is_element():
			xnode.attribute_changed.connect(_on_element_attribute_changed)
	text_submitted.connect(set_value.bind(true))
	focus_entered.connect(reset_font_color)
	text_change_canceled.connect(sync)
	button_gui_input.connect(_on_slider_gui_input)
	tooltip_text = attribute_name
	sync()


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync()

func sync() -> void:
	reset_font_color()
	
	if State.selected_xids.is_empty():
		return
	
	var values := PackedStringArray()
	var defaults := PackedStringArray()
	var has_same_values := true
	var has_same_defaults := true
	
	for xid in State.selected_xids:
		var xnode := State.root_element.get_xnode(xid)
		if not xnode.is_element():
			continue
		
		var element: Element = xnode
		var new_value := element.get_attribute_value(attribute_name)
		var new_default := element.get_default(attribute_name)
		
		if not values.is_empty():
			if has_same_values and not new_value in values:
				has_same_values = false
			if has_same_defaults and not new_default in defaults:
				has_same_defaults = false
		
		values.append(new_value)
		defaults.append(new_default)
	
	text = values[0] if has_same_values else ".."
	placeholder_text = defaults[0] if has_same_defaults else ".."
	if values == defaults:
		font_color = Configs.savedata.basic_color_warning
	
	var tooltip_lines := PackedStringArray()
	for i in values.size():
		var current_value := values[i] if not values[i].is_empty() else Translator.translate("Unset")
		tooltip_lines.append(current_value + " (" + Translator.translate("Default") + ": " + defaults[i] + ")")
	tooltip_text = "\n".join(tooltip_lines)
	
	queue_redraw()


# Slider

var initial_slider_value: String
var slider_dragged := false:
	set(new_value):
		if slider_dragged != new_value:
			slider_dragged = new_value
			queue_redraw()
			if not slider_hovered:
				get_viewport().update_mouse_cursor_state()
				# FIXME workaround because "button_pressed" remains true if you unclick while
				# outside of the area, for some reason. Couldn't replicate this in a minimal project.
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
	stylebox.draw(ci, Rect2(size.x - button_width, 1, button_width - 2, size.y - 2))
	
	# Calculate fill height based on selected elements
	if State.selected_xids.is_empty():
		return
	
	var slider_value := 0.0
	for i in State.selected_xids.size():
		var xid := State.selected_xids[i]
		var xnode := State.root_element.get_xnode(xid)
		if xnode.is_element():
			var element: Element = xnode
			var numeric_value := element.get_attribute_num(attribute_name)
			if i == 0:
				slider_value = numeric_value
			elif numeric_value != slider_value:
				slider_value = 0.0
				break
	var fill_height := (size.y - 4) * (slider_value - MIN_VALUE) / MAX_VALUE
	
	# Create a stylebox that'll occupy the exact amount of space.
	var fill_stylebox := StyleBoxFlat.new()
	fill_stylebox.bg_color = ThemeUtils.tinted_contrast_color
	if not slider_dragged and slider_hovered:
		fill_stylebox.bg_color.a = 0.65
	elif not slider_hovered:
		fill_stylebox.bg_color.a = 0.5
	fill_stylebox.draw(ci, Rect2(size.x - button_width, size.y - 2 - fill_height, button_width - 2, fill_height))
	if slider_dragged:
		draw_button_border("pressed")
	elif slider_hovered:
		draw_button_border("hover")
	else:
		draw_button_border("normal")

func _on_slider_gui_input(event: InputEvent) -> void:
	if not temp_button.mouse_exited.is_connected(_on_slider_mouse_exited):
		temp_button.mouse_exited.connect(_on_slider_mouse_exited)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		accept_event()
		HandlerGUI.throw_mouse_motion_event()
	else:
		temp_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
	
	if event is InputEventMouseMotion and event.button_mask == 0:
		slider_hovered = true
	if not slider_dragged:
		if Utils.is_event_drag_start(event):
			slider_dragged = true
			# Store the initial value (use first element's value or ".." if multiple)
			initial_slider_value = text
			set_num(get_slider_value_at_y(event.position.y))
	else:
		if Utils.is_event_drag(event):
			set_num(get_slider_value_at_y(event.position.y))
		elif Utils.is_event_drag_end(event):
			slider_dragged = false
			var final_slider_value := get_slider_value_at_y(event.position.y)
			var final_text := NumberParser.num_to_text(final_slider_value, Configs.savedata.editor_formatter)
			if initial_slider_value != final_text:
				set_num(final_slider_value, true)

func _unhandled_input(event: InputEvent) -> void:
	if slider_dragged and Utils.is_event_drag_cancel(event):
		slider_dragged = false
		set_value(initial_slider_value)
		accept_event()


func get_slider_value_at_y(y_coord: float) -> float:
	return snappedf(lerpf(MAX_VALUE, MIN_VALUE, (y_coord - 4) / (temp_button.size.y - 4)), SLIDER_STEP)

func _on_slider_mouse_exited() -> void:
	slider_hovered = false
