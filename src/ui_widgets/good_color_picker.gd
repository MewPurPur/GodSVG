extends VBoxContainer

const ColorPickerLayoutPopupScene = preload("res://src/ui_widgets/color_picker_layout_popup.tscn")
const EyedropperPopupScene = preload("res://src/ui_widgets/eyedropper_popup.tscn")

const handle_texture = preload("res://assets/icons/BWHandle.svg")
const slider_arrow = preload("res://assets/icons/SliderArrow.svg")
const side_slider_arrow = preload("res://assets/icons/SliderArrowSide.svg")
const bg_pattern = preload("res://assets/icons/CheckerboardMini.svg")

const KEYBOARD_DELAY_DURATION = 0.5

var alpha_enabled := false
var is_none_keyword_available := false
var is_current_color_keyword_available := false

var color_model_button_group := ButtonGroup.new()

var undo_redo := UndoRedoRef.new()

@onready var color_models_container: HBoxContainer = $SliderContainer/ColorModelContainer/ColorModels
@onready var color_models_button: Button = $SliderContainer/ColorModelContainer/ColorModelsButton
@onready var start_color_rect: Control = %ColorsDisplay/StartColorRect
@onready var color_rect: Control = %ColorsDisplay/ColorRect
@onready var keyword_button: Button = $ColorContainer/KeywordButton
@onready var reset_color_button: Button = %ColorsDisplay/ColorRect/ResetColorButton
@onready var eyedropper_button: Button = $ColorContainer/EyedropperButton
@onready var alpha_slider: HBoxContainer = %Slider4


@onready var color_area: MarginContainer = $PickerArea/ColorAreaInputArea
@onready var color_area_drawn: ColorRect = $PickerArea/ColorAreaInputArea/ColorArea
var color_area_surface := RenderingServer.canvas_item_create()
var color_area_dragged := false
var color_area_scrolled_time := -1.0

@onready var primary_slider: MarginContainer = $PickerArea/PrimarySliderInputArea
@onready var primary_slider_drawn: ColorRect = $PickerArea/PrimarySliderInputArea/PrimarySlider
var primary_slider_surface := RenderingServer.canvas_item_create()
var primary_slider_dragged := false
var primary_slider_scrolled_time := -1.0

# Tracks are the color rects of the sliders.
@onready var tracks_arr: Array[ColorRect] = [%Slider1/InputArea/Track, %Slider2/InputArea/Track, %Slider3/InputArea/Track, %Slider4/InputArea/Track]
# Widgets are the margin containers that acts as click areas and draw the arrow.
@onready var widgets_arr: Array[MarginContainer] = [%Slider1/InputArea, %Slider2/InputArea, %Slider3/InputArea, %Slider4/InputArea]
# Fields are the number fields beside the color tracks.
var hslider_surfaces: Array[RID] = [RenderingServer.canvas_item_create(), RenderingServer.canvas_item_create(),
		RenderingServer.canvas_item_create(), RenderingServer.canvas_item_create()]
var hsliders_dragged: Array[bool] = [false, false, false, false]
var hsliders_scrolled_time: PackedFloat32Array = [-1.0, -1.0, -1.0, -1.0]

@onready var fields_arr: Array[BetterLineEdit] = [%Slider1/IntField, %Slider2/IntField, %Slider3/IntField, %Slider4/IntField]

# Paints refer to any string, including keywords and references.
# This variable stores what the color string was at the start, for the reset button.
var starting_paint: String
var starting_display_color: ColorPickerUtils.PreciseColor
# These store the old color when using keywords or starting a dragging operation.
var backup_paint: String
var backup_display_color: ColorPickerUtils.PreciseColor
# These store the current color string, normally forced to hex.
var paint: String
var display_color: ColorPickerUtils.PreciseColor

signal color_changed(new_color: String)


