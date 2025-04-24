extends VBoxContainer

const EyedropperPopupScene = preload("res://src/ui_parts/eyedropper_popup.tscn")

const handle_texture = preload("res://assets/icons/BWHandle.svg")
const slider_arrow = preload("res://assets/icons/SliderArrow.svg")
const side_slider_arrow = preload("res://assets/icons/SideSliderArrow.svg")
const bg_pattern = preload("res://assets/icons/backgrounds/CheckerboardMini.svg")

var alpha_enabled := false
var is_none_keyword_available := false
var is_current_color_keyword_available := false

var color_space_button_group := ButtonGroup.new()

var undo_redo := UndoRedoRef.new()

signal slider_mode_changed
enum SliderMode {RGB, HSV}
var slider_mode: SliderMode:
	set(new_value):
		if slider_mode != new_value:
			slider_mode = new_value
			slider_mode_changed.emit()

@onready var color_wheel: MarginContainer = $ShapeContainer/ColorWheel
@onready var color_wheel_drawn: ColorRect = $ShapeContainer/ColorWheel/ColorWheelDraw
@onready var color_space_container: HBoxContainer = $SliderContainer/ColorSpaceContainer
@onready var start_color_rect: Control = %ColorsDisplay/StartColorRect
@onready var color_rect: Control = %ColorsDisplay/ColorRect
@onready var keyword_button: Button = $ColorContainer/KeywordButton
@onready var reset_color_button: Button = %ColorsDisplay/ColorRect/ResetColorButton
@onready var eyedropper_button: Button = $ColorContainer/EyedropperButton
@onready var center: Vector2 = color_wheel_drawn.get_rect().get_center()

var color_wheel_surface := RenderingServer.canvas_item_create()

# 0 is the side slider, 1-3 are the remaining sliders, 4 is the alpha slider.
var sliders_dragged: Array[bool] = [false, false, false, false, false]
# Tracks are the color rects of the sliders.
@onready var tracks_arr: Array[ColorRect] = [
		$ShapeContainer/SideSlider/SideSliderTrack, %Slider1/MarginContainer/ColorTrack,
		%Slider2/MarginContainer/ColorTrack, %Slider3/MarginContainer/ColorTrack,
		%Slider4/MarginContainer/ColorTrack]
# Widgets are the margin containers that acts as click areas and draw the arrow.
@onready var widgets_arr: Array[MarginContainer] = [
		$ShapeContainer/SideSlider, %Slider1/MarginContainer, %Slider2/MarginContainer,
		%Slider3/MarginContainer, %Slider4/MarginContainer]
# Fields are the number fields beside the color tracks.
@onready var fields_arr: Array[BetterLineEdit] = [
	null, %Slider1/IntField, %Slider2/IntField, %Slider3/IntField, %Slider4/IntField]
@onready var alpha_slider: HBoxContainer = %Slider4

# This variable stores what the color string was at the start, for the reset button.
var starting_color: String
var starting_display_color: Color
# These store the old color when using "none" or starting a dragging operation.
var backup_color: String
var backup_display_color: Color
# These store the current color string, normally forced to hex.
var color: String
var display_color: Color

signal color_changed(new_color: String)


func backup() -> void:
	backup_color = color
	backup_display_color = display_color

# To be called right after the color picker is added.
func setup_color(new_color: String, default_color: Color) -> void:
	starting_color = new_color
	color = new_color
	# Setup the display color.
	starting_display_color = ColorParser.text_to_color(starting_color, default_color,
			alpha_enabled)
	if slider_mode == SliderMode.HSV:
		# Clamping like this doesn't change the hex representation, but
		# it helps avoid locking certain sliders (e.g. hue slider when saturation is 0).
		# The HVS order helps to keep the saturation at 0.0001 for some reason.
		starting_display_color.h = clampf(starting_display_color.h, 0.0, 0.9999)
		starting_display_color.v = clampf(starting_display_color.v, 0.0001, 1.0)
		starting_display_color.s = clampf(starting_display_color.s, 0.0001, 1.0)
	if not alpha_enabled:
		starting_display_color.a = 1
	display_color = starting_display_color
	slider_mode = Configs.savedata.color_picker_slider_mode
	update()


