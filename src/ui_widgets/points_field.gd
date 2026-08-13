# An editor to be tied to a points attribute.
extends VBoxContainer

var element: Element
const attribute_name = "points"  # Never propagates.

# So, about this editor. Most of this code is about implementing a big optimization.
# All the path commands are a single node that draws fake-outs in order to prevent
# adding too many nodes to the scene tree. Real controls are only created when necessary,
# i.e., a strip that's hovered, focused, directly above or below the focused strip, or
# the first strip if the line_edit is currently focused.

class Strip extends Control:
	var field_x: BetterLineEdit
	var field_y: BetterLineEdit
	var action_button: Button

const STRIP_HEIGHT = 22.0

signal focused

const MiniNumberFieldScene = preload("res://src/ui_widgets/mini_number_field.tscn")

const more_icon = preload("res://assets/icons/SmallMore.svg")
const plus_icon = preload("res://assets/icons/Plus.svg")

var mini_line_edit_stylebox := get_theme_stylebox("normal", "MiniLineEdit")
var mini_line_edit_font_size := get_theme_font_size("font_size", "MiniLineEdit")
var mini_line_edit_font_color := get_theme_color("font_color", "MiniLineEdit")

@onready var line_edit: BetterLineEdit = $LineEdit
@onready var points_container: Control = $Points

# Variables around the big optimization.
# The dictionary of real strips is synced every time the mouse hovers a strip,
# a control is focused in or around a strip, or the line_edit is focused and needs
# the first strip to be accessible via focus. Strips that haven't been changed get reused.
var hovered_index := -1
var focused_index := -1
var real_strips: Dictionary[int, Strip] = {}

@onready var ci := points_container.get_canvas_item()
var add_first_point_button: Control


func set_value(new_value: String, save := false) -> void:
	element.set_attribute(attribute_name, new_value)
	sync()
	if save:
		State.save_svg()


func setup() -> void:
	Configs.language_changed.connect(sync_localization)
	sync_localization()
	Configs.theme_changed.connect(sync_theming)
	sync_theming()
	element.attribute_changed.connect(_on_element_attribute_changed)
	line_edit.tooltip_text = attribute_name
	line_edit.text_submitted.connect(set_value.bind(true))
	line_edit.text_changed.connect(setup_font)
	line_edit.text_change_canceled.connect(setup_font_with_current_text)
	line_edit.focus_entered.connect(_on_line_edit_focus_entered)
	line_edit.visible_focus_changed.connect(_on_line_edit_visible_focus_changed)
	points_container.draw.connect(_points_draw)
	points_container.gui_input.connect(_on_points_gui_input)
	points_container.mouse_exited.connect(_on_points_mouse_exited)
	State.hover_changed.connect(points_container.queue_redraw)
	State.selection_changed.connect(points_container.queue_redraw)
	sync()
	points_container.queue_redraw()


func get_inner_rect(index: int) -> Rect2:
	return Rect2(points_container.position + Vector2(0, STRIP_HEIGHT * index), Vector2(points_container.size.x, STRIP_HEIGHT))


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync()

func sync_localization() -> void:
	line_edit.placeholder_text = Translator.translate("No points")

func sync_theming() -> void:
	mini_line_edit_stylebox = get_theme_stylebox("normal", "MiniLineEdit")
	mini_line_edit_font_size = get_theme_font_size("font_size", "MiniLineEdit")
	mini_line_edit_font_color = get_theme_color("font_color", "MiniLineEdit")
	queue_redraw()

func _on_line_edit_focus_entered() -> void:
	if line_edit.has_focus(true):
		_on_line_edit_visible_focus_changed()

func _on_line_edit_visible_focus_changed() -> void:
	set_focused(-1)
	focused.emit()

func setup_font_with_current_text() -> void:
	setup_font(line_edit.text)

func setup_font(new_text: String) -> void:
	if new_text.is_empty():
		line_edit.add_theme_font_override("font", ThemeUtils.main_font)
	else:
		line_edit.remove_theme_font_override("font")

var last_synced_value := " "  # Invalid initial string.

