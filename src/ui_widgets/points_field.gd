# An editor to be tied to a points attribute.
extends VBoxContainer

var element: Element
const attribute_name = "points"  # Never propagates.

# So, about this editor. Most of this code is about implementing a huge optimization.
# All the points are a single node that draws fake-outs in order to prevent
# adding too many nodes to the scene tree. The real controls are only created when
# necessary, such as when hovered or focused.

const STRIP_HEIGHT = 22.0

signal focused

const MiniNumberField = preload("mini_number_field.tscn")

const more_icon = preload("res://visual/icons/SmallMore.svg")
const plus_icon = preload("res://visual/icons/Plus.svg")

var mini_line_edit_stylebox := get_theme_stylebox("normal", "MiniLineEdit")
var mini_line_edit_font_size := get_theme_font_size("font_size", "MiniLineEdit")
var mini_line_edit_font_color := get_theme_color("font_color", "MiniLineEdit")

@onready var line_edit: LineEdit = $LineEdit
@onready var points_container: Control = $Points

# Variables around the big optimization.
# The idea is that when the mouse enters a strip, it's remembered as hovered.
# If a numfield is focused, its strip is remembered as focused.
# If a numfield is hovered and then focused, the controls aren't re-added,
# instead, the references are moved from the hovered to the focused fields array.
# If a focused field is hovered, no hovered fields are added.
var hovered_idx := -1
var focused_idx := -1
var hovered_strip: Control
var focused_strip: Control

var current_selections: Array[int] = []
var current_hovered: int = -1
@onready var ci := points_container.get_canvas_item()
var add_move_button: Control


func set_value(new_value: String, save := false) -> void:
	element.set_attribute(attribute_name, new_value)
	sync(element.get_attribute(attribute_name).get_value())
	if save:
		SVG.queue_save()

func sync_to_attribute() -> void:
	set_value(element.get_attribute_value(attribute_name))


func setup() -> void:
	GlobalSettings.language_changed.connect(update_translation)
	sync_to_attribute()
	element.attribute_changed.connect(_on_element_attribute_changed)
	line_edit.tooltip_text = attribute_name
	line_edit.text_submitted.connect(set_value.bind(true))
	line_edit.text_changed.connect(setup_font)
	line_edit.text_change_canceled.connect(func(): setup_font(line_edit.text))
	line_edit.focus_entered.connect(_on_line_edit_focus_entered)
	points_container.draw.connect(points_draw)
	points_container.gui_input.connect(_on_points_gui_input)
	points_container.mouse_exited.connect(_on_points_mouse_exited)
	Indications.hover_changed.connect(_on_selections_or_hover_changed)
	Indications.selection_changed.connect(_on_selections_or_hover_changed)
	update_translation()


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync_to_attribute()

func update_translation() -> void:
	line_edit.placeholder_text = Translator.translate("No points")

func _on_line_edit_focus_entered() -> void:
	focused.emit()

func setup_font(new_text: String) -> void:
	if new_text.is_empty():
		line_edit.add_theme_font_override("font", ThemeUtils.regular_font)
	else:
		line_edit.remove_theme_font_override("font")

func sync(new_value: String) -> void:
	line_edit.text = new_value
	setup_font(new_value)
	# A plus button for adding a first point if empty.
	var points_count: int = element.get_attribute(attribute_name).get_list_size() / 2
	if points_count == 0 and not is_instance_valid(add_move_button):
		add_move_button = Button.new()
		add_move_button.icon = plus_icon
		add_move_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		add_move_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		add_move_button.focus_mode = Control.FOCUS_NONE
		add_move_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_move_button.theme_type_variation = "FlatButton"
		add_child(add_move_button)
		add_move_button.pressed.connect(_on_add_move_button_pressed)
	elif points_count != 0 and is_instance_valid(add_move_button):
		add_move_button.queue_free()
	# Rebuild the points.
	points_container.custom_minimum_size.y = points_count * STRIP_HEIGHT
	Utils.throw_mouse_motion_event()
	if hovered_idx >= points_count:
		activate_hovered(-1)
	reactivate_hovered()
	points_container.queue_redraw()


func update_point_x_coordinate(new_value: float, idx: int) -> void:
	var list := element.get_attribute_list(attribute_name)
	list[idx * 2] = new_value
	element.get_attribute(attribute_name).set_list(list)
	SVG.queue_save()

func update_point_y_coordinate(new_value: float, idx: int) -> void:
	var list := element.get_attribute_list(attribute_name)
	list[idx * 2 + 1] = new_value
	element.get_attribute(attribute_name).set_list(list)
	SVG.queue_save()