func add_color_space_buttons() -> void:
	var normal_stylebox := StyleBoxFlat.new()
	normal_stylebox.bg_color = ThemeUtils.translucent_button_color_normal
	
	var hover_stylebox := normal_stylebox.duplicate()
	hover_stylebox.bg_color = ThemeUtils.translucent_button_color_hover
	
	var pressed_stylebox := StyleBoxFlat.new()
	pressed_stylebox.bg_color = ThemeUtils.translucent_button_color_pressed
	pressed_stylebox.border_width_top = 2
	pressed_stylebox.content_margin_bottom = 2
	pressed_stylebox.border_color = Color(ThemeUtils.common_editable_text_color, 0.7)
	
	for color_space: SliderMode in [SliderMode.RGB, SliderMode.HSV]:
		var btn := Button.new()
		btn.begin_bulk_theme_override()
		btn.add_theme_constant_override("align_to_largest_stylebox", 0)
		btn.add_theme_stylebox_override("normal", normal_stylebox)
		btn.add_theme_stylebox_override("hover", hover_stylebox)
		btn.add_theme_stylebox_override("pressed", pressed_stylebox)
		btn.end_bulk_theme_override()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.button_group = color_space_button_group
		btn.toggle_mode = true
		btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		slider_mode_changed.connect(func() -> void:
				btn.mouse_default_cursor_shape = Control.CURSOR_ARROW if\
				slider_mode == color_space else Control.CURSOR_POINTING_HAND
		)
		if color_space == Configs.savedata.color_picker_slider_mode:
			btn.button_pressed = true
		btn.pressed.connect(change_slider_mode.bind(color_space))
		match color_space:
			SliderMode.RGB: btn.text = "RGB"
			SliderMode.HSV: btn.text = "HSV"
		color_space_container.add_child(btn)

# Workaround to set this after ready from external places.
func update_keyword_button() -> void:
	if is_none_keyword_available or is_current_color_keyword_available:
		keyword_button.tooltip_text = Translator.translate("Color keywords")
		keyword_button.pressed.connect(_on_keyword_button_pressed)
		keyword_button.show()

func _ready() -> void:
	add_color_space_buttons()
	# Set up signals.
	widgets_arr[0].gui_input.connect(parse_slider_input.bind(0, true))
	widgets_arr[1].gui_input.connect(parse_slider_input.bind(1))
	widgets_arr[2].gui_input.connect(parse_slider_input.bind(2))
	widgets_arr[3].gui_input.connect(parse_slider_input.bind(3))
	slider_mode_changed.connect(_on_slider_mode_changed)
	_on_slider_mode_changed()
	if alpha_enabled:
		alpha_slider.visible = alpha_enabled
		widgets_arr[4].gui_input.connect(parse_slider_input.bind(4))
	
	update_keyword_button()
	eyedropper_button.pressed.connect(_on_eyedropper_pressed)
	eyedropper_button.tooltip_text = Translator.translate("Eyedropper")
	# Set up the rest.
	RenderingServer.canvas_item_set_parent(color_wheel_surface,
			color_wheel_drawn.get_canvas_item())

func _exit_tree() -> void:
	RenderingServer.free_rid(color_wheel_surface)


func _on_slider_mode_changed() -> void:
	match slider_mode:
		SliderMode.RGB:
			tracks_arr[1].material.set_shader_parameter("interpolation", 1)
			tracks_arr[2].material.set_shader_parameter("interpolation", 2)
			tracks_arr[3].material.set_shader_parameter("interpolation", 3)
		SliderMode.HSV:
			tracks_arr[1].material.set_shader_parameter("interpolation", 4)
			tracks_arr[2].material.set_shader_parameter("interpolation", 5)
			tracks_arr[3].material.set_shader_parameter("interpolation", 6)
	if alpha_enabled:
		tracks_arr[4].material.set_shader_parameter("interpolation", 0)
	update()


