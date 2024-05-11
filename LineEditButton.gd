class_name LineEditButton extends Control
## An optimized control representing a LineEdit with a button attached to it.

# A fake-out is drawn to avoid adding unnecessary nodes.
# The real controls are only created when necessary, such as when hovered or focused.

const BUTTON_WIDTH = 15.0

signal pressed
signal text_change_canceled
signal text_changed
signal text_submitted
signal button_gui_input

var _should_stay_active_outside := false
var _is_mouse_outside := true
var _active := false

var temp_line_edit: BetterLineEdit
var temp_button: Button

@export var placeholder_text: String:
	set(new_value):
		if placeholder_text != new_value:
			placeholder_text = new_value
			if not _active and text.is_empty():
				queue_redraw()

@export var text: String:
	set(new_value):
		if text != new_value:
			text = new_value
			if not _active and not text.is_empty():
				queue_redraw()

@export var font_color := Color.TRANSPARENT:
	set(new_value):
		if font_color != new_value:
			font_color = new_value
			if _active:
				temp_line_edit.add_theme_color_override("font_color", _get_font_color())
			else:
				queue_redraw()

@export var icon: Texture2D

var ci := get_canvas_item()


func reset_font_color() -> void:
	font_color = Color.TRANSPARENT  # This is the value treated as invalid.


func _init() -> void:
	custom_minimum_size.y = 22
	set_anchors_and_offsets_preset(PRESET_TOP_LEFT)
	focus_mode = Control.FOCUS_ALL
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

func _on_underlying_control_unfocused() -> void:
	_should_stay_active_outside = false
	if _is_mouse_outside:
		_setdown()

func _setup() -> void:
	if not _active:
		_active = true
		temp_line_edit = BetterLineEdit.new()
		temp_line_edit.custom_minimum_size =\
				Vector2(custom_minimum_size.x - BUTTON_WIDTH, 22)
		temp_line_edit.tooltip_text = tooltip_text
		temp_line_edit.placeholder_text = placeholder_text
		temp_line_edit.text = text
		temp_line_edit.focus_mode = Control.FOCUS_CLICK
		temp_line_edit.mouse_filter = Control.MOUSE_FILTER_PASS
		temp_line_edit.theme_type_variation = "RightConnectedLineEdit"
		if font_color != Color.TRANSPARENT:
			temp_line_edit.add_theme_color_override("font_color", _get_font_color())
		temp_line_edit.text_change_canceled.connect(emit_text_change_canceled)
		temp_line_edit.text_changed.connect(emit_text_changed)
		temp_line_edit.text_submitted.connect(emit_text_submitted)
		temp_line_edit.focus_entered.connect(_on_underlying_control_focused)
		temp_line_edit.focus_exited.connect(_on_underlying_control_unfocused)
		add_child(temp_line_edit)
		temp_button = Button.new()
		temp_button.show_behind_parent = true  # Lets the icon draw in front.
		temp_button.custom_minimum_size = Vector2(BUTTON_WIDTH, 22)
		temp_button.position.x = size.x - BUTTON_WIDTH
		temp_button.focus_mode = Control.FOCUS_NONE
		temp_button.mouse_filter = Control.MOUSE_FILTER_PASS
		temp_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		temp_button.theme_type_variation = "LeftConnectedButton"
		temp_button.pressed.connect(emit_pressed)
		temp_button.button_down.connect(_on_underlying_control_focused)
		temp_button.button_up.connect(_on_underlying_control_unfocused)
		add_child(temp_button)
		queue_redraw()

func _setdown() -> void:
	if _active:
		_active = false
		temp_line_edit.queue_free()
		temp_button.queue_free()
		queue_redraw()


func _draw() -> void:
	var sb: StyleBoxFlat = get_theme_stylebox("normal", "LineEdit")
	if not _active:
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		draw_line(Vector2(size.x - BUTTON_WIDTH, 0),
				Vector2(size.x - BUTTON_WIDTH, size.y), sb.border_color, 2)
		var drawn_text := placeholder_text if text.is_empty() else text
		var drawn_color := get_theme_color("font_placeholder_color", "LineEdit") if\
				text.is_empty() else _get_font_color()
		get_theme_font("font", "LineEdit").draw_string(ci, Vector2(5, BUTTON_WIDTH),
				drawn_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				get_theme_font_size("font_size", "LineEdit"), drawn_color)
	
	if icon != null:
		var icon_side := BUTTON_WIDTH + 1 - sb.content_margin_left - sb.content_margin_right
		icon.draw_rect(ci, Rect2(size.x - (BUTTON_WIDTH + 1 + icon_side) / 2,
				(size.y - icon_side) / 2, icon_side, icon_side), false)


func emit_pressed() -> void:
	pressed.emit()

func emit_text_change_canceled() -> void:
	text_change_canceled.emit()

func emit_text_changed(new_text: String) -> void:
	text_changed.emit(new_text)

func emit_text_submitted(new_text: String) -> void:
	text_submitted.emit(new_text)

func emit_button_gui_input() -> void:
	button_gui_input.emit()

func emit_focus_entered() -> void:
	focus_entered.emit()


# Helpers

func _get_font_color() -> Color:
	return get_theme_color("font_color", "LineEdit") if font_color == Color.TRANSPARENT\
			else font_color
