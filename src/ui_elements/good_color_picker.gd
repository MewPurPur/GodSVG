extends VBoxContainer

const handle_texture = preload("res://visual/icons/handles/HandleBig.svg")
const slider_arrow = preload("res://visual/icons/SliderArrow.svg")
const side_slider_arrow = preload("res://visual/icons/SideSliderArrow.svg")

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
		if slider_mode == SliderMode.RGB:
			slider1_track.material.set_shader_parameter(&"interpolation", 0)
			slider2_track.material.set_shader_parameter(&"interpolation", 1)
			slider3_track.material.set_shader_parameter(&"interpolation", 2)
		elif slider_mode == SliderMode.HSV:
			slider1_track.material.set_shader_parameter(&"interpolation", 3)
			slider2_track.material.set_shader_parameter(&"interpolation", 4)
			slider3_track.material.set_shader_parameter(&"interpolation", 5)
			# Clamping like this doesn't change the hex representation, but
			# it helps avoid locking certain sliders (e.g. hue slider when saturation is 0).
			var new_color := color
			new_color.h = clampf(new_color.h, 0.0, 0.9999)
			new_color.s = clampf(new_color.s, 0.0001, 1.0)
			new_color.v = clampf(new_color.v, 0.0001, 1.0)
			set_color(new_color)
		update()

@onready var side_slider: MarginContainer = $ShapeContainer/SideSlider
@onready var side_slider_track: ColorRect = $ShapeContainer/SideSlider/SideSliderTrack
@onready var color_wheel: MarginContainer = $ShapeContainer/ColorWheel
@onready var color_wheel_drawn: ColorRect = $ShapeContainer/ColorWheel/ColorWheelDraw
@onready var rgb_button: Button = $SliderContainer/ColorSpaceContainer/RGB
@onready var hsv_button: Button = $SliderContainer/ColorSpaceContainer/HSV
@onready var start_color_rect: ColorRect = %ColorsDisplay/StartColorRect
@onready var color_rect: ColorRect = %ColorsDisplay/ColorRect
@onready var slider1_widget: MarginContainer = %Slider1/MarginContainer
@onready var slider2_widget: MarginContainer = %Slider2/MarginContainer
@onready var slider3_widget: MarginContainer = %Slider3/MarginContainer
@onready var slider1_track: ColorRect = %Slider1/MarginContainer/ColorTrack
@onready var slider2_track: ColorRect = %Slider2/MarginContainer/ColorTrack
@onready var slider3_track: ColorRect = %Slider3/MarginContainer/ColorTrack
@onready var slider1_field: BetterLineEdit = %Slider1/IntField
@onready var slider2_field: BetterLineEdit = %Slider2/IntField
@onready var slider3_field: BetterLineEdit = %Slider3/IntField
@onready var none_button: Button = $ColorContainer/None
@onready var reset_color_button: Button = %ColorsDisplay/ColorRect/ResetColorButton
@onready var center: Vector2 = color_wheel_drawn.get_rect().get_center()

var color_wheel_surface := RenderingServer.canvas_item_create()
var is_dragging_slider1 := false
var is_dragging_slider2 := false
var is_dragging_slider3 := false
var is_dragging_side_slider := false

var starting_color: String
signal color_changed(new_color: String)
var is_none := false
var color := Color(0, 0, 0)

# To be called right after the color picker is added.
func setup_color(new_color: String) -> void:
	starting_color = new_color
	is_none = (new_color == "none")
	setup_none_button()
	color = Color.from_string(new_color, Color(0, 0, 0))
	slider_mode = GlobalSettings.save_data.color_picker_slider_mode
	if not is_node_ready():
		await ready
	update()

func set_color(new_color: Color) -> void:
	if is_none:
		toggle_none()
	if color != new_color:
		color = new_color
		update()
		color_changed.emit(new_color.to_html(false))

func update() -> void:
	side_slider_track.material.set_shader_parameter(&"v", color.v)
	side_slider_track.material.set_shader_parameter(&"base_color",
			Color.from_hsv(color.h, color.s, 1.0))
	slider1_track.material.set_shader_parameter(&"base_color", color)
	slider2_track.material.set_shader_parameter(&"base_color", color)
	slider3_track.material.set_shader_parameter(&"base_color", color)
	color_rect.color = color
	if starting_color == "none":
		start_color_rect.color = Color.TRANSPARENT
	elif !starting_color.is_empty():
		start_color_rect.color = Color(starting_color)
	queue_redraw()
	side_slider.queue_redraw()
	color_wheel_drawn.queue_redraw()
	slider1_widget.queue_redraw()
	slider2_widget.queue_redraw()
	slider3_widget.queue_redraw()
	match slider_mode:
		SliderMode.RGB: 
			slider1_field.text = String.num_uint64(roundi(color.r * 255))
			slider2_field.text = String.num_uint64(roundi(color.g * 255))
			slider3_field.text = String.num_uint64(roundi(color.b * 255))
		SliderMode.HSV: 
			slider1_field.text = String.num_uint64(roundi(color.h * 360))
			slider2_field.text = String.num_uint64(roundi(color.s * 100))
			slider3_field.text = String.num_uint64(roundi(color.v * 100))