func register_visual_change(new_color: Color, use_backup := true) -> void:
	if use_backup and new_color == backup_display_color:
		return
	elif not use_backup and new_color == display_color:
		return
	
	undo_redo.create_action("")
	undo_redo.add_do_method(set_color.bind(hex(new_color), new_color))
	if use_backup:
		undo_redo.add_undo_method(set_color.bind(backup_color, backup_display_color))
	else:
		undo_redo.add_undo_method(set_color.bind(color, display_color))
	undo_redo.commit_action()


func set_color(new_color: String, new_display_color: Color) -> void:
	set_display_color(new_display_color)
	if color == new_color:
		return
	
	color = new_color
	update()
	color_changed.emit(new_color)


func set_display_color(new_display_color: Color) -> void:
	display_color = new_display_color
	update()
	color_changed.emit(hex(new_display_color))

func update() -> void:
	# Adjust the shaders.
	tracks_arr[0].material.set_shader_parameter("v", display_color.v)
	tracks_arr[0].material.set_shader_parameter("base_color",
			Color.from_hsv(display_color.h, display_color.s, 1.0))
	tracks_arr[1].material.set_shader_parameter("base_color", display_color)
	tracks_arr[2].material.set_shader_parameter("base_color", display_color)
	tracks_arr[3].material.set_shader_parameter("base_color", display_color)
	if alpha_enabled:
		tracks_arr[4].material.set_shader_parameter("base_color", display_color)
	# Redraw widgets, color indicators, color wheel.
	color_rect.queue_redraw()
	start_color_rect.queue_redraw()
	queue_redraw()
	color_wheel_drawn.queue_redraw()
	queue_redraw_widgets()
	# Set the text of the color fields.
	slider1_update()
	slider2_update()
	slider3_update()
	slider4_update()
	# Ensure that the HSV values are never exactly 0 or 1 to make everything draggable.
	backup_display_color.h = clampf(backup_display_color.h, 0.0, 0.9999)
	backup_display_color.v = clampf(backup_display_color.v, 0.0001, 1.0)
	backup_display_color.s = clampf(backup_display_color.s, 0.0001, 1.0)
	display_color.h = clampf(display_color.h, 0.0, 0.9999)
	display_color.v = clampf(display_color.v, 0.0001, 1.0)
	display_color.s = clampf(display_color.s, 0.0001, 1.0)
	if alpha_enabled:
		backup_display_color.a = clampf(backup_display_color.a, 0.0, 1.0)
		display_color.a = clampf(display_color.a, 0.0, 1.0)
	update_color_button()


func _on_color_wheel_gui_input(event: InputEvent) -> void:
	var is_event_drag_start := Utils.is_event_drag_start(event)
	if is_event_drag_start:
		backup()
	var new_color := display_color
	if Utils.is_event_drag(event) or is_event_drag_start:
		var event_pos_on_wheel: Vector2 = event.position + color_wheel.position -\
				color_wheel_drawn.position
		new_color.h = fposmod(center.angle_to_point(event_pos_on_wheel), TAU) / TAU
		new_color.s = minf(event_pos_on_wheel.distance_to(center) * 2 /\
				color_wheel_drawn.size.x, 1.0)
		set_display_color(new_color)
	if Utils.is_event_drag_end(event):
		register_visual_change(display_color)

func start_slider_drag(idx: int) -> void:
	sliders_dragged[idx] = true
	backup()

func move_slider(idx: int, offset: float) -> void:
	var new_color := display_color
	var channel: String
	match idx:
		4: channel = "a"
		0: channel = "v"
		1: match slider_mode:
			SliderMode.RGB: channel = "r"
			SliderMode.HSV: channel = "h"
		2: match slider_mode:
			SliderMode.RGB: channel = "g"
			SliderMode.HSV: channel = "s"
		3: match slider_mode:
			SliderMode.RGB: channel = "b"
			SliderMode.HSV: channel = "v"
	new_color = set_color_channel(new_color, channel, offset)
	set_display_color(new_color)
	widgets_arr[idx].queue_redraw()