func sync() -> void:
	var new_value := element.get_attribute_value(attribute_name)
	line_edit.text = new_value
	setup_font_with_current_text()
	if last_synced_value == new_value:
		return
	last_synced_value = new_value
	
	# A plus button for adding a first point if empty.
	var points_count: int = element.get_attribute(attribute_name).get_list_size() / 2
	if points_count == 0 and not is_instance_valid(add_first_point_button):
		add_first_point_button = Button.new()
		add_first_point_button.icon = plus_icon
		add_first_point_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		add_first_point_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		add_first_point_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_first_point_button.theme_type_variation = "FlatButton"
		add_child(add_first_point_button)
		add_first_point_button.pressed.connect(_on_add_first_point_button_pressed)
		HandlerGUI.register_focus_sequence(self, [line_edit, add_first_point_button])
	elif points_count != 0:
		if is_instance_valid(add_first_point_button):
			add_first_point_button.queue_free()
		HandlerGUI.register_focus_sequence(self, [line_edit, points_container])
	sync_to_new_value_and_selection.call_deferred()

func sync_to_new_value_and_selection() -> void:
	var point_count: int = element.get_attribute(attribute_name).get_list_size() / 2
	
	if focused_index != -1:
		if State.semi_selected_xid != element.xid or State.inner_selections.size() != 1:
			line_edit.grab_focus(true)
			set_focused(-1, true)
		else:
			# Gather the old focus.
			var focused_strip := real_strips[focused_index]
			var is_field_x_focused := focused_strip.field_x.has_focus()
			var is_field_y_focused := focused_strip.field_y.has_focus()
			var is_action_button_focused := focused_strip.action_button.has_focus() or focused_strip.action_button in HandlerGUI.suppressed_focused_controls
			
			var is_focus_hidden := not (is_action_button_focused and focused_strip.action_button.has_focus(true))
			
			if State.inner_selections[0] != focused_index:
				set_focused(State.inner_selections[0], true)
				real_strips[focused_index].action_button.grab_focus(is_focus_hidden)
			else:
				set_focused(State.inner_selections[0], true)
				if is_field_x_focused:
					real_strips[focused_index].field_x.grab_focus(true)
				elif is_field_y_focused:
					real_strips[focused_index].field_y.grab_focus(true)
				elif is_action_button_focused:
					real_strips[focused_index].action_button.grab_focus(is_focus_hidden)
	elif line_edit.has_focus():
		set_focused(-1, true)
	
	if get_rect().has_point(get_local_mouse_position()):
		HandlerGUI.throw_mouse_motion_event()
	points_container.custom_minimum_size.y = STRIP_HEIGHT * point_count
	points_container.queue_redraw()


func update_list(new_value: float, index: int) -> void:
	var list := element.get_attribute_list(attribute_name)
	list[index] = new_value
	element.get_attribute(attribute_name).set_list(list)
	State.save_svg()

func _on_add_first_point_button_pressed() -> void:
	element.get_attribute(attribute_name).set_list(PackedFloat64Array([0.0, 0.0]))
	line_edit.grab_focus(not add_first_point_button.has_focus(true))
	State.normal_select(element.xid, 0, true)
	State.save_svg()


# Points editor orchestration.

func _on_points_mouse_exited() -> void:
	var point_idx := State.inner_hovered
	if State.semi_hovered_xid == element.xid:
		set_hovered(-1)
	State.remove_hovered(element.xid, point_idx)


# Prevents buttons from selecting a whole subpath when double-clicked.
func _eat_double_clicks(event: InputEvent, button: Button) -> void:
	if hovered_index >= 0 and event is InputEventMouseButton and event.double_click:
		button.accept_event()
		if event.is_pressed():
			if button.toggle_mode:
				button.toggled.emit(not button.button_pressed)
			else:
				button.pressed.emit()

