extends VBoxContainer

const EyedropperPopup = preload("res://src/ui_parts/eyedropper_popup.tscn")

const handle_texture = preload("res://visual/icons/BWHandle.svg")
const slider_arrow = preload("res://visual/icons/SliderArrow.svg")
const side_slider_arrow = preload("res://visual/icons/SideSliderArrow.svg")
const bg_pattern = preload("res://visual/icons/backgrounds/CheckerboardMini.svg")

var alpha_enabled := false
var show_disable_color := true

var UR := UndoRedo.new()

enum SliderMode {RGB, HSV}
var slider_mode: SliderMode:
	set(new_mode):
		slider_mode = new_mode
		var disabled_button := hsv_button if new_mode == SliderMode.HSV else rgb_button
		for btn in [hsv_button, rgb_button]:
			btn.disabled = (btn == disabled_button)
			btn.mouse_default_cursor_shape = Control.CURSOR_ARROW if\
					btn == disabled_button else Control.CURSOR_POINTING_HAND
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

@onready var color_wheel: MarginContainer = $ShapeContainer/ColorWheel
@onready var color_wheel_drawn: ColorRect = $ShapeContainer/ColorWheel/ColorWheelDraw
@onready var rgb_button: Button = $SliderContainer/ColorSpaceContainer/RGB
@onready var hsv_button: Button = $SliderContainer/ColorSpaceContainer/HSV
@onready var start_color_rect: Control = %ColorsDisplay/StartColorRect
@onready var color_rect: Control = %ColorsDisplay/ColorRect
@onready var none_button: Button = $ColorContainer/NoneButton
@onready var reset_color_button: Button = %ColorsDisplay/ColorRect/ResetColorButton
@onready var center: Vector2 = color_wheel_drawn.get_rect().get_center()

var color_wheel_surface := RenderingServer.canvas_item_create()