# To be called right after the color picker is added.
func setup_color(new_paint: String, initial_paint: String, default_color: Color) -> void:
	starting_paint = initial_paint
	paint = new_paint
	# Set up the display color.
	starting_display_color = ColorPickerUtils.PreciseColor.from_color(ColorParser.text_to_color(starting_paint, default_color, alpha_enabled))
	starting_display_color.shift_hsv()
	if not alpha_enabled:
		starting_display_color.a = 1
	display_color = ColorPickerUtils.PreciseColor.from_color(ColorParser.text_to_color(new_paint, default_color, alpha_enabled))
	display_color.shift_hsv()
	backup_display_color = display_color.duplicate()
	backup_paint = new_paint
	color_changed.connect(sync_to_color.unbind(1))
	sync_to_color()

func sync_to_config() -> void:
	for child in color_models_container.get_children():
		color_models_container.remove_child(child)
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
	_on_color_picker_layout_changed()


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
	primary_slider.gui_input.connect(parse_primary_slider_input)
	primary_slider.focus_entered.connect(primary_slider.queue_redraw)
	primary_slider.focus_exited.connect(primary_slider.queue_redraw)
	reset_color_button.pressed.connect(_on_reset_color_button_pressed)
	
	start_color_rect.draw.connect(_on_start_color_rect_draw)
	color_rect.draw.connect(_on_color_rect_draw)
	color_area.draw.connect(_on_color_area_draw)
	primary_slider.draw.connect(_on_primary_slider_draw)
	
	for i in (range(0, 4) if alpha_enabled else range(0, 3)):
		widgets_arr[i].draw.connect(_on_hslider_draw.bind(i))
		widgets_arr[i].gui_input.connect(parse_hslider_input.bind(i))
		tracks_arr[i].resized.connect(sync_to_color)
		fields_arr[i].text_submitted.connect(_on_hslider_text_submitted.bind(i))
	if alpha_enabled:
		alpha_slider.visible = alpha_enabled
	
	color_model_button_group.pressed.connect(sync_color_model_buttons_mouse_cursor_shape.unbind(1))
	sync_color_model_buttons_mouse_cursor_shape.call()
	
	if is_none_keyword_available or is_current_color_keyword_available:
		keyword_button.tooltip_text = Translator.translate("Color keywords")
		keyword_button.pressed.connect(_on_keyword_button_pressed)
		keyword_button.show()
	
	color_models_button.pressed.connect(_on_color_models_button_pressed)
	eyedropper_button.pressed.connect(_on_eyedropper_pressed)
	eyedropper_button.tooltip_text = Translator.translate("Eyedropper")
	# Set up the rest.
	RenderingServer.canvas_item_set_parent(color_area_surface, color_area.get_canvas_item())
	RenderingServer.canvas_item_set_parent(primary_slider_surface, primary_slider.get_canvas_item())
	for idx in widgets_arr.size():
		RenderingServer.canvas_item_set_parent(hslider_surfaces[idx], widgets_arr[idx].get_canvas_item())
	
	_on_color_picker_layout_changed()
	if keyword_button.visible:
		keyword_button.grab_focus(true)
	else:
		eyedropper_button.grab_focus(true)

func register_focus_sequence() -> void:
	var focus_sequence: Array[Control] = [color_area, primary_slider, keyword_button, reset_color_button, eyedropper_button]
	focus_sequence.append_array(color_models_container.get_children())
	focus_sequence.append(color_models_button)
	focus_sequence.append_array(widgets_arr)
	focus_sequence.append_array(fields_arr)
	HandlerGUI.register_focus_sequence(self, focus_sequence)