func _ready() -> void:
	RenderingServer.canvas_item_set_parent(color_wheel_surface,
			color_wheel_drawn.get_canvas_item())


func _on_side_slider_gui_input(event: InputEvent) -> void:
	if Utils.is_event_drag(event) or Utils.is_event_drag_start(event):
		var n: float = (event.position.y - side_slider_track.position.y) /\
				side_slider_track.size.y
		var new_color := color
		new_color.v = clampf(1 - n, 0.0001, 1.0)
		set_color(new_color)
	if Utils.is_event_drag_start(event) or Utils.is_event_drag_end(event):
		is_dragging_side_slider = event.is_pressed()
		side_slider.queue_redraw()

func _on_color_wheel_gui_input(event: InputEvent) -> void:
	if Utils.is_event_drag(event) or Utils.is_event_drag_start(event):
		var new_color := color
		var event_pos_on_wheel: Vector2 = event.position + color_wheel.position -\
				color_wheel_drawn.position
		new_color.h = fposmod(center.angle_to_point(event_pos_on_wheel), TAU) / TAU
		new_color.s = minf(event_pos_on_wheel.distance_to(center) * 2 /\
				color_wheel_drawn.size.x, 1.0)
		set_color(new_color)

func _on_slider1_gui_input(event: InputEvent) -> void:
	if Utils.is_event_drag(event) or Utils.is_event_drag_start(event):
		var n: float = (event.position.x - slider1_track.position.x) / slider1_track.size.x
		var new_color := color
		match slider_mode:
			SliderMode.RGB: new_color.r = clampf(n, 0.0, 1.0)
			SliderMode.HSV: new_color.h = clampf(n, 0.0, 0.9999)
		set_color(new_color)
	if Utils.is_event_drag_start(event) or Utils.is_event_drag_end(event):
		is_dragging_slider1 = event.is_pressed()
		slider1_widget.queue_redraw()

func _on_slider2_gui_input(event: InputEvent) -> void:
	if Utils.is_event_drag(event) or Utils.is_event_drag_start(event):
		var n: float = (event.position.x - slider2_track.position.x) / slider2_track.size.x
		var new_color := color
		match slider_mode:
			SliderMode.RGB: new_color.g = clampf(n, 0.0, 1.0)
			SliderMode.HSV: new_color.s = clampf(n, 0.0001, 1.0)
		set_color(new_color)
	if Utils.is_event_drag_start(event) or Utils.is_event_drag_end(event):
		is_dragging_slider2 = event.is_pressed()
		slider2_widget.queue_redraw()

func _on_slider3_gui_input(event: InputEvent) -> void:
	if Utils.is_event_drag(event) or Utils.is_event_drag_start(event):
		var n: float = (event.position.x - slider3_track.position.x) / slider3_track.size.x
		var new_color := color
		match slider_mode:
			SliderMode.RGB: new_color.b = clampf(n, 0.0, 1.0)
			SliderMode.HSV: new_color.v = clampf(n, 0.0001, 1.0)
		set_color(new_color)
	if Utils.is_event_drag_start(event) or Utils.is_event_drag_end(event):
		is_dragging_slider3 = event.is_pressed()
		slider3_widget.queue_redraw()


func _on_rgb_pressed() -> void:
	slider_mode = SliderMode.RGB
	GlobalSettings.modify_save_data(&"color_picker_slider_mode", SliderMode.RGB)

func _on_hsv_pressed() -> void:
	slider_mode = SliderMode.HSV
	GlobalSettings.modify_save_data(&"color_picker_slider_mode", SliderMode.HSV)


# Draw inside the side slider to give it a little arrow to the side.
func _on_side_slider_draw() -> void:
	var arrow_modulate := Color(1, 1, 1) if is_dragging_side_slider\
			else Color(1, 1, 1, 0.7)
	side_slider.draw_texture(side_slider_arrow, Vector2(0, side_slider_track.position.y +\
			side_slider_track.size.y * (1 - color.v) - side_slider_arrow.get_height() / 2.0),
			arrow_modulate)

func _draw() -> void:
	RenderingServer.canvas_item_clear(color_wheel_surface)
	# Draw color wheel handle.
	var point_pos := center + Vector2(center.x * cos(color.h * TAU),
			center.y * sin(color.h * TAU)) * color.s
	RenderingServer.canvas_item_add_texture_rect(color_wheel_surface, Rect2(point_pos -\
			handle_texture.get_size() / 2, handle_texture.get_size()), handle_texture)


