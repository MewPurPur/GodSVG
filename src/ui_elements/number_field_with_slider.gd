## An editor to be tied to a numeric attribute, plus a slider widget.
extends HBoxContainer

signal focused
var attribute: AttributeNumeric
var attribute_name: String

@onready var num_edit: LineEdit = $LineEdit
@onready var slider: Button = $Slider

var slider_step := 0.01
var min_value := 0.0
var max_value := 1.0
var allow_lower := true
var allow_higher := true

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR) -> void:
	var numeric_value := AttributeNumeric.evaluate_expr(new_value)
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
	
	# Just because the value passed was +1 or 1.0 instead of the default 1,
	# shouldn't cause the attribute to be added to the SVG text.
	if attribute.default == NumberParser.num_to_text(numeric_value):
		new_value = attribute.default
	elif NumberParser.text_to_num(new_value) != AttributeNumeric.evaluate_expr(new_value):
		new_value = NumberParser.num_to_text(numeric_value)
	
	sync(attribute.autoformat(new_value))
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
	num_edit.tooltip_text = attribute_name

func _on_focus_exited() -> void:
	set_value(num_edit.text)

func _on_focus_entered() -> void:
	focused.emit()

func _on_text_submitted(submitted_text: String) -> void:
	set_value(submitted_text)

func sync(new_value: String) -> void:
	if num_edit != null:
		num_edit.text = new_value
		if new_value == attribute.default:
			num_edit.add_theme_color_override(&"font_color", Color(0.64, 0.64, 0.64))
		else:
			num_edit.remove_theme_color_override(&"font_color")
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

var slider_hovered := false:
	set(new_value):
		if slider_hovered != new_value:
			slider_hovered = new_value
			queue_redraw()

func _draw() -> void:
	var slider_size := slider.get_size()
	var line_edit_size := num_edit.get_size()
	draw_set_transform(Vector2(line_edit_size.x, 1))
	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.bg_color = num_edit.get_theme_stylebox(&"normal", &"LineEdit").bg_color
	draw_style_box(stylebox, Rect2(Vector2.ZERO, slider_size - Vector2(1, 2)))
	var fill_height := (slider_size.y - 4) * (attribute.get_num() - min_value) / max_value
	if slider_dragged:
		draw_rect(Rect2(0, 1 + slider_size.y - 4 - fill_height,
				slider_size.x - 2, fill_height), Color("#def"))
	elif slider_hovered:
		draw_rect(Rect2(0, 1 + slider_size.y - 4 - fill_height,
				slider_size.x - 2, fill_height), Color("#defb"))
	else:
		draw_rect(Rect2(0, 1 + slider_size.y - 4 - fill_height,
				slider_size.x - 2, fill_height), Color("#def8"))

func _on_slider_resized() -> void:
	queue_redraw()  # Whyyyyy are their sizes wrong at first...

func _on_slider_gui_input(event: InputEvent) -> void:
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

func get_slider_value_at_y(y_coord: float) -> float:
	return snappedf(lerpf(max_value, min_value,
			(y_coord - 4) / (slider.get_size().y - 4)), slider_step)

func _on_slider_mouse_exited() -> void:
	slider_hovered = false
