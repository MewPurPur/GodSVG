extends VBoxContainer

const ColorPickerLayoutPopupScene = preload("res://src/ui_widgets/color_picker_layout_popup.tscn")
const EyedropperPopupScene = preload("res://src/ui_widgets/eyedropper_popup.tscn")

const handle_texture = preload("res://assets/icons/BWHandle.svg")
const slider_arrow = preload("res://assets/icons/SliderArrow.svg")
const side_slider_arrow = preload("res://assets/icons/SliderArrowSide.svg")
const bg_pattern = preload("res://assets/icons/CheckerboardMini.svg")

var alpha_enabled := false
var is_none_keyword_available := false
var is_current_color_keyword_available := false

var color_model_button_group := ButtonGroup.new()

var undo_redo := UndoRedoRef.new()

@onready var color_area: MarginContainer = $PickerArea/ColorAreaContainer
@onready var color_area_drawn: ColorRect = $PickerArea/ColorAreaContainer/ColorArea
@onready var primary_slider: MarginContainer = $PickerArea/PrimarySliderContainer
@onready var primary_slider_drawn: ColorRect = $PickerArea/PrimarySliderContainer/PrimarySlider

@onready var color_models_container: HBoxContainer = $SliderContainer/ColorModelContainer/ColorModels
@onready var color_models_button: Button = $SliderContainer/ColorModelContainer/ColorModelsButton
@onready var start_color_rect: Control = %ColorsDisplay/StartColorRect
@onready var color_rect: Control = %ColorsDisplay/ColorRect
@onready var keyword_button: Button = $ColorContainer/KeywordButton
@onready var reset_color_button: Button = %ColorsDisplay/ColorRect/ResetColorButton
@onready var eyedropper_button: Button = $ColorContainer/EyedropperButton
@onready var center: Vector2 = color_area_drawn.get_rect().get_center()

var color_area_surface := RenderingServer.canvas_item_create()
var primary_slider_surface := RenderingServer.canvas_item_create()

var primary_slider_dragged: bool = false
var sliders_dragged: Array[bool] = [false, false, false, false]
# Tracks are the color rects of the sliders.
@onready var tracks_arr: Array[ColorRect] = [%Slider1/MarginContainer/ColorTrack,
	%Slider2/MarginContainer/ColorTrack, %Slider3/MarginContainer/ColorTrack, %Slider4/MarginContainer/ColorTrack]
# Widgets are the margin containers that acts as click areas and draw the arrow.
@onready var widgets_arr: Array[MarginContainer] = [%Slider1/MarginContainer,
	%Slider2/MarginContainer, %Slider3/MarginContainer, %Slider4/MarginContainer]
# Fields are the number fields beside the color tracks.
@onready var fields_arr: Array[BetterLineEdit] = [
	%Slider1/IntField, %Slider2/IntField, %Slider3/IntField, %Slider4/IntField]
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
func setup_color(new_color: String, initial_color: String, default_color: Color) -> void:
	starting_color = initial_color
	color = new_color
	# Set up the display color.
	starting_display_color = ColorParser.text_to_color(starting_color, default_color, alpha_enabled)
	if Configs.savedata.color_picker_current_model == ColorPickerUtils.ColorModel.HSV:
		# Clamping like this doesn't change the hex representation, but it helps avoid
		# locking certain sliders (e.g. hue slider when saturation is 0).
		# The HVS order helps to keep the saturation at 0.0001 for some reason.
		starting_display_color.h = clampf(starting_display_color.h, 0.0, 0.9999)
		starting_display_color.v = clampf(starting_display_color.v, 0.0001, 1.0)
		starting_display_color.s = clampf(starting_display_color.s, 0.0001, 1.0)
	if not alpha_enabled:
		starting_display_color.a = 1
	display_color = ColorParser.text_to_color(new_color, default_color, alpha_enabled)
	update()