func _exit_tree() -> void:
	RenderingServer.free_rid(color_area_surface)
	RenderingServer.free_rid(primary_slider_surface)
	for surface in hslider_surfaces:
		RenderingServer.free_rid(surface)


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
			tracks_arr[0].material.set_shader_parameter("interpolation", 4)
			tracks_arr[1].material.set_shader_parameter("interpolation", 7)
			tracks_arr[2].material.set_shader_parameter("interpolation", 8)
	if alpha_enabled:
		tracks_arr[3].material.set_shader_parameter("interpolation", 0)
	
	match Configs.savedata.color_picker_current_shape:
		ColorPickerUtils.PickerShape.HS_V_CIRCLE:
			color_area_drawn.material.set_shader_parameter("interpolation", 0)
			primary_slider_drawn.material.set_shader_parameter("interpolation", 6)
		ColorPickerUtils.PickerShape.HS_L_CIRCLE:
			color_area_drawn.material.set_shader_parameter("interpolation", 1)
			primary_slider_drawn.material.set_shader_parameter("interpolation", 8)
		ColorPickerUtils.PickerShape.SV_H_SQUARE:
			color_area_drawn.material.set_shader_parameter("interpolation", 2)
			primary_slider_drawn.material.set_shader_parameter("interpolation", 4)
		ColorPickerUtils.PickerShape.SL_H_SQUARE:
			color_area_drawn.material.set_shader_parameter("interpolation", 3)
			primary_slider_drawn.material.set_shader_parameter("interpolation", 4)
	sync_to_color()
	register_focus_sequence()

func _on_color_models_button_pressed() -> void:
	var context_popup := ColorPickerLayoutPopupScene.instantiate()
	context_popup.color_picker_layout_changed.connect(sync_to_config)
	HandlerGUI.popup_under_rect_center(context_popup, color_models_button.get_global_rect(), get_viewport())


func register_visual_change() -> void:
	if Color.html_is_valid(paint) and display_color.equals(backup_display_color):
		return
	
	undo_redo.create_action()
	undo_redo.add_do_method(set_color.bind(hex(), display_color.to_array()))
	undo_redo.add_undo_method(set_color.bind(backup_paint, backup_display_color.to_array()))
	undo_redo.commit_action()

func register_keyword_change(keyword: String) -> void:
	if keyword == paint.strip_edges():
		return
	
	var display_color_array := display_color.to_array()
	undo_redo.create_action()
	undo_redo.add_do_method(set_color.bind(keyword, display_color_array))
	undo_redo.add_undo_method(set_color.bind(backup_paint, display_color_array))
	undo_redo.commit_action()
	
	backup_paint = paint.strip_edges()
	backup_display_color.copy_values_from(display_color)

func set_color(new_paint: String, new_display_color_array: PackedFloat64Array) -> void:
	display_color = ColorPickerUtils.PreciseColor.from_array(new_display_color_array)
	backup_display_color.copy_values_from(display_color)
	backup_paint = hex()
	if paint == new_paint:
		color_changed.emit(hex())
	else:
		paint = new_paint
		color_changed.emit(new_paint)