func _on_add_move_button_pressed() -> void:
	element.get_attribute(attribute_name).set_list(PackedFloat64Array([0.0, 0.0]))
	SVG.queue_save()


# Points editor orchestration.

func _on_selections_or_hover_changed() -> void:
	var new_selections: Array[int] = []
	if Indications.semi_selected_xid == element.xid:
		new_selections = Indications.inner_selections
	var new_hovered: int = -1
	if Indications.semi_hovered_xid == element.xid:
		new_hovered = Indications.inner_hovered
	# Only redraw if selections or hovered changed.
	if new_selections != current_selections:
		# TODO Figure out why the fuck must I duplicate it.
		current_selections = new_selections.duplicate()
		points_container.queue_redraw()
	if new_hovered != current_hovered:
		current_hovered = new_hovered
		points_container.queue_redraw()

func _on_points_mouse_exited() -> void:
	var cmd_idx := Indications.inner_hovered
	if Indications.semi_hovered_xid == element.xid:
		activate_hovered(-1)
	Indications.remove_hovered(element.xid, cmd_idx)


# Prevents buttons from selecting a whole subpath when double-clicked.
func _eat_double_clicks(event: InputEvent, button: Button) -> void:
	if hovered_idx >= 0 and event is InputEventMouseButton and event.double_click:
		button.accept_event()
		if event.is_pressed():
			if button.toggle_mode:
				button.toggled.emit(not button.button_pressed)
			else:
				button.pressed.emit()

func _on_points_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return
	
	var cmd_idx := -1
	var event_pos: Vector2 = event.position
	if Rect2(Vector2.ZERO, points_container.get_size()).has_point(event_pos):
		cmd_idx = int(event_pos.y / STRIP_HEIGHT)
	
	if event is InputEventMouseMotion and event.button_mask == 0:
		if cmd_idx >= 0:
			Indications.set_hovered(element.xid, cmd_idx)
		else:
			Indications.remove_hovered(element.xid, cmd_idx)
		activate_hovered(cmd_idx)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if event.double_click:
					Indications.normal_select(element.xid, 0)
					Indications.shift_select(element.xid,
							element.get_attribute(attribute_name).get_list_size() / 2)
				elif event.is_command_or_control_pressed():
					Indications.ctrl_select(element.xid, cmd_idx)
				elif event.shift_pressed:
					Indications.shift_select(element.xid, cmd_idx)
				else:
					Indications.normal_select(element.xid, cmd_idx)
			elif event.is_released() and not event.shift_pressed and\
			not event.is_command_or_control_pressed() and not event.double_click and\
			Indications.inner_selections.size() > 1 and\
			cmd_idx in Indications.inner_selections:
				Indications.normal_select(element.xid, cmd_idx)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if Indications.semi_selected_xid != element.xid or\
			not cmd_idx in Indications.inner_selections:
				Indications.normal_select(element.xid, cmd_idx)
			# Popup the actions.
			var viewport := get_viewport()
			var popup_pos := viewport.get_mouse_position()
			HandlerGUI.popup_under_pos(Indications.get_selection_context(
					HandlerGUI.popup_under_pos.bind(popup_pos, viewport),
					Indications.Context.LIST), popup_pos, viewport)


func points_draw() -> void:
	RenderingServer.canvas_item_clear(ci)
	for i: int in element.get_attribute(attribute_name).get_list_size() / 2:
		var v_offset := STRIP_HEIGHT * i
		# Draw the background hover or selection stylebox.
		var hovered := Indications.is_hovered(element.xid, i)
		var selected := Indications.is_selected(element.xid, i)
		if selected or hovered:
			var stylebox := StyleBoxFlat.new()
			stylebox.set_corner_radius_all(3)
			if selected:
				stylebox.bg_color = Color(0.7, 0.7, 1.0, 0.18) if hovered else\
						Color(0.6, 0.6, 1.0, 0.16)
			else:
				stylebox.bg_color = Color(0.8, 0.8, 1.0, 0.05)
			stylebox.draw(ci, Rect2(Vector2(0, v_offset), Vector2(points_container.size.x,
					STRIP_HEIGHT)))
		# Draw the child controls. They are going to be drawn, not added as a node unless
		# the mouse hovers them. This is a hack to significantly improve performance.
		if i == hovered_idx or i == focused_idx:
			continue
		
		var point_x := element.get_attribute_list(attribute_name)[i * 2]
		var point_y := element.get_attribute_list(attribute_name)[i * 2 + 1]
		# Draw the action button.
		more_icon.draw_rect(ci, Rect2(Vector2(points_container.size.x - 19, 4 + v_offset),
				Vector2(14, 14)), false, ThemeUtils.icon_normal_color)
		# Draw the fields.
		draw_numfield(Rect2(Vector2(4, 2 + v_offset), Vector2(44, 18)), point_x)
		draw_numfield(Rect2(Vector2(52, 2 + v_offset), Vector2(44, 18)), point_y)