func sync_to_config() -> void:
	for child in color_models_container.get_children():
		child.queue_free()
	
	var normal_stylebox := StyleBoxFlat.new()
	normal_stylebox.bg_color = ThemeUtils.hover_overlay_color
	
	var hover_stylebox := normal_stylebox.duplicate()
	hover_stylebox.bg_color = ThemeUtils.strong_hover_overlay_color
	
	var focus_stylebox := StyleBoxFlat.new()
	focus_stylebox.draw_center = false
	focus_stylebox.set_border_width_all(2)
	focus_stylebox.border_color = ThemeUtils.focus_color
	
	var pressed_stylebox := StyleBoxFlat.new()
	pressed_stylebox.bg_color = ThemeUtils.hover_pressed_overlay_color
	pressed_stylebox.border_width_top = 2
	pressed_stylebox.content_margin_bottom = 2.0
	pressed_stylebox.border_color = Color(ThemeUtils.editable_text_color, 0.7)
	
	for active_color_model: ColorPickerUtils.ColorModel in Configs.savedata.color_picker_active_models:
		var btn := Button.new()
		btn.begin_bulk_theme_override()
		btn.add_theme_constant_override("align_to_largest_stylebox", 0)
		btn.add_theme_stylebox_override("normal", normal_stylebox)
		btn.add_theme_stylebox_override("hover", hover_stylebox)
		btn.add_theme_stylebox_override("focus", focus_stylebox)
		btn.add_theme_stylebox_override("pressed", pressed_stylebox)
		btn.add_theme_stylebox_override("hover_pressed", pressed_stylebox)
		btn.end_bulk_theme_override()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.button_group = color_model_button_group
		btn.toggle_mode = true
		btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		
		if active_color_model == Configs.savedata.color_picker_current_model:
			btn.button_pressed = true
		btn.pressed.connect(
			func() -> void:
				Configs.savedata.color_picker_current_model = active_color_model
				for button in color_model_button_group.get_buttons():
					button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
				_on_color_picker_layout_changed()
		)
		btn.text = ColorPickerUtils.color_model_to_string(active_color_model)
		color_models_container.add_child(btn)
	
	reset_color_button.add_theme_stylebox_override("focus", focus_stylebox)

# Workaround to set this after ready from external places.
func update_keyword_button() -> void:
	if is_none_keyword_available or is_current_color_keyword_available:
		keyword_button.tooltip_text = Translator.translate("Color keywords")
		keyword_button.pressed.connect(_on_keyword_button_pressed)
		keyword_button.show()

func sync_color_model_buttons_mouse_cursor_shape() -> void:
	for button in color_model_button_group.get_buttons():
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW if button == color_model_button_group.get_pressed_button() else Control.CURSOR_POINTING_HAND

func _ready() -> void:
	var shortcuts := ShortcutsRegistration.new()
	shortcuts.add_shortcut("ui_undo", undo_redo.undo)
	shortcuts.add_shortcut("ui_redo", undo_redo.redo)
	HandlerGUI.register_shortcuts(self, shortcuts)
	
	Configs.theme_changed.connect(sync_to_config)
	sync_to_config()
	# Set up signals.
	color_area.gui_input.connect(_on_color_area_gui_input)
	primary_slider_drawn.draw.connect(_on_primary_slider_draw)
	primary_slider.gui_input.connect(parse_primary_slider_input)
	
	start_color_rect.draw.connect(_on_start_color_rect_draw)
	color_rect.draw.connect(_on_color_rect_draw)
	reset_color_button.pressed.connect(_on_reset_color_button_pressed)
	
	for i in (range(0, 4) if alpha_enabled else range(0, 3)):
		widgets_arr[i].draw.connect(_on_hslider_draw.bind(i))
		widgets_arr[i].gui_input.connect(parse_slider_input.bind(i))
		tracks_arr[i].resized.connect(queue_redraw_widgets)
		fields_arr[i].text_submitted.connect(_on_slider_text_submitted.bind(i))
	if alpha_enabled:
		alpha_slider.visible = alpha_enabled
	_on_color_picker_layout_changed()
	
	color_model_button_group.pressed.connect(sync_color_model_buttons_mouse_cursor_shape.unbind(1))
	sync_color_model_buttons_mouse_cursor_shape.call()
	
	update_keyword_button()
	color_models_button.pressed.connect(_on_color_models_button_pressed)
	eyedropper_button.pressed.connect(_on_eyedropper_pressed)
	eyedropper_button.tooltip_text = Translator.translate("Eyedropper")
	# Set up the rest.
	RenderingServer.canvas_item_set_parent(color_area_surface, color_area_drawn.get_canvas_item())
	RenderingServer.canvas_item_set_parent(primary_slider_surface, primary_slider.get_canvas_item())
	
	var focus_sequence: Array[Control] = [primary_slider, keyword_button, reset_color_button, eyedropper_button]
	focus_sequence.append_array(color_models_container.get_children())
	focus_sequence.append(color_models_button)
	focus_sequence.append_array(fields_arr.slice(1))
	HandlerGUI.register_focus_sequence(self, focus_sequence)
	if keyword_button.visible:
		keyword_button.grab_focus(true)
	else:
		eyedropper_button.grab_focus(true)