func set_color_channel(col: Color, channel: String, offset: float) -> Color:
	match channel:
		"a": col.a = clampf(offset, 0.0, 1.0)
		"r": col.r = clampf(offset, 0.0, 1.0)
		"g": col.g = clampf(offset, 0.0, 1.0)
		"b": col.b = clampf(offset, 0.0, 1.0)
		"h": col.h = clampf(offset, 0.0, 0.9999)
		"s": col.s = clampf(offset, 0.0001, 1.0)
		"v": col.v = clampf(offset, 0.0001, 1.0)
	return col

func end_slider_drag(idx: int) -> void:
	register_visual_change(display_color)
	sliders_dragged[idx] = false
	widgets_arr[idx].queue_redraw()

func calculate_offset(idx: int, pos: Vector2, is_slider_vertical: bool) -> float:
	if is_slider_vertical:
		return 1 - ((pos.y - tracks_arr[idx].position.y) / tracks_arr[idx].size.y)
	else:
		return (pos.x - tracks_arr[idx].position.x) / tracks_arr[idx].size.x

func parse_slider_input(event: InputEvent, idx: int, is_slider_vertical := false) -> void:
	if Utils.is_event_drag_start(event):
		start_slider_drag(idx)
		move_slider(idx, calculate_offset(idx, event.position, is_slider_vertical))
	elif Utils.is_event_drag(event):
		move_slider(idx, calculate_offset(idx, event.position, is_slider_vertical))
	elif Utils.is_event_drag_end(event):
		end_slider_drag(idx)

# When slider text is submitted, it should be clamped, used, and then the slider should
# be updated again so the text reflects the new value even if the color didn't change.
func _on_slider1_text_submitted(new_text: String) -> void:
	var new_color := display_color
	match slider_mode:
		SliderMode.RGB: new_color.r = clampf(new_text.to_int() / 255.0, 0.0, 1.0)
		SliderMode.HSV: new_color.h = clampf(new_text.to_int() / 360.0, 0.0, 0.9999)
	register_visual_change(new_color, false)
	slider1_update()

func _on_slider2_text_submitted(new_text: String) -> void:
	var new_color := display_color
	match slider_mode:
		SliderMode.RGB: new_color.g = clampf(new_text.to_int() / 255.0, 0.0, 1.0)
		SliderMode.HSV: new_color.s = clampf(new_text.to_int() / 100.0, 0.0001, 1.0)
	register_visual_change(new_color, false)
	slider2_update()

func _on_slider3_text_submitted(new_text: String) -> void:
	var new_color := display_color
	match slider_mode:
		SliderMode.RGB: new_color.b = clampf(new_text.to_int() / 255.0, 0.0, 1.0)
		SliderMode.HSV: new_color.v = clampf(new_text.to_int() / 100.0, 0.0001, 1.0)
	register_visual_change(new_color, false)
	slider3_update()

func _on_slider4_text_submitted(new_text: String) -> void:
	var new_color := display_color
	new_color.a = clampf(new_text.to_int() / 100.0, 0.0, 1.0)
	register_visual_change(new_color, false)
	slider4_update()

func slider1_update() -> void:
	var number: float
	match slider_mode:
		SliderMode.RGB: number = display_color.r * 255
		SliderMode.HSV: number = display_color.h * 360
	_slider_set_text(fields_arr[1], number)

func slider2_update() -> void:
	var number: float
	match slider_mode:
		SliderMode.RGB: number = display_color.g * 255
		SliderMode.HSV: number = display_color.s * 100
	_slider_set_text(fields_arr[2], number)