func sync_to_color() -> void:
	# Adjust the shaders.
	if is_instance_valid(display_color):
		var display_regular_color := display_color.to_color()
		match Configs.savedata.color_picker_current_shape:
			ColorPickerUtils.PickerShape.HS_V_CIRCLE:
				primary_slider_drawn.material.set_shader_parameter("base_color", display_regular_color)
				color_area_drawn.material.set_shader_parameter("third_value", 1.0)
			ColorPickerUtils.PickerShape.HS_L_CIRCLE:
				primary_slider_drawn.material.set_shader_parameter("base_color", display_regular_color)
				color_area_drawn.material.set_shader_parameter("third_value", 0.5)
			ColorPickerUtils.PickerShape.SV_H_SQUARE, ColorPickerUtils.PickerShape.SL_H_SQUARE:
				primary_slider_drawn.material.set_shader_parameter("base_color", Color.RED)
				color_area_drawn.material.set_shader_parameter("third_value", display_color.get_hue())
		for i in (range(0, 4) if alpha_enabled else range(0, 3)):
			tracks_arr[i].material.set_shader_parameter("base_color", display_regular_color)
			sync_hslider(i)
	# Full redraw.
	for i in 4:
		var widget := widgets_arr[i]
		if is_instance_valid(widget):
			widget.queue_redraw()
	primary_slider.queue_redraw()
	color_area.queue_redraw()
	color_rect.queue_redraw()
	start_color_rect.queue_redraw()
	# Update color button.
	if ColorParser.are_colors_same(starting_paint, paint):
		reset_color_button.disabled = true
		return
	reset_color_button.disabled = false
	
	var accent_hue_color := Color.from_hsv(ThemeUtils.accent_color.h, 1.0, 1.0)
	
	reset_color_button.begin_bulk_theme_override()
	if display_color.get_luminance_imprecise() < 0.45:
		reset_color_button.add_theme_color_override("icon_hover_color", Color.WHITE)
		reset_color_button.add_theme_color_override("icon_focus_color", Color.WHITE)
		reset_color_button.add_theme_color_override("icon_pressed_color", accent_hue_color.lerp(Color.WHITE, 0.76))
	else:
		reset_color_button.add_theme_color_override("icon_hover_color", Color.BLACK)
		reset_color_button.add_theme_color_override("icon_focus_color", Color.BLACK)
		reset_color_button.add_theme_color_override("icon_pressed_color", accent_hue_color.lerp(Color.BLACK, 0.64))
	reset_color_button.end_bulk_theme_override()


# Implements keyboard control for the widgets.
func _process(delta: float) -> void:
	if primary_slider.has_focus():
		var axis := Input.get_axis("ui_down", "ui_up")
		if not is_zero_approx(axis):
			if not primary_slider.has_focus(true):
				primary_slider.grab_focus()
			var offset_change := 0.0
			if primary_slider_scrolled_time < 0:
				primary_slider_scrolled_time = 0.0
				offset_change = 0.01
			elif primary_slider_scrolled_time > KEYBOARD_DELAY_DURATION:
				offset_change = clampf(snappedf(primary_slider_scrolled_time * delta, 0.01), 0.01, 0.05)
			primary_slider_scrolled_time += delta
			ColorPickerUtils.set_primary_slider_offset(display_color, ColorPickerUtils.get_primary_slider_offset(display_color) + offset_change * axis)
			color_changed.emit(hex())
		elif primary_slider_scrolled_time >= 0:
			primary_slider_scrolled_time = -1.0
			register_visual_change()
	elif primary_slider_scrolled_time >= 0:
		primary_slider_scrolled_time = -1.0
		register_visual_change()
	
	for index in widgets_arr.size():
		var hslider := widgets_arr[index]
		if hslider.has_focus():
			var axis := Input.get_axis("ui_left", "ui_right")
			if not is_zero_approx(axis):
				if not hslider.has_focus(true):
					hslider.grab_focus()
				var offset_change := 0.0
				if hsliders_scrolled_time[index] < 0:
					hsliders_scrolled_time[index] = 0.0
					offset_change = 1.0 / ColorPickerUtils.get_channel_fidelity(index)
				elif hsliders_scrolled_time[index] > KEYBOARD_DELAY_DURATION:
					offset_change = clampf(snappedf(hsliders_scrolled_time[index] * delta, 0.01), 0.01, 0.05)
				hsliders_scrolled_time[index] += delta
				ColorPickerUtils.set_channel_offset(display_color, index, ColorPickerUtils.get_channel_offset(display_color, index) + offset_change * axis)
				color_changed.emit(hex())
			elif hsliders_scrolled_time[index] >= 0:
				hsliders_scrolled_time[index] = -1.0
				register_visual_change()
		elif hsliders_scrolled_time[index] >= 0:
			hsliders_scrolled_time[index] = -1.0
			register_visual_change()
	
	if color_area.has_focus():
		var vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if not vector.is_zero_approx():
			if not color_area.has_focus(true):
				color_area.grab_focus()
			var offset_change := 0.0
			if color_area_scrolled_time < 0:
				color_area_scrolled_time = 0.0
				offset_change = 0.01
			elif color_area_scrolled_time > KEYBOARD_DELAY_DURATION:
				offset_change = clampf(snappedf(color_area_scrolled_time * delta, 0.01), 0.01, 0.05)
			color_area_scrolled_time += delta
			ColorPickerUtils.set_color_area_coordinates(display_color, ColorPickerUtils.get_color_area_coordinates(display_color) + vector * offset_change)
			color_changed.emit(hex())
		elif color_area_scrolled_time >= 0:
			color_area_scrolled_time = -1.0
			register_visual_change()
	elif color_area_scrolled_time >= 0:
		color_area_scrolled_time = -1.0
		register_visual_change()


