extends Control

const arrow_icon = preload("res://assets/icons/SmallArrowDown.svg")

var ci := get_canvas_item()

var line_edit: BetterLineEdit

@export var values: Array[Variant]
@export var disabled_values: Array[Variant]  # References values.
@export var aliases: Dictionary = {}  # References values.
@export var restricted := true
@export var editing_enabled := false
@export var align_left := false  # The alignment of the popup options' text.
# TODO Typed Dictionary wonkiness
@export var value_text_map: Dictionary = {}  # Dictionary[Variant, String]

signal value_changed(new_value: Variant)
var _value: Variant

func set_value(new_value: Variant, emit_changed := true) -> void:
	if _value != new_value:
		_value = new_value
		if emit_changed:
			value_changed.emit(_value)

func _ready() -> void:
	_value = values[0]
	value_changed.connect(queue_redraw.unbind(1))
	mouse_exited.connect(_on_mouse_exited)
	tooltip_text = Translator.translate("Right-click to edit as text.")

func _draw() -> void:
	var normal_sb: StyleBoxFlat = get_theme_stylebox("normal", "LineEdit")
	var font := get_theme_font("font", "LineEdit")
	var font_size := get_theme_font_size("font_size", "LineEdit")
	
	normal_sb.draw(ci, Rect2(Vector2.ZERO, size))
	if get_viewport().gui_get_hovered_control() == self:
		get_theme_stylebox("hover", "LineEdit").draw(ci, Rect2(Vector2.ZERO, size))
	
	var spacing := size.y - arrow_icon.get_height()
	var half_spacing := spacing / 2.0
	
	arrow_icon.draw(ci, Vector2(size.x - arrow_icon.get_width() - half_spacing, half_spacing))
	var text_line := TextLine.new()
	text_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_line.width = size.x - spacing - arrow_icon.get_width()
	text_line.add_string(str(_value), font, font_size)
	
	var y_offset := normal_sb.get_offset().y + (size.y - normal_sb.get_minimum_size().y - text_line.get_size().y) / 2.0
	text_line.draw(ci, Vector2(normal_sb.content_margin_left, y_offset), get_theme_color("font_color", "LineEdit"))


func _on_mouse_exited() -> void:
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == 0:
		queue_redraw()
	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			var btn_arr: Array[Button] = []
			for val in values:
				btn_arr.append(ContextPopup.create_button(value_text_map.get(val, str(val)),
						set_value.bind(val), disabled_values.has(val) or val == _value))
			
			var value_picker := ContextPopup.new()
			value_picker.setup(btn_arr, align_left, size.x, get_window().size.y / 2.0)
			queue_redraw()
			HandlerGUI.popup_under_rect(value_picker, get_global_rect(), get_viewport())
		elif event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			line_edit = BetterLineEdit.new()
			line_edit.size = size
			line_edit.editable = editing_enabled
			line_edit.text = str(_value)
			line_edit.text_submitted.connect(func(p: String) -> void: _on_text_submitted(p))
			line_edit.text_changed.connect(func(p: String) -> void: _on_text_changed(p))
			line_edit.focus_exited.connect(func() -> void: line_edit.queue_free())
			add_child(line_edit)
			line_edit.grab_focus()

func _on_text_submitted(new_text: String) -> void:
	if new_text in aliases:
		new_text = aliases[new_text]
	
	if (restricted and new_text in values) or not restricted:
		set_value(new_text)
	queue_redraw()
	line_edit.remove_theme_color_override("font_color")

func _on_text_changed(new_text: String) -> void:
	if restricted:
		if new_text in aliases:
			new_text = aliases[new_text]
		line_edit.add_theme_color_override("font_color", Configs.savedata.get_validity_color(not new_text in values))