func _exit_tree() -> void:
	RenderingServer.free_rid(color_area_surface)
	RenderingServer.free_rid(primary_slider_surface)


func _on_color_picker_layout_changed() -> void:
	match Configs.savedata.color_picker_current_model:
		ColorPickerUtils.ColorModel.RGB:
			tracks_arr[0].material.set_shader_parameter("interpolation", 1)
			tracks_arr[1].material.set_shader_parameter("interpolation", 2)
			tracks_arr[2].material.set_shader_parameter("interpolation", 3)
		ColorPickerUtils.ColorModel.HSV:
			tracks_arr[0].material.set_shader_parameter("interpolation", 4)
			tracks_arr[1].material.set_shader_parameter("interpolation", 5)
			tracks_arr[2].material.set_shader_parameter("interpolation", 6)
		ColorPickerUtils.ColorModel.HSL:
			tracks_arr[0].material.set_shader_parameter("interpolation", 7)
			tracks_arr[1].material.set_shader_parameter("interpolation", 8)
			tracks_arr[2].material.set_shader_parameter("interpolation", 9)
	if alpha_enabled:
		tracks_arr[3].material.set_shader_parameter("interpolation", 0)
	update()

func _on_color_models_button_pressed() -> void:
	var context_popup := ColorPickerLayoutPopupScene.instantiate()
	context_popup.color_picker_layout_changed.connect(sync_to_config)
	HandlerGUI.popup_under_rect_center(context_popup, color_models_button.get_global_rect(), get_viewport())


# If the change was continuous, like a color wheel adjustment, the backup color
# should be used as it stores the color from before the operation.
func register_visual_change(new_color: Color, use_backup := true) -> void:
	# Return early if the color didn't change. If the color is a keyword, all visual changes reset it to a normal color.
	if not color in ["none", "currentColor"] and new_color == (backup_display_color if use_backup else display_color):
		return
	
	undo_redo.create_action()
	undo_redo.add_do_method(set_color.bind(hex(new_color), new_color))
	if use_backup:
		undo_redo.add_undo_method(set_color.bind(backup_color, backup_display_color))
	else:
		undo_redo.add_undo_method(set_color.bind(color, display_color))
	undo_redo.commit_action()


func set_color(new_color: String, new_display_color: Color) -> void:
	if color == new_color:
		set_display_color(new_display_color)
	else:
		display_color = new_display_color
		color = new_color
		update()
		color_changed.emit(new_color)


func set_display_color(new_display_color: Color) -> void:
	display_color = new_display_color
	update()
	color_changed.emit(hex(new_display_color))

func update() -> void:
	# Adjust the shaders.
	primary_slider_drawn.material.set_shader_parameter("v", display_color.v)
	primary_slider_drawn.material.set_shader_parameter("base_color", Color.from_hsv(display_color.h, display_color.s, 1.0))
	tracks_arr[0].material.set_shader_parameter("base_color", display_color)
	tracks_arr[1].material.set_shader_parameter("base_color", display_color)
	tracks_arr[2].material.set_shader_parameter("base_color", display_color)
	if alpha_enabled:
		tracks_arr[3].material.set_shader_parameter("base_color", display_color)
	# Redraw widgets, color indicators, color wheel.
	color_rect.queue_redraw()
	start_color_rect.queue_redraw()
	queue_redraw()
	color_area_drawn.queue_redraw()
	queue_redraw_widgets()
	# Set the text of the color fields.
	slider_update(0)
	slider_update(1)
	slider_update(2)
	slider_update(3)
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


func _on_color_area_gui_input(event: InputEvent) -> void:
	var is_event_drag_start := Utils.is_event_drag_start(event)
	if is_event_drag_start:
		backup()
	var new_color := display_color
	if Utils.is_event_drag(event) or is_event_drag_start:
		var event_pos_on_wheel: Vector2 = event.position + color_area.position - color_area_drawn.position
		new_color.h = fposmod(center.angle_to_point(event_pos_on_wheel), TAU) / TAU
		new_color.s = minf(event_pos_on_wheel.distance_to(center) * 2 / color_area_drawn.size.x, 1.0)
		set_display_color(new_color)
	if Utils.is_event_drag_end(event):
		register_visual_change(display_color)

func start_slider_drag(idx: int) -> void:
	sliders_dragged[idx] = true
	backup()

func start_primary_slider_drag() -> void:
	primary_slider_dragged = true
	backup()