func _on_points_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return
	
	var point_idx := -1
	var event_pos: Vector2 = event.position
	if Rect2(Vector2.ZERO, points_container.size).has_point(event_pos):
		point_idx = int(event_pos.y / STRIP_HEIGHT)
	
	set_hovered(point_idx)
	if event is InputEventMouseMotion and event.button_mask == 0:
		if point_idx >= 0:
			State.set_hovered(element.xid, point_idx)
		else:
			State.remove_hovered(element.xid, point_idx)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if event.double_click:
					State.normal_select(element.xid, 0)
					State.shift_select(element.xid, element.get_attribute(attribute_name).get_list_size() / 2 - 1)
				elif event.is_command_or_control_pressed():
					State.ctrl_select(element.xid, point_idx)
				elif event.shift_pressed:
					State.shift_select(element.xid, point_idx)
				else:
					State.normal_select(element.xid, point_idx)
			elif event.is_released() and not event.shift_pressed and not event.is_command_or_control_pressed() and\
			not event.double_click and State.inner_selections.size() > 1 and point_idx in State.inner_selections:
				State.normal_select(element.xid, point_idx)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if State.semi_selected_xid != element.xid or not point_idx in State.inner_selections:
				State.normal_select(element.xid, point_idx)
			# Popup the actions.
			var viewport := get_viewport()
			var popup_pos := viewport.get_mouse_position()
			HandlerGUI.popup_under_position(State.get_selection_context(HandlerGUI.popup_under_position.bind(popup_pos, viewport),
					Utils.LayoutPart.INSPECTOR), popup_pos, viewport)


func _points_draw() -> void:
	RenderingServer.canvas_item_clear(ci)
	var points_attribute: AttributeList = element.get_attribute(attribute_name)
	var point_count := points_attribute.get_list_size() / 2
	
	for i in point_count:
		var v_offset := STRIP_HEIGHT * i
		# Draw the background hover or selection stylebox.
		var hovered := State.is_hovered(element.xid, i)
		var selected := State.is_selected(element.xid, i)
		if selected or hovered:
			var stylebox := StyleBoxFlat.new()
			stylebox.set_corner_radius_all(3)
			if hovered and selected:
				stylebox.bg_color = ThemeUtils.soft_hover_pressed_overlay_color
			elif selected:
				stylebox.bg_color = ThemeUtils.soft_pressed_overlay_color
			elif hovered:
				stylebox.bg_color = ThemeUtils.soft_hover_overlay_color
			stylebox.draw(ci, Rect2(Vector2(0, v_offset), Vector2(points_container.size.x, STRIP_HEIGHT)))
		
		# Draw the child controls. They won't be added as nodes until necessary for UI purposes.
		# This is a hack to significantly improve performance.
		if i in real_strips.keys():
			continue
		
		# Draw the action button.
		more_icon.draw(ci, Vector2(points_container.size.x - 19, 4 + v_offset), ThemeUtils.context_icon_normal_color)
		# Draw the fields.
		draw_numfield(Rect2(Vector2(4, 2 + v_offset), Vector2(44, 18)), element.get_attribute_list(attribute_name)[i * 2])
		draw_numfield(Rect2(Vector2(52, 2 + v_offset), Vector2(44, 18)), element.get_attribute_list(attribute_name)[i * 2 + 1])

func draw_numfield(rect: Rect2, num: float) -> void:
	mini_line_edit_stylebox.draw(ci, rect)
	ThemeUtils.mono_font.draw_string(ci, rect.position + Vector2(3, 13), NumstringParser.basic_num_to_text(num),
			HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 6, mini_line_edit_font_size, mini_line_edit_font_color)


func set_hovered(index: int) -> void:
	if hovered_index != index:
		hovered_index = index
		sync_real_strips()

func set_focused(index: int, full_rebuild := false) -> void:
	if focused_index == index and not full_rebuild and not (index == -1 and line_edit.has_focus()):
		return
	focused_index = index
	if index != -1:
		State.normal_select(element.xid, index)
	sync_real_strips(full_rebuild)