func slider3_update() -> void:
	var number: float
	match slider_mode:
		SliderMode.RGB: number = display_color.b * 255
		SliderMode.HSV: number = display_color.v * 100
	_slider_set_text(fields_arr[3], number)

func slider4_update() -> void:
	_slider_set_text(fields_arr[4],display_color.a * 100)

func _slider_set_text(field: BetterLineEdit, number: float) -> void:
	field.text = String.num_uint64(roundi(number))


func _on_keyword_button_pressed() -> void:
	var btn_arr: Array[Button] = []
	if is_none_keyword_available:
		btn_arr.append(ContextPopup.create_button("none",
				set_to_keyword.bind("none"), color == "none",
				load("res://assets/icons/NoneColor.svg")))
	if is_current_color_keyword_available:
		btn_arr.append(ContextPopup.create_button("currentColor",
				set_to_keyword.bind("currentColor"), color == "currentColor",
				load("res://assets/icons/Paste.svg")))
	
	for btn in btn_arr:
		btn.add_theme_font_override("font", ThemeUtils.mono_font)
	
	var context_popup := ContextPopup.new()
	context_popup.setup(btn_arr, true)
	HandlerGUI.popup_under_rect(context_popup, keyword_button.get_global_rect(),
			get_viewport())

func set_to_keyword(keyword: String) -> void:
	undo_redo.create_action("")
	if color.strip_edges() == keyword:
		undo_redo.add_do_method(set_color.bind(backup_color, backup_display_color))
		undo_redo.add_undo_method(set_color.bind(color, display_color))
	else:
		backup()
		undo_redo.add_do_method(set_color.bind(keyword, display_color))
		undo_redo.add_undo_method(set_color.bind(color, display_color))
	undo_redo.commit_action()

func _on_reset_color_button_pressed() -> void:
	reset_color_button.disabled = true
	undo_redo.create_action("")
	undo_redo.add_do_method(set_color.bind(starting_color, starting_display_color))
	undo_redo.add_undo_method(set_color.bind(color, display_color))
	undo_redo.commit_action()


func change_slider_mode(new_slider_mode: SliderMode) -> void:
	slider_mode = new_slider_mode
	Configs.savedata.color_picker_slider_mode = new_slider_mode


# Gray out the start color rect if it's not actually a color.
func _on_start_color_rect_draw() -> void:
	var rect_size := start_color_rect.size
	var rect := Rect2(Vector2.ZERO, rect_size)
	if ColorParser.is_valid_url(starting_color):
		var cross_color := Color(0.8, 0.8, 0.8)
		start_color_rect.draw_rect(rect, Color(0.6, 0.6, 0.6))
		start_color_rect.draw_line(Vector2.ZERO, rect_size, cross_color, 0.5, true)
		start_color_rect.draw_line(Vector2(rect_size.x, 0), Vector2(0, rect_size.y),
				cross_color, 0.5, true)
	else:
		start_color_rect.draw_texture_rect(bg_pattern, rect, true)
		start_color_rect.draw_rect(rect, starting_display_color)

func _on_color_rect_draw() -> void:
	var rect := Rect2(Vector2.ZERO, color_rect.size)
	color_rect.draw_texture_rect(bg_pattern, rect, true)
	color_rect.draw_rect(rect, display_color)

# Draw inside the side slider to give it a little arrow to the side.
func _on_side_slider_draw() -> void:
	var arrow_modulate := Color(1, 1, 1) if sliders_dragged[0] else Color(1, 1, 1, 0.7)
	widgets_arr[0].draw_texture(side_slider_arrow, Vector2(0, tracks_arr[0].position.y +\
			tracks_arr[0].size.y * (1 - display_color.v) -\
			side_slider_arrow.get_height() / 2.0), arrow_modulate)

func _draw() -> void:
	RenderingServer.canvas_item_clear(color_wheel_surface)
	# Draw the color wheel handle.
	var point_pos := center + Vector2(center.x * cos(display_color.h * TAU),
			center.y * sin(display_color.h * TAU)) * display_color.s
	RenderingServer.canvas_item_add_texture_rect(color_wheel_surface, Rect2(point_pos -\
			handle_texture.get_size() / 2, handle_texture.get_size()), handle_texture)