func set_primary_slider_offset(offset: float, register_change := false) -> void:
	var new_color := ColorPickerUtils.set_primary_slider_offset(display_color, offset)
	if register_change:
		register_visual_change(new_color, false)
	else:
		set_display_color(new_color)
	primary_slider_drawn.queue_redraw()

func set_slider_offset(index: int, offset: float, register_change := false) -> void:
	var new_color := ColorPickerUtils.set_channel_offset(display_color, index, offset)
	if register_change:
		register_visual_change(new_color, false)
	else:
		set_display_color(new_color)
	widgets_arr[index].queue_redraw()

func end_slider_drag(idx: int) -> void:
	register_visual_change(display_color)
	sliders_dragged[idx] = false
	widgets_arr[idx].queue_redraw()

func end_primary_slider_drag() -> void:
	register_visual_change(display_color)
	primary_slider_dragged = false
	primary_slider_drawn.queue_redraw()

func calculate_hslider_offset(index: int, pos: Vector2) -> float:
	return (pos.x - tracks_arr[index].position.x) / tracks_arr[index].size.x

func calculate_primary_slider_offset(pos: Vector2) -> float:
	return 1.0 - ((pos.y - primary_slider.position.y) / primary_slider.size.y)

func parse_primary_slider_input(event: InputEvent) -> void:
	var delta := 0.0
	if event.is_action_pressed("ui_down", true, true):
		delta -= 0.01
		accept_event()
	if event.is_action_pressed("ui_up", true, true):
		delta += 0.01
		accept_event()
	
	if not is_zero_approx(delta):
		if not primary_slider_dragged:
			start_primary_slider_drag()
		set_primary_slider_offset(display_color.v + delta)
	elif primary_slider_dragged:
		end_primary_slider_drag()
	
	if Utils.is_event_drag_start(event):
		start_primary_slider_drag()
		set_primary_slider_offset(calculate_primary_slider_offset(event.position))
	elif Utils.is_event_drag(event):
		set_primary_slider_offset(calculate_primary_slider_offset(event.position))
	elif Utils.is_event_drag_end(event):
		end_primary_slider_drag()

func parse_slider_input(event: InputEvent, index: int) -> void:
	if Utils.is_event_drag_start(event):
		start_slider_drag(index)
		set_slider_offset(index, calculate_hslider_offset(index, event.position))
	elif Utils.is_event_drag(event):
		set_slider_offset(index, calculate_hslider_offset(index, event.position))
	elif Utils.is_event_drag_end(event):
		end_slider_drag(index)

# When slider text is submitted, it should be clamped, used, and then the slider should
# be updated again so the text reflects the new value even if the color didn't change.
func _on_slider_text_submitted(new_text: String, index: int) -> void:
	var new_value := NumstringParser.evaluate(new_text)
	if is_nan(new_value):
		slider_update(index)
		return
	set_slider_offset(index, new_value / ColorPickerUtils.get_channel_fidelity(index), true)
	register_visual_change(display_color, false)
	slider_update(index)

func slider_update(index: int) -> void:
	fields_arr[index].text = String.num_uint64(roundi(
		ColorPickerUtils.get_channel_offset(display_color, index) * ColorPickerUtils.get_channel_fidelity(index)))


func _on_keyword_button_pressed() -> void:
	var btn_arr: Array[ContextButton] = []
	if is_none_keyword_available:
		btn_arr.append(ContextButton.create_custom("none", set_to_keyword.bind("none"),
			preload("res://assets/icons/NoneColor.svg"), color == "none"))
	if is_current_color_keyword_available:
		btn_arr.append(ContextButton.create_custom("currentColor", set_to_keyword.bind("currentColor"),
			preload("res://assets/icons/Paste.svg"), color == "currentColor"))
	
	for btn in btn_arr:
		btn.add_theme_font_override("font", ThemeUtils.mono_font)
	
	var context_popup := ContextPopup.create(btn_arr)
	HandlerGUI.popup_under_rect(context_popup, keyword_button.get_global_rect(), get_viewport())

func set_to_keyword(keyword: String) -> void:
	undo_redo.create_action()
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
	undo_redo.create_action()
	undo_redo.add_do_method(set_color.bind(starting_color, starting_display_color))
	undo_redo.add_undo_method(set_color.bind(color, display_color))
	undo_redo.commit_action()