func _on_color_area_gui_input(event: InputEvent) -> void:
	for action_name in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		if event.is_action_pressed(action_name, true, true):
			accept_event()
	
	var should_change_offset := false
	if Utils.is_event_drag_start(event):
		color_area_dragged = true
		should_change_offset = true
	elif color_area_dragged:
		if Utils.is_event_drag(event):
			should_change_offset = true
		elif Utils.is_event_drag_end(event):
			color_area_dragged = false
			register_visual_change()
			return
	
	if should_change_offset:
		ColorPickerUtils.set_color_area_coordinates(display_color, (event.position + color_area.position - color_area_drawn.position) / color_area_drawn.size)
		color_changed.emit(hex())

func parse_primary_slider_input(event: InputEvent) -> void:
	match ColorPickerUtils.get_current_picker_shape_geometric_shape():
		ColorPickerUtils.PickerGeometricShape.CIRCLE_AND_BAR, ColorPickerUtils.PickerGeometricShape.SQUARE_AND_BAR:
			for action_name in ["ui_down", "ui_up", "ui_left", "ui_right"]:
				if event.is_action_pressed(action_name, true, true):
					accept_event()
			
			var should_change_offset := false
			if Utils.is_event_drag_start(event):
				primary_slider_dragged = true
				should_change_offset = true
			elif primary_slider_dragged:
				if Utils.is_event_drag(event):
					should_change_offset = true
				elif Utils.is_event_drag_end(event):
					primary_slider_dragged = false
					register_visual_change()
					return
			
			if should_change_offset:
				var new_offset: float
				match ColorPickerUtils.get_current_picker_shape_geometric_shape():
					ColorPickerUtils.PickerGeometricShape.CIRCLE_AND_BAR, ColorPickerUtils.PickerGeometricShape.SQUARE_AND_BAR:
						new_offset = 1.0 - (event.position.y - primary_slider_drawn.position.y) / primary_slider_drawn.size.y
				ColorPickerUtils.set_primary_slider_offset(display_color, new_offset)
				color_changed.emit(hex())

func parse_hslider_input(event: InputEvent, index: int) -> void:
	for action_name in ["ui_left", "ui_right"]:
		if event.is_action_pressed(action_name, true, true):
			accept_event()
	
	var should_change_offset := false
	if Utils.is_event_drag_start(event):
		hsliders_dragged[index] = true
		should_change_offset = true
	elif hsliders_dragged[index]:
		if Utils.is_event_drag(event):
			should_change_offset = true
		elif Utils.is_event_drag_end(event):
			hsliders_dragged[index] = false
			register_visual_change()
			return
	
	if should_change_offset:
		ColorPickerUtils.set_channel_offset(display_color, index,
				(event.position.x - tracks_arr[index].position.x) / tracks_arr[index].size.x)
		color_changed.emit(hex())

# When slider text is submitted, it should be clamped, used, and then the slider should
# be updated again so the text reflects the new value even if the color didn't change.
func _on_hslider_text_submitted(new_text: String, index: int) -> void:
	var new_value := NumstringParser.evaluate(new_text)
	if is_nan(new_value):
		sync_hslider(index)
		return
	ColorPickerUtils.set_channel_offset(display_color, index, new_value / ColorPickerUtils.get_channel_fidelity(index))
	register_visual_change()
	widgets_arr[index].queue_redraw()
	sync_hslider(index)

