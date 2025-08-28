@icon("res://godot_only/icons/LineEditButton.svg")
class_name LineEditButton extends Control
## An optimized control representing a LineEdit with a button attached to it.

# A fake-out is drawn to avoid adding unnecessary nodes.
# The real controls are only created when necessary, such as when hovered or focused.

signal pressed
signal text_change_canceled
signal text_changed
signal text_submitted
signal button_gui_input(event: InputEvent)

var _should_stay_active_outside := false
var _is_mouse_outside := true

var active := false
var temp_line_edit: BetterLineEdit
var temp_button: Button

@export var placeholder_text: String:
	set(new_value):
		if placeholder_text != new_value:
			placeholder_text = new_value
			if active:
				temp_line_edit.placeholder_text = new_value
			else:
				queue_redraw()

@export var text: String:
	set(new_value):
		# No early equivalence check because of a certain potential situation.
		# For example, if you start with empty text and enter a value, but it's dismissed,
		# the text would revert back to empty. There should be an update in that case.
		var old_value := text
		text = new_value
		if active:
			temp_line_edit.text = new_value
		else:
			queue_redraw()
			if text != old_value:
				text_changed.emit(text)

@export var font_color := Color.TRANSPARENT:
	set(new_value):
		if font_color != new_value:
			font_color = new_value
			if active:
				temp_line_edit.add_theme_color_override("font_color", _get_font_color())
			else:
				queue_redraw()

@export var use_mono_font := true:
	set(new_value):
		if use_mono_font != new_value:
			use_mono_font = new_value
			if active:
				temp_line_edit.add_theme_font_override("font", _get_font())
			else:
				queue_redraw()

@export var icon: Texture2D
@export var button_visuals := true
@export var mono_font_tooltip := false
@export var button_width := 14.0:
	set(new_value):
		if not is_equal_approx(new_value, button_width):
			button_width = new_value
			queue_redraw()

var ci := get_canvas_item()


func reset_font_color() -> void:
	font_color = Color.TRANSPARENT  # This is the value treated as invalid.


func _init() -> void:
	custom_minimum_size.y = 22
	set_anchors_and_offsets_preset(PRESET_TOP_LEFT)
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_entered.connect(_on_base_class_focus_entered)
	mouse_entered.connect(_on_base_class_mouse_entered)
	mouse_exited.connect(_on_base_class_mouse_exited)

func _on_base_class_mouse_entered() -> void:
	_is_mouse_outside = false
	_setup()

func _on_base_class_focus_entered() -> void:
	_setup()

func _on_base_class_mouse_exited() -> void:
	_is_mouse_outside = true
	if not _should_stay_active_outside:
		_setdown()

func _on_underlying_control_focused() -> void:
	_should_stay_active_outside = true
	focus_entered.emit()

func _on_underlying_control_unfocused() -> void:
	_should_stay_active_outside = false
	if _is_mouse_outside:
		_setdown()

func _setup() -> void:
	if active:
		return
	active = true
	temp_line_edit = BetterLineEdit.new()
	temp_line_edit.size = Vector2(size.x - button_width, 22)
	temp_line_edit.tooltip_text = tooltip_text
	temp_line_edit.mono_font_tooltip = mono_font_tooltip
	temp_line_edit.placeholder_text = placeholder_text
	temp_line_edit.text = text
	temp_line_edit.mouse_filter = Control.MOUSE_FILTER_PASS
	temp_line_edit.theme_type_variation = "RightConnectedLineEdit"
	if font_color != Color.TRANSPARENT:
		temp_line_edit.add_theme_color_override("font_color", _get_font_color())
	temp_line_edit.add_theme_font_override("font", _get_font())
	temp_line_edit.text_change_canceled.connect(text_change_canceled.emit)
	temp_line_edit.text_changed.connect(text_changed.emit)
	temp_line_edit.text_submitted.connect(text_submitted.emit)
	temp_line_edit.focus_entered.connect(_on_underlying_control_focused)
	temp_line_edit.focus_exited.connect(_on_underlying_control_unfocused)
	add_child(temp_line_edit)
	temp_button = Button.new()
	temp_button.show_behind_parent = true  # Lets the icon draw in front.
	temp_button.custom_minimum_size = Vector2(button_width, 22)
	temp_button.position.x = size.x - button_width
	temp_button.focus_mode = Control.FOCUS_NONE
	temp_button.mouse_filter = Control.MOUSE_FILTER_PASS
	temp_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if button_visuals:
		temp_button.theme_type_variation = "LeftConnectedButton"
	else:
		temp_button.flat = true
	temp_button.pressed.connect(pressed.emit)
	temp_button.gui_input.connect(button_gui_input.emit)
	temp_button.button_down.connect(_on_underlying_control_focused)
	temp_button.button_up.connect(_on_underlying_control_unfocused)
	add_child(temp_button)
	queue_redraw()
	# If there aren't button visuals, then they are probably
	# handed off to draw functions which need to be aware of the hover state.
	if not button_visuals:
		temp_button.mouse_exited.connect(queue_redraw)
		temp_line_edit.mouse_exited.connect(queue_redraw)

# Opposite of setup.
func _setdown() -> void:
	if active:
		active = false
		temp_line_edit.queue_free()
		temp_button.queue_free()
		queue_redraw()


func _draw() -> void:
	var sb: StyleBoxFlat = get_theme_stylebox("normal", "LineEdit")
	var horizontal_margin_width := sb.content_margin_left + sb.content_margin_right
	if not active:
		sb.draw(ci, Rect2(Vector2.ZERO, size))
		draw_line(Vector2(size.x - button_width, 0), Vector2(size.x - button_width, size.y), sb.border_color, 2)
		# The default overrun behavior couldn't be changed for the simplest draw methods.
		var text_obj := TextLine.new()
		text_obj.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
		text_obj.width = size.x - button_width - horizontal_margin_width
		text_obj.add_string(placeholder_text if text.is_empty() else text, _get_font(), get_theme_font_size("font_size", "LineEdit"))
		text_obj.draw(ci, Vector2(5, 2), get_theme_color("font_placeholder_color", "LineEdit") if text.is_empty() else _get_font_color())
	
	if is_instance_valid(icon):
		var icon_side := button_width - horizontal_margin_width + 2
		icon.draw_rect(ci, Rect2(size.x - (button_width + 0.5 + icon_side) / 2, (size.y - icon_side) / 2,
				icon_side, icon_side), false, get_theme_color("icon_normal_color", "LeftConnectedButton"))


# Helpers

func _get_font() -> Font:
	return ThemeUtils.mono_font if use_mono_font else ThemeUtils.regular_font

func _get_font_color() -> Color:
	return get_theme_color("font_color", "LineEdit") if font_color == Color.TRANSPARENT else font_color

func draw_button_border(theme_name: String) -> void:
	var button_outline: StyleBoxFlat = get_theme_stylebox(theme_name, "LeftConnectedButton").duplicate()
	button_outline.draw_center = false
	button_outline.draw(ci, Rect2(size.x - button_width, 0, button_width, size.y))