# Gray out the start color rect if it's not actually a color.
func _on_start_color_rect_draw() -> void:
	var rect_size := start_color_rect.size
	var rect := Rect2(Vector2.ZERO, rect_size)
	if ColorParser.is_valid_url(starting_color):
		var cross_color := Color(0.8, 0.8, 0.8)
		start_color_rect.draw_rect(rect, Color(0.6, 0.6, 0.6))
		start_color_rect.draw_line(Vector2.ZERO, rect_size, cross_color, 0.5, true)
		start_color_rect.draw_line(Vector2(rect_size.x, 0), Vector2(0, rect_size.y), cross_color, 0.5, true)
	else:
		start_color_rect.draw_texture_rect(bg_pattern, rect, true)
		start_color_rect.draw_rect(rect, starting_display_color)

func _on_color_rect_draw() -> void:
	var rect := Rect2(Vector2.ZERO, color_rect.size)
	color_rect.draw_texture_rect(bg_pattern, rect, true)
	color_rect.draw_rect(rect, display_color)

# Draw inside the side slider to give it a little arrow to the side.
func _on_primary_slider_draw() -> void:
	RenderingServer.canvas_item_clear(primary_slider_surface)
	var arrow_modulate := ThemeUtils.tinted_contrast_color
	if not primary_slider_dragged:
		arrow_modulate.a = 0.7
	var arrow_y := primary_slider.position.y + primary_slider.size.y * (1 - display_color.v) - side_slider_arrow.get_height() / 2.0
	side_slider_arrow.draw(primary_slider_surface, Vector2(0, arrow_y), arrow_modulate)
	if primary_slider.has_focus(true):
		get_theme_stylebox("focus", "FlatButton").draw(primary_slider_surface, Rect2(Vector2(0, arrow_y), Vector2(side_slider_arrow.get_size())).grow(3))

func _draw() -> void:
	RenderingServer.canvas_item_clear(color_area_surface)
	# Draw the color wheel handle.
	var handle_texture_size := handle_texture.get_size()
	var point_pos := center + Vector2(center.x * cos(display_color.h * TAU), center.y * sin(display_color.h * TAU)) * display_color.s
	RenderingServer.canvas_item_add_texture_rect(color_area_surface, Rect2(point_pos - handle_texture_size / 2, handle_texture_size), handle_texture)


func queue_redraw_widgets() -> void:
	for i in 4:
		var widget := widgets_arr[i]
		if is_instance_valid(widget):
			widget.queue_redraw()
	primary_slider_drawn.queue_redraw()

# Helper for drawing the horizontal sliders.
func _on_hslider_draw(channel_index: int) -> void:
	var arrow_modulate := ThemeUtils.tinted_contrast_color
	if not sliders_dragged[channel_index]:
		arrow_modulate.a *= 0.7
	widgets_arr[channel_index].draw_texture(slider_arrow, Vector2(tracks_arr[channel_index].position.x + tracks_arr[channel_index].size.x *\
		ColorPickerUtils.get_channel_offset(display_color, channel_index) -\
		slider_arrow.get_width() / 2.0, tracks_arr[channel_index].size.y), arrow_modulate)
	widgets_arr[channel_index].draw_string(get_theme_default_font(), Vector2(-12, 11),
		ColorPickerUtils.get_channel_letter(channel_index), HORIZONTAL_ALIGNMENT_CENTER, 12, 14, ThemeUtils.text_color)


func update_color_button() -> void:
	if ColorParser.are_colors_same(starting_color, color):
		reset_color_button.disabled = true
		return
	reset_color_button.disabled = false
	
	var accent_hue_color := Color.from_hsv(ThemeUtils.accent_color.h, 1.0, 1.0)
	
	reset_color_button.begin_bulk_theme_override()
	if display_color.get_luminance() < 0.5:
		reset_color_button.add_theme_color_override("icon_hover_color", Color.WHITE)
		reset_color_button.add_theme_color_override("icon_focus_color", Color.WHITE)
		reset_color_button.add_theme_color_override("icon_pressed_color", accent_hue_color.lerp(Color.WHITE, 0.76))
	else:
		reset_color_button.add_theme_color_override("icon_hover_color", Color.BLACK)
		reset_color_button.add_theme_color_override("icon_focus_color", Color.BLACK)
		reset_color_button.add_theme_color_override("icon_pressed_color", accent_hue_color.lerp(Color.BLACK, 0.64))
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


func _on_eyedropper_pressed() -> void:
	var eyedropper_popup := EyedropperPopupScene.instantiate()
	eyedropper_popup.color_picked.connect(register_visual_change.bind(false))
	HandlerGUI.add_popup(eyedropper_popup, false)