func sync_hslider(index: int) -> void:
	fields_arr[index].text = String.num_uint64(roundi(ColorPickerUtils.get_channel_offset(display_color, index) * ColorPickerUtils.get_channel_fidelity(index)))


func _on_keyword_button_pressed() -> void:
	var btn_arr: Array[ContextButton] = []
	if is_none_keyword_available:
		btn_arr.append(ContextButton.create_custom("none", register_keyword_change.bind("none"),
			preload("res://assets/icons/NoneColor.svg"), paint == "none"))
	if is_current_color_keyword_available:
		btn_arr.append(ContextButton.create_custom("currentColor", register_keyword_change.bind("currentColor"),
			preload("res://assets/icons/Paste.svg"), paint == "currentColor"))
	
	for btn in btn_arr:
		btn.add_theme_font_override("font", ThemeUtils.mono_font)
	HandlerGUI.popup_under_rect(ContextPopup.create(btn_arr), keyword_button.get_global_rect(), get_viewport())

func _on_reset_color_button_pressed() -> void:
	display_color.copy_values_from(starting_display_color)
	paint = starting_paint
	register_visual_change()


# Gray out the start color rect if it's not actually a color.
func _on_start_color_rect_draw() -> void:
	var rect_size := start_color_rect.size
	var rect := Rect2(Vector2.ZERO, rect_size)
	if ColorParser.is_valid_url(starting_paint):
		var cross_color := Color(0.8, 0.8, 0.8)
		start_color_rect.draw_rect(rect, Color(0.6, 0.6, 0.6))
		start_color_rect.draw_line(Vector2.ZERO, rect_size, cross_color, 0.5, true)
		start_color_rect.draw_line(Vector2(rect_size.x, 0), Vector2(0, rect_size.y), cross_color, 0.5, true)
	else:
		start_color_rect.draw_texture_rect(bg_pattern, rect, true)
		start_color_rect.draw_rect(rect, starting_display_color.to_color())

func _on_color_rect_draw() -> void:
	var rect := Rect2(Vector2.ZERO, color_rect.size)
	color_rect.draw_texture_rect(bg_pattern, rect, true)
	color_rect.draw_rect(rect, display_color.to_color())

func _on_color_area_draw() -> void:
	RenderingServer.canvas_item_clear(color_area_surface)
	var handle_texture_size := handle_texture.get_size()
	var point_pos := color_area_drawn.position
	match ColorPickerUtils.get_current_picker_shape_geometric_shape():
		ColorPickerUtils.PickerGeometricShape.CIRCLE_AND_BAR:
			var angle_value := display_color.get_hue()
			var distance_value: float
			match Configs.savedata.color_picker_current_shape:
				ColorPickerUtils.PickerShape.HS_V_CIRCLE:
					distance_value = ColorPickerUtils.get_channel_offset_for_model(display_color, 1, ColorPickerUtils.ColorModel.HSV)
				ColorPickerUtils.PickerShape.HS_L_CIRCLE:
					distance_value = ColorPickerUtils.get_channel_offset_for_model(display_color, 1, ColorPickerUtils.ColorModel.HSL)
			point_pos += color_area_drawn.size / 2 * (Vector2(1, 1) + Vector2.from_angle(angle_value * TAU) * distance_value)
		ColorPickerUtils.PickerGeometricShape.SQUARE_AND_BAR:
			var horizontal_value: float
			var vertical_value: float
			match Configs.savedata.color_picker_current_shape:
				ColorPickerUtils.PickerShape.SV_H_SQUARE:
					horizontal_value = ColorPickerUtils.get_channel_offset_for_model(display_color, 1, ColorPickerUtils.ColorModel.HSV)
					vertical_value = ColorPickerUtils.get_channel_offset_for_model(display_color, 2, ColorPickerUtils.ColorModel.HSV)
				ColorPickerUtils.PickerShape.SL_H_SQUARE:
					horizontal_value = ColorPickerUtils.get_channel_offset_for_model(display_color, 1, ColorPickerUtils.ColorModel.HSL)
					vertical_value = ColorPickerUtils.get_channel_offset_for_model(display_color, 2, ColorPickerUtils.ColorModel.HSL)
			point_pos += Vector2(horizontal_value, 1 - vertical_value) * color_area_drawn.size
	RenderingServer.canvas_item_add_texture_rect(color_area_surface, Rect2(point_pos - handle_texture_size / 2, handle_texture_size), handle_texture)
	if color_area.has_focus(true):
		get_theme_stylebox("focus", "FlatButton").draw(color_area_surface, Rect2(point_pos - Vector2(8, 8), Vector2(16, 16)))

