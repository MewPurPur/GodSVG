# An editor to be tied to a color attribute.
extends LineEditButton

var tag: Tag
var attribute_name: String

const ColorPopup = preload("res://src/ui_elements/color_popup.tscn")
const checkerboard = preload("res://visual/icons/backgrounds/ColorButtonBG.svg")

@onready var color_popup: Control

func set_value(new_value: String, save := true) -> void:
	var attribute := tag.get_attribute(attribute_name)
	if not new_value.is_empty():
		# Validate the value.
		if not is_valid(new_value):
			sync(attribute.get_value())
			return
	new_value = ColorParser.add_hash_if_hex(new_value)
	sync(attribute.format(new_value))
	
	# Update the attribute.
	if attribute.get_value() != new_value:
		attribute.set_value(new_value, save)

func setup_default() -> void:
	placeholder_text = tag.get_default(attribute_name)


func _ready() -> void:
	set_value(tag.get_attribute_value(attribute_name, true))
	tag.attribute_changed.connect(_on_tag_attribute_changed)
	if attribute_name in DB.propagated_attributes:
		tag.ancestor_attribute_changed.connect(_on_tag_ancestor_attribute_changed)
	text_submitted.connect(set_value)
	focus_entered.connect(reset_font_color)
	tooltip_text = attribute_name
	setup_default()


func _on_tag_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		set_value(tag.get_attribute_value(attribute_name, true), false)

func _on_tag_ancestor_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		setup_default()

func _on_pressed() -> void:
	color_popup = ColorPopup.instantiate()
	color_popup.current_value = tag.get_attribute(attribute_name).get_value()
	color_popup.color_picked.connect(_on_color_picked)
	HandlerGUI.popup_under_rect(color_popup, get_global_rect(), get_viewport())

func _draw() -> void:
	super()
	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.bg_color = tag.get_attribute(attribute_name).get_color()
	checkerboard.draw(ci, Vector2(size.x - BUTTON_WIDTH, 1))
	stylebox.draw(ci, Rect2(size.x - BUTTON_WIDTH, 1, BUTTON_WIDTH - 1, size.y - 2))
	if is_instance_valid(temp_button) and temp_button.button_pressed:
		draw_button_border("pressed")
	elif is_instance_valid(temp_button) and temp_button.get_global_rect().has_point(
	get_viewport().get_mouse_position()):
		draw_button_border("hover")
	else:
		draw_button_border("normal")


func _on_text_change_canceled() -> void:
	sync(tag.get_attribute(attribute_name).get_value())


func _on_color_picked(new_color: String, close_picker: bool) -> void:
	if close_picker:
		color_popup.queue_free()
		set_value(new_color, true)
	else:
		set_value(new_color, false)

func is_valid(color_text: String) -> bool:
	return ColorParser.is_valid(ColorParser.add_hash_if_hex(color_text))


func _on_text_changed(new_text: String) -> void:
	font_color = GlobalSettings.get_validity_color(!is_valid(new_text))

func sync(new_value: String) -> void:
	reset_font_color()
	if new_value == tag.get_default(attribute_name):
		font_color = GlobalSettings.basic_color_warning
	text = new_value.trim_prefix("#")
	queue_redraw()

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