func draw_numfield(rect: Rect2, num: float) -> void:
	mini_line_edit_stylebox.draw(ci, rect)
	ThemeUtils.mono_font.draw_string(ci, rect.position + Vector2(3, 13),
			NumstringParser.basic_num_to_text(num), HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 6, mini_line_edit_font_size, mini_line_edit_font_color)


func activate_hovered(idx: int) -> void:
	if idx != hovered_idx and\
	idx < element.get_attribute(attribute_name).get_list_size() / 2:
		activate_hovered_shared_logic(idx)

func reactivate_hovered() -> void:
	activate_hovered_shared_logic(hovered_idx)

func activate_hovered_shared_logic(idx: int) -> void:
	if is_instance_valid(hovered_strip):
		hovered_strip.queue_free()
	if focused_idx != idx:
		hovered_strip = setup_point_controls(idx)
	hovered_idx = idx
	points_container.queue_redraw()

func activate_focused(idx: int) -> void:
	if idx == focused_idx:
		return
	
	if idx == -1:
		if focused_idx == hovered_idx:
			hovered_strip = focused_strip
			focused_strip = null
		else:
			focused_strip.queue_free()
	elif idx == hovered_idx:
		if focused_idx >= 0:
			focused_strip.queue_free()
		focused_strip = hovered_strip
		hovered_strip = null
	else:
		focused_strip = setup_point_controls(idx)
	
	focused_idx = idx
	points_container.queue_redraw()

func check_focused() -> void:
	for child in focused_strip.get_children():
		if child.has_focus():
			return
	activate_focused(-1)

func setup_point_controls(idx: int) -> Control:
	if idx < 0:
		return null
	
	var point_x := element.get_attribute_list(attribute_name)[idx * 2]
	var point_y := element.get_attribute_list(attribute_name)[idx * 2 + 1]
	
	var container := Control.new()
	container.position.y = idx * STRIP_HEIGHT
	container.size = Vector2(points_container.size.x, STRIP_HEIGHT)
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	points_container.add_child(container)
	# Setup the action button.
	var action_button := Button.new()
	action_button.icon = more_icon
	action_button.theme_type_variation = "FlatButton"
	action_button.focus_mode = Control.FOCUS_NONE
	action_button.mouse_filter = Control.MOUSE_FILTER_PASS
	action_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	container.add_child(action_button)
	action_button.pressed.connect(_on_action_button_pressed.bind(action_button))
	action_button.gui_input.connect(_eat_double_clicks.bind(action_button))
	action_button.position = Vector2(points_container.size.x - 21, 2)
	action_button.size = Vector2(STRIP_HEIGHT - 4, STRIP_HEIGHT - 4)
	# Setup the fields.
	var x_field := numfield(idx)
	x_field.set_value(point_x)
	x_field.tooltip_text = "x"
	x_field.value_changed.connect(update_point_x_coordinate.bind(idx))
	x_field.focus_entered.connect(activate_focused.bind(idx))
	x_field.focus_exited.connect(check_focused, CONNECT_DEFERRED)
	var y_field := numfield(idx)
	y_field.set_value(point_y)
	y_field.tooltip_text = "y"
	y_field.value_changed.connect(update_point_y_coordinate.bind(idx))
	y_field.focus_entered.connect(activate_focused.bind(idx))
	y_field.focus_exited.connect(check_focused, CONNECT_DEFERRED)
	
	container.add_child(x_field)
	x_field.position = Vector2(4, 2)
	x_field.size = Vector2(44, 18)
	container.add_child(y_field)
	y_field.position = Vector2(52, 2)
	y_field.size = Vector2(44, 18)
	return container


func numfield(cmd_idx: int) -> BetterLineEdit:
	var new_field := MiniNumberField.instantiate()
	new_field.focus_entered.connect(Indications.normal_select.bind(element.xid, cmd_idx))
	return new_field


func _on_action_button_pressed(action_button_ref: Button) -> void:
	# Update the selection immediately, since if this point is
	# in a multi-selection, only the mouse button release would change the selection.
	Indications.normal_select(element.xid, hovered_idx)
	var viewport := get_viewport()
	var action_button_rect := action_button_ref.get_global_rect()
	HandlerGUI.popup_under_rect_center(Indications.get_selection_context(
			HandlerGUI.popup_under_rect_center.bind(action_button_rect, viewport),
			Indications.Context.LIST), action_button_rect, viewport)