func _on_slider1_draw() -> void:
	var offset := color.r if slider_mode == SliderMode.RGB else color.h
	var arrow_modulate := Color(1, 1, 1) if is_dragging_slider1 else Color(1, 1, 1, 0.7)
	slider1_widget.draw_texture(slider_arrow, Vector2(slider1_track.position.x +\
			slider1_track.size.x * offset - slider_arrow.get_width() / 2.0,
			slider1_track.size.y), arrow_modulate)
	var chr := "R" if slider_mode == SliderMode.RGB else "H"
	slider1_widget.draw_string(ThemeDB.get_project_theme().default_font,
			Vector2(-12, 11), chr, HORIZONTAL_ALIGNMENT_CENTER, 12, 14)

func _on_slider2_draw() -> void:
	var offset := color.g if slider_mode == SliderMode.RGB else color.s
	var arrow_modulate := Color(1, 1, 1) if is_dragging_slider2 else Color(1, 1, 1, 0.7)
	slider2_widget.draw_texture(slider_arrow, Vector2(slider2_track.position.x +\
			slider2_track.size.x * offset - slider_arrow.get_width() / 2.0,
			slider2_track.size.y), arrow_modulate)
	var chr := "G" if slider_mode == SliderMode.RGB else "S"
	slider2_widget.draw_string(ThemeDB.get_project_theme().default_font,
			Vector2(-12, 11), chr, HORIZONTAL_ALIGNMENT_CENTER, 12, 14)

func _on_slider3_draw() -> void:
	var offset := color.b if slider_mode == SliderMode.RGB else color.v
	var arrow_modulate := Color(1, 1, 1) if is_dragging_slider3 else Color(1, 1, 1, 0.7)
	slider3_widget.draw_texture(slider_arrow, Vector2(slider3_track.position.x +\
			slider3_track.size.x * offset - slider_arrow.get_width() / 2.0,
			slider3_track.size.y), arrow_modulate)
	var chr := "B" if slider_mode == SliderMode.RGB else "V"
	slider3_widget.draw_string(ThemeDB.get_project_theme().default_font,
			Vector2(-12, 11), chr, HORIZONTAL_ALIGNMENT_CENTER, 12, 14)


func _on_slider1_text_submitted(new_text: String) -> void:
	var new_color := color
	if slider_mode == SliderMode.RGB:
		new_color.r = clampf(new_text.to_int() / 255.0, 0.0, 1.0)
	elif slider_mode == SliderMode.HSV:
		new_color.h = clampf(new_text.to_int() / 360.0, 0.0, 0.9999)
	set_color(new_color)

func _on_slider2_text_submitted(new_text: String) -> void:
	var new_color := color
	if slider_mode == SliderMode.RGB:
		new_color.g = clampf(new_text.to_int() / 255.0, 0.0, 1.0)
	elif slider_mode == SliderMode.HSV:
		new_color.s = clampf(new_text.to_int() / 100.0, 0.0001, 1.0)
	set_color(new_color)

func _on_slider3_text_submitted(new_text: String) -> void:
	var new_color := color
	if slider_mode == SliderMode.RGB:
		new_color.b = clampf(new_text.to_int() / 255.0, 0.0, 1.0)
	elif slider_mode == SliderMode.HSV:
		new_color.v = clampf(new_text.to_int() / 100.0, 0.0001, 1.0)
	set_color(new_color)


# This sets the color to "none", usually when the button is pressed.
func toggle_none() -> void:
	is_none = not is_none
	if is_none:
		color_changed.emit("none")
	else:
		color_changed.emit(color.to_html(false))
	setup_none_button()

func setup_none_button() -> void:
	none_button.button_pressed = is_none
	none_button.tooltip_text = tr(&"#enable_color") if is_none else tr(&"#disable_color")


func _on_reset_color_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask != MOUSE_BUTTON_MASK_LEFT:
		if (starting_color == "none" and not is_none) or\
		AttributeColor.get_color_from_non_url(starting_color).is_equal_approx(color):
			reset_color_button.disabled = true
			return
		reset_color_button.disabled = false
		if color.get_luminance() < 0.455:
			reset_color_button.begin_bulk_theme_override()
			reset_color_button.add_theme_color_override(&"icon_hover_color", Color.WHITE)
			reset_color_button.add_theme_color_override(&"icon_pressed_color",
					Color(0.5, 1, 1))
			reset_color_button.end_bulk_theme_override()
		else:
			reset_color_button.begin_bulk_theme_override()
			reset_color_button.add_theme_color_override(&"icon_hover_color", Color.BLACK)
			reset_color_button.add_theme_color_override(&"icon_pressed_color",
					Color(0, 0.5, 0.5))
			reset_color_button.end_bulk_theme_override()

func _on_reset_color_button_pressed() -> void:
	reset_color_button.disabled = true
	if starting_color != "none":
		set_color(starting_color)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed(&"redo"):
		if UR.has_redo():
			UR.redo()
		accept_event()
	elif event.is_action_pressed(&"undo") and UR.has_undo():
		UR.undo()
		accept_event()