# Helper for drawing the horizontal sliders.
func draw_hslider(idx: int, offset: float, chr: String) -> void:
	var arrow_modulate := Color(1, 1, 1) if sliders_dragged[idx] else Color(1, 1, 1, 0.7)
	widgets_arr[idx].draw_texture(slider_arrow, Vector2(tracks_arr[idx].position.x +\
			tracks_arr[idx].size.x * offset - slider_arrow.get_width() / 2.0,
			tracks_arr[idx].size.y), arrow_modulate)
	widgets_arr[idx].draw_string(get_theme_default_font(),
			Vector2(-12, 11), chr, HORIZONTAL_ALIGNMENT_CENTER, 12, 14)

# Make sure the arrows are redrawn when the tracks finish resizing.
func _on_track_resized() -> void:
	if !widgets_arr.is_empty():
		queue_redraw_widgets()

func queue_redraw_widgets() -> void:
	widgets_arr[0].queue_redraw()
	widgets_arr[1].queue_redraw()
	widgets_arr[2].queue_redraw()
	widgets_arr[3].queue_redraw()
	if alpha_enabled:
		widgets_arr[4].queue_redraw()

func _on_slider1_draw() -> void:
	match slider_mode:
		SliderMode.RGB: draw_hslider(1, display_color.r, "R")
		SliderMode.HSV: draw_hslider(1, display_color.h, "H")

func _on_slider2_draw() -> void:
	match slider_mode:
		SliderMode.RGB: draw_hslider(2, display_color.g, "G")
		SliderMode.HSV: draw_hslider(2, display_color.s, "S")

func _on_slider3_draw() -> void:
	match slider_mode:
		SliderMode.RGB: draw_hslider(3, display_color.b, "B")
		SliderMode.HSV: draw_hslider(3, display_color.v, "V")

func _on_slider4_draw() -> void:
	draw_hslider(4, display_color.a, "A")


func update_color_button() -> void:
	if ColorParser.are_colors_same(starting_color, color):
		reset_color_button.disabled = true
		return
	reset_color_button.disabled = false
	if display_color.get_luminance() < 0.455:
		reset_color_button.begin_bulk_theme_override()
		reset_color_button.add_theme_color_override("icon_hover_color", Color.WHITE)
		reset_color_button.add_theme_color_override("icon_pressed_color",
				Color(0.5, 1, 1))
		reset_color_button.end_bulk_theme_override()
	else:
		reset_color_button.begin_bulk_theme_override()
		reset_color_button.add_theme_color_override("icon_hover_color", Color.BLACK)
		reset_color_button.add_theme_color_override("icon_pressed_color",
				Color(0, 0.5, 0.5))
		reset_color_button.end_bulk_theme_override()

func hex(col: Color) -> String:
	# Removing the saturation and hue clamping fixes hex conversion in edge cases.
	# e.g., H = 0.0001, S = 0.0001, V = 0.5 --> Color(0.5, 0.4999, 0.4999) --> "807f7f".
	if col.s < 0.001:
		col.s = 0.0
	
	if col.h < 0.001:
		col.h = 0.0
	elif col.h > 0.999:
		col.h = 1.0
	
	return col.to_html(alpha_enabled and col.a != 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if ShortcutUtils.is_action_pressed(event, "ui_redo"):
		if undo_redo.has_redo():
			undo_redo.redo()
		accept_event()
	elif ShortcutUtils.is_action_pressed(event, "ui_undo"):
		if undo_redo.has_undo():
			undo_redo.undo()
		accept_event()


func _on_eyedropper_pressed() -> void:
	var eyedropper_popup := EyedropperPopupScene.instantiate()
	eyedropper_popup.color_picked.connect(register_visual_change.bind(false))
	HandlerGUI.add_popup(eyedropper_popup)
