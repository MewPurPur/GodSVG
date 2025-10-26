# A dropdown with multiple options, not tied to any attribute.
@abstract class_name Dropdown extends Control

const arrow_icon = preload("res://assets/icons/SmallArrowDown.svg")

var ci := get_canvas_item()
var line_edit: BetterLineEdit
var _text: String

@export var editing_enabled := false
@export var align_left := false  # The alignment of the popup options' text.

func set_text(new_text: String) -> void:
	if _text != new_text:
		_text = new_text
		queue_redraw()

func _ready() -> void:
	theme_type_variation = "Dropdown"
	mouse_exited.connect(_on_mouse_exited)

func _draw() -> void:
	var normal_sb: StyleBoxFlat = get_theme_stylebox("normal")
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var spacing := size.y - arrow_icon.get_height()
	var half_spacing := spacing / 2.0
	
	normal_sb.draw(ci, Rect2(Vector2.ZERO, size))
	if get_viewport().gui_get_hovered_control() == self:
		get_theme_stylebox("hover").draw(ci, Rect2(Vector2.ZERO, size))
		arrow_icon.draw(ci, Vector2(size.x - arrow_icon.get_width() - half_spacing, half_spacing))
	else:
		arrow_icon.draw(ci, Vector2(size.x - arrow_icon.get_width() - half_spacing, half_spacing), Color(1, 1, 1, 0.75))
	
	var text_line := TextLine.new()
	text_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_line.width = size.x - spacing - arrow_icon.get_width() - normal_sb.content_margin_left + 2
	text_line.add_string(_text, font, font_size)
	
	var y_offset := normal_sb.get_offset().y + (size.y - normal_sb.get_minimum_size().y - text_line.get_size().y) / 2.0
	text_line.draw(ci, Vector2(normal_sb.content_margin_left, y_offset), get_theme_color("font_color"))


func _on_mouse_exited() -> void:
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == 0:
		queue_redraw()
	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			focus_entered.emit()
			var value_picker := ContextPopup.new()
			value_picker.setup(_get_dropdown_buttons(), align_left, size.x, get_window().size.y / 2.0)
			queue_redraw()
			accept_event()
			HandlerGUI.popup_under_rect(value_picker, get_global_rect(), get_viewport())
		elif event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_enter_edit_mode()
			accept_event()

func _enter_edit_mode() -> void:
	line_edit = BetterLineEdit.new()
	line_edit.size = size
	line_edit.editable = editing_enabled
	line_edit.text = _get_line_edit_activation_text()
	line_edit.text_submitted.connect(_on_text_submitted)
	line_edit.text_changed.connect(_on_text_changed)
	line_edit.focus_exited.connect(line_edit.queue_free)
	line_edit.add_theme_font_override("font", get_theme_font("font"))
	add_child(line_edit)
	line_edit.grab_focus()

func _get_line_edit_activation_text() -> String:
	return _text

func _on_text_submitted(_new_text: String) -> void:
	queue_redraw()

func _on_text_changed(_new_text: String) -> void:
	return

@abstract func _get_dropdown_buttons() -> Array[Button]