func _on_primary_slider_draw() -> void:
	RenderingServer.canvas_item_clear(primary_slider_surface)
	var arrow_modulate := ThemeUtils.tinted_contrast_color
	if not primary_slider_dragged and primary_slider_scrolled_time < 0:
		arrow_modulate.a = 0.7
	var arrow_y := primary_slider_drawn.size.y * (1 - ColorPickerUtils.get_primary_slider_offset(display_color)) +\
			primary_slider_drawn.position.y - side_slider_arrow.get_height() / 2.0
	side_slider_arrow.draw(primary_slider_surface, Vector2(0, arrow_y), arrow_modulate)
	if primary_slider.has_focus(true):
		get_theme_stylebox("focus", "FlatButton").draw(primary_slider_surface, Rect2(Vector2(0, arrow_y), Vector2(side_slider_arrow.get_size())).grow(3))

func _on_hslider_draw(index: int) -> void:
	var surface := hslider_surfaces[index]
	RenderingServer.canvas_item_clear(surface)
	var arrow_modulate := ThemeUtils.tinted_contrast_color
	if not hsliders_dragged[index]:
		arrow_modulate.a *= 0.7
	get_theme_default_font().draw_string(surface, Vector2(-12, 11), ColorPickerUtils.get_channel_letter(index),
			HORIZONTAL_ALIGNMENT_CENTER, 12, 14, ThemeUtils.text_color)
	var arrow_x := tracks_arr[index].position.x + tracks_arr[index].size.x *\
			ColorPickerUtils.get_channel_offset(display_color, index) - slider_arrow.get_width() / 2.0
	slider_arrow.draw(surface, Vector2(arrow_x, tracks_arr[index].size.y), arrow_modulate)
	if widgets_arr[index].has_focus(true):
		get_theme_stylebox("focus", "FlatButton").draw(surface, Rect2(Vector2(arrow_x, tracks_arr[index].size.y), Vector2(slider_arrow.get_size())).grow(3))


func hex() -> String:
	# Removing the saturation and hue clamping fixes hex conversion in edge cases.
	# e.g., H = 0.0001, S = 0.0001, V = 0.5 --> Color(0.5, 0.4999, 0.4999) --> "807f7f".
	var color := display_color.duplicate()
	color.set_saturation(snappedf(color.get_saturation(), 1/1600.0))
	color.set_hue(snappedf(color.get_hue(), 1/5760.0))
	return color.to_color().to_html(alpha_enabled and color.a != 1.0)


func _on_eyedropper_pressed() -> void:
	var eyedropper_popup := EyedropperPopupScene.instantiate()
	eyedropper_popup.color_picked.connect(_on_eyedropper_color_picker)
	HandlerGUI.add_popup(eyedropper_popup, false)

func _on_eyedropper_color_picker(new_color: Color) -> void:
	display_color = ColorPickerUtils.PreciseColor.from_color(new_color)
	color_changed.emit(hex())
	register_visual_change()