func sync_real_strips(rebuild_all := false) -> void:
	var wanted: Array[int] = []
	var point_count: int = element.get_attribute(attribute_name).get_list_size() / 2
	
	if hovered_index >= 0 and hovered_index < point_count:
		wanted.append(hovered_index)
	
	if focused_index >= 0 and focused_index < point_count:
		for i in range(focused_index - 1, focused_index + 2):
			if i >= 0 and i < point_count and not i in wanted:
				wanted.append(i)
	elif line_edit.has_focus() and point_count > 0 and not 0 in wanted:
		wanted.append(0)
	
	wanted.sort()
	
	if rebuild_all:
		for idx in real_strips.keys():
			real_strips[idx].queue_free()
			real_strips.erase(idx)
	else:
		for idx in real_strips.keys():
			if not idx in wanted:
				real_strips[idx].queue_free()
				real_strips.erase(idx)
	
	for idx in wanted:
		if not idx in real_strips.keys():
			real_strips[idx] = setup_point_controls(idx)
	
	HandlerGUI.forget_focus_sequence(points_container)
	var focus_sequence: Array[Control] = []
	for idx in wanted:
		var strip := real_strips[idx]
		if is_instance_valid(strip):
			focus_sequence.append_array(strip.get_children())
	HandlerGUI.register_focus_sequence(points_container, focus_sequence)
	points_container.queue_redraw()

func check_if_strip_still_focused(index: int) -> void:
	if focused_index != index:
		return
	var strip := real_strips[index]
	if strip.field_x.has_focus() or strip.field_y.has_focus() or\
	strip.action_button.has_focus() or strip.action_button in HandlerGUI.suppressed_focused_controls:
		return
	set_focused(-1)


func setup_point_controls(idx: int) -> Strip:
	if idx < 0:
		return null
	
	var point_x := element.get_attribute_list(attribute_name)[idx * 2]
	var point_y := element.get_attribute_list(attribute_name)[idx * 2 + 1]
	
	var strip := Strip.new()
	strip.position.y = idx * STRIP_HEIGHT
	strip.size = Vector2(points_container.size.x, STRIP_HEIGHT)
	strip.mouse_filter = Control.MOUSE_FILTER_PASS
	points_container.add_child(strip)
	# Setup the fields.
	var field_x := MiniNumberFieldScene.instantiate()
	field_x.set_value(point_x)
	field_x.tooltip_text = "x"
	field_x.value_changed.connect(update_list.bind(idx * 2))
	field_x.focus_entered.connect(set_focused.bind(idx))
	field_x.focus_exited.connect(check_if_strip_still_focused.bind(idx), CONNECT_DEFERRED)
	strip.field_x = field_x
	strip.add_child(field_x)
	field_x.position = Vector2(4, 2)
	field_x.size = Vector2(44, 18)
	var field_y := MiniNumberFieldScene.instantiate()
	field_y.set_value(point_y)
	field_y.tooltip_text = "y"
	field_y.value_changed.connect(update_list.bind(idx * 2 + 1))
	field_y.focus_entered.connect(set_focused.bind(idx))
	field_y.focus_exited.connect(check_if_strip_still_focused.bind(idx), CONNECT_DEFERRED)
	strip.field_y = field_y
	strip.add_child(field_y)
	field_y.position = Vector2(52, 2)
	field_y.size = Vector2(44, 18)
	# Setup the action button.
	var action_button := Button.new()
	action_button.icon = more_icon
	action_button.theme_type_variation = "FlatButton"
	action_button.mouse_filter = Control.MOUSE_FILTER_PASS
	action_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	strip.action_button = action_button
	strip.add_child(action_button)
	action_button.pressed.connect(_on_action_button_pressed.bind(action_button))
	action_button.gui_input.connect(_eat_double_clicks.bind(action_button))
	action_button.focus_entered.connect(set_focused.bind(idx))
	action_button.focus_exited.connect(check_if_strip_still_focused.bind(idx), CONNECT_DEFERRED)
	action_button.position = Vector2(points_container.size.x - 21, 2)
	action_button.size = Vector2(STRIP_HEIGHT - 4, STRIP_HEIGHT - 4)
	return strip


func _on_action_button_pressed(action_button_ref: Button) -> void:
	# Update the selection immediately, since if this point is in a multi-selection,
	# only the mouse button release would change the selection.
	var viewport := get_viewport()
	var action_button_rect := action_button_ref.get_global_rect()
	HandlerGUI.popup_under_rect_center(State.get_selection_context(HandlerGUI.popup_under_rect_center.bind(action_button_rect, viewport),
			Utils.LayoutPart.INSPECTOR), action_button_rect, viewport)