# 0 is the side slider, 1-3 are the remaining sliders.
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
func setup_color(new_color: String) -> void:
	starting_color = new_color
	color = new_color
	# Setup the display color.
	starting_display_color = ColorParser.text_to_color(starting_color, Color(),
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
	slider_mode = GlobalSettings.savedata.color_picker_slider_mode
	update()

func _ready() -> void:
	# Set up signals.
	widgets_arr[0].gui_input.connect(parse_slider_input.bind(0, true))
	for i in [1, 2, 3]:
		widgets_arr[i].gui_input.connect(parse_slider_input.bind(i))
	if alpha_enabled:
		alpha_slider.visible = alpha_enabled
		widgets_arr[4].gui_input.connect(parse_slider_input.bind(4))
	if show_disable_color:
		none_button.show()
	# Set up the rest.
	RenderingServer.canvas_item_set_parent(color_wheel_surface,
			color_wheel_drawn.get_canvas_item())

func _exit_tree() -> void:
	RenderingServer.free_rid(color_wheel_surface)
	UR.free()

func register_visual_change(new_color: Color, use_backup := true) -> void:
	if use_backup and new_color == backup_display_color:
		return
	elif not use_backup and new_color == display_color:
		return
	
	UR.create_action("")
	UR.add_do_method(set_color.bind(hex(new_color), new_color))
	if use_backup:
		UR.add_undo_method(set_color.bind(backup_color, backup_display_color))
	else:
		UR.add_undo_method(set_color.bind(color, display_color))
	UR.commit_action()


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
	for i in [1, 2, 3]:
		tracks_arr[i].material.set_shader_parameter("base_color", display_color)
	if alpha_enabled:
		tracks_arr[4].material.set_shader_parameter("base_color", display_color)
	# Setup the "none" button.
	var is_none := (color == "none")
	none_button.button_pressed = is_none
	none_button.tooltip_text = TranslationServer.translate("Enable the color") if is_none\
			else TranslationServer.translate("Disable the color")
	# Redraw widgets, color indicators, color wheel.
	color_rect.queue_redraw()
	start_color_rect.queue_redraw()
	queue_redraw()
	color_wheel_drawn.queue_redraw()
	queue_redraw_widgets()
	# Set the text of the color fields.
	match slider_mode:
		SliderMode.RGB:
			fields_arr[1].text = String.num_uint64(roundi(display_color.r * 255))
			fields_arr[2].text = String.num_uint64(roundi(display_color.g * 255))
			fields_arr[3].text = String.num_uint64(roundi(display_color.b * 255))
		SliderMode.HSV:
			fields_arr[1].text = String.num_uint64(roundi(display_color.h * 360))
			fields_arr[2].text = String.num_uint64(roundi(display_color.s * 100))
			fields_arr[3].text = String.num_uint64(roundi(display_color.v * 100))
	fields_arr[4].text = String.num_uint64(roundi(display_color.a * 100))
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

func _on_slider1_text_submitted(new_text: String) -> void:
	var new_color := display_color
	match slider_mode:
		SliderMode.RGB: new_color.r = clampf(new_text.to_int() / 255.0, 0.0, 1.0)
		SliderMode.HSV: new_color.h = clampf(new_text.to_int() / 360.0, 0.0, 0.9999)
	register_visual_change(new_color, false)

func _on_slider2_text_submitted(new_text: String) -> void:
	var new_color := display_color
	match slider_mode:
		SliderMode.RGB: new_color.g = clampf(new_text.to_int() / 255.0, 0.0, 1.0)
		SliderMode.HSV: new_color.s = clampf(new_text.to_int() / 100.0, 0.0001, 1.0)
	register_visual_change(new_color, false)

func _on_slider3_text_submitted(new_text: String) -> void:
	var new_color := display_color
	match slider_mode:
		SliderMode.RGB: new_color.b = clampf(new_text.to_int() / 255.0, 0.0, 1.0)
		SliderMode.HSV: new_color.v = clampf(new_text.to_int() / 100.0, 0.0001, 1.0)
	register_visual_change(new_color, false)

func _on_slider4_text_submitted(new_text: String) -> void:
	var new_color := display_color
	new_color.a = clampf(new_text.to_int() / 100.0, 0.0, 1.0)
	register_visual_change(new_color, false)

func _on_none_button_pressed() -> void:
	UR.create_action("")
	if color.strip_edges() == "none":
		UR.add_do_method(set_color.bind(backup_color, backup_display_color))
		UR.add_undo_method(set_color.bind(color, display_color))
	else:
		backup()
		UR.add_do_method(set_color.bind("none", display_color))
		UR.add_undo_method(set_color.bind(color, display_color))
	UR.commit_action()

func _on_reset_color_button_pressed() -> void:
	reset_color_button.disabled = true
	UR.create_action("")
	UR.add_do_method(set_color.bind(starting_color, starting_display_color))
	UR.add_undo_method(set_color.bind(color, display_color))
	UR.commit_action()


func _on_rgb_pressed() -> void:
	change_slider_mode(SliderMode.RGB)

func _on_hsv_pressed() -> void:
	change_slider_mode(SliderMode.HSV)

func change_slider_mode(new_slider_mode: SliderMode) -> void:
	slider_mode = new_slider_mode
	GlobalSettings.modify_setting("color_picker_slider_mode", new_slider_mode)


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
	for i in [0, 1, 2, 3]:
		widgets_arr[i].queue_redraw()
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
	return col.to_html(alpha_enabled and col.a != 1.0)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("redo"):
		if UR.has_redo():
			UR.redo()
		accept_event()
	elif event.is_action_pressed("undo"):
		if UR.has_undo():
			UR.undo()
		accept_event()


func _on_eyedropper_pressed() -> void:
	var eyedropper_popup := EyedropperPopup.instantiate()
	eyedropper_popup.color_picked.connect(register_visual_change.bind(false))
	HandlerGUI.add_popup_overlay(eyedropper_popup)
