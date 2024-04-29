# An editor to be tied to a color attribute.
extends HBoxContainer

signal focused
var attribute: AttributeColor

const ColorPopup = preload("res://src/ui_elements/color_popup.tscn")
const checkerboard = preload("res://visual/icons/backgrounds/ColorButtonBG.svg")

@onready var color_button: Button = $Button
@onready var color_edit: BetterLineEdit = $LineEdit
@onready var color_popup: Control

var ci := get_canvas_item()

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR) -> void:
	if not new_value.is_empty():
		# Validate the value.
		if not is_valid(new_value):
			sync(attribute.get_value())
			return
	new_value = ColorParser.add_hash_if_hex(new_value)
	sync(attribute.autoformat(new_value))
	
	# Update the attribute.
	if attribute.get_value() != new_value or update_type == Utils.UpdateType.FINAL:
		match update_type:
			Utils.UpdateType.INTERMEDIATE:
				attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
			Utils.UpdateType.FINAL:
				attribute.set_value(new_value, Attribute.SyncMode.FINAL)
			_:
				attribute.set_value(new_value)


func _ready() -> void:
	set_value(attribute.get_value())
	color_edit.tooltip_text = attribute.name
	color_edit.placeholder_text = attribute.get_default()
	color_button.resized.connect(queue_redraw)
	attribute.value_changed.connect(set_value)
	color_edit.text_submitted.connect(set_value)


func _on_button_pressed() -> void:
	color_popup = ColorPopup.instantiate()
	color_popup.current_value = attribute.get_value()
	color_popup.color_picked.connect(_on_color_picked)
	HandlerGUI.popup_under_rect(color_popup, color_edit.get_global_rect(), get_viewport())

func _draw() -> void:
	var button_size := color_button.get_size()
	var line_edit_size := color_edit.get_size()
	draw_set_transform(Vector2(line_edit_size.x, 1))
	var stylebox := StyleBoxFlat.new()
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.bg_color = attribute.get_color()
	checkerboard.draw(ci, Vector2.ZERO)
	stylebox.draw(ci, Rect2(Vector2.ZERO, button_size - Vector2(1, 2)))


func _on_focus_entered() -> void:
	color_edit.remove_theme_color_override("font_color")
	focused.emit()

func _on_text_change_canceled() -> void:
	sync(attribute.get_value())


func _on_color_picked(new_color: String, close_picker: bool) -> void:
	if close_picker:
		color_popup.queue_free()
		set_value(new_color, Utils.UpdateType.FINAL)
	else:
		set_value(new_color, Utils.UpdateType.INTERMEDIATE)

func is_valid(text: String) -> bool:
	return ColorParser.is_valid(ColorParser.add_hash_if_hex(text))


func _on_text_changed(new_text: String) -> void:
	color_edit.add_theme_color_override("font_color",
			GlobalSettings.get_validity_color(!is_valid(new_text)))

func sync(new_value: String) -> void:
	if color_edit != null:
		color_edit.remove_theme_color_override("font_color")
		if new_value == attribute.get_default():
			color_edit.add_theme_color_override("font_color", GlobalSettings.basic_color_warning)
		color_edit.text = new_value.trim_prefix("#")
	queue_redraw()

func _notification(what: int) -> void:
	if what == Utils.CustomNotification.BASIC_COLORS_CHANGED:
		sync(color_edit.text)


func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and\
	event.is_pressed():
		accept_event()
		Utils.throw_mouse_motion_event(get_viewport())
	else:
		color_button.mouse_filter = Utils.mouse_filter_pass_non_drag_events(event)
