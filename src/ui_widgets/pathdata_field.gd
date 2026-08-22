# An editor to be tied to a pathdata attribute.
extends VBoxContainer

var element: Element
const attribute_name = "d"  # Never propagates.

# So, about this editor. Most of this code is about implementing a big optimization.
# All the path commands are a single node that draws fake-outs in order to prevent
# adding too many nodes to the scene tree. Real controls are only created when necessary,
# i.e., a strip that's hovered, focused, directly above or below the focused strip, or
# the first strip if the line_edit is currently focused.

class Strip extends Control:
	var relativity_button: Button
	var fields: Array[Control]
	var action_button: Button

const STRIP_HEIGHT = 22.0

signal focused

const MiniNumberFieldScene = preload("res://src/ui_widgets/mini_number_field.tscn")
const FlagFieldScene = preload("res://src/ui_widgets/flag_field.tscn")

const more_icon = preload("res://assets/icons/SmallMore.svg")
const plus_icon = preload("res://assets/icons/Plus.svg")

var mini_line_edit_stylebox := get_theme_stylebox("normal", "MiniLineEdit")
var mini_line_edit_font_size := get_theme_font_size("font_size", "MiniLineEdit")
var mini_line_edit_font_color := get_theme_color("font_color", "MiniLineEdit")

@onready var line_edit: BetterLineEdit = $LineEdit
@onready var commands_container: Control = $Commands

# Variables around the big optimization.
# The dictionary of real strips is synced every time the mouse hovers a strip,
# a control is focused in or around a strip, or the line_edit is focused and needs
# the first strip to be accessible via focus. Strips that haven't been changed get reused.
var hovered_index := -1
var focused_index := -1
var real_strips: Dictionary[int, Strip] = {}

@onready var ci := commands_container.get_canvas_item()
var add_move_button: Control


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
	commands_container.draw.connect(_commands_draw)
	commands_container.gui_input.connect(_on_commands_gui_input)
	commands_container.mouse_exited.connect(_on_commands_mouse_exited)
	State.hover_changed.connect(commands_container.queue_redraw)
	State.selection_changed.connect(commands_container.queue_redraw)
	sync()
	commands_container.queue_redraw()


func get_inner_rect(index: int) -> Rect2:
	return Rect2(commands_container.position + Vector2(0, STRIP_HEIGHT * index), Vector2(commands_container.size.x, STRIP_HEIGHT))


func _on_element_attribute_changed(attribute_changed: String) -> void:
	if attribute_name == attribute_changed:
		sync()

func sync_localization() -> void:
	line_edit.placeholder_text = Translator.translate("No path data")

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
	
	# A plus button for adding a move command if empty.
	var cmd_count: int = element.get_attribute(attribute_name).get_command_count()
	if cmd_count == 0 and not is_instance_valid(add_move_button):
		add_move_button = Button.new()
		add_move_button.icon = plus_icon
		add_move_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		add_move_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		add_move_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_move_button.theme_type_variation = "FlatButton"
		add_child(add_move_button)
		add_move_button.pressed.connect(_on_add_move_button_pressed)
		HandlerGUI.register_focus_sequence(self, [line_edit, add_move_button])
	elif cmd_count != 0:
		if is_instance_valid(add_move_button):
			add_move_button.queue_free()
		HandlerGUI.register_focus_sequence(self, [line_edit, commands_container])
	sync_to_new_value_and_selection.call_deferred()

func sync_to_new_value_and_selection() -> void:
	var cmd_count: int = element.get_attribute(attribute_name).get_command_count()
	
	if focused_index != -1:
		if State.semi_selected_xid != element.xid or State.inner_selections.size() != 1:
			line_edit.grab_focus(true)
			set_focused(-1, true)
		else:
			# Gather the old focus.
			var focused_strip := real_strips[focused_index]
			var is_relativity_button_focused := focused_strip.relativity_button.has_focus()
			var is_action_button_focused := focused_strip.action_button.has_focus() or focused_strip.action_button in HandlerGUI.suppressed_focused_controls
			var field_focused_index := -1
			for i in focused_strip.fields.size():
				var field := focused_strip.fields[i]
				if field.has_focus():
					field_focused_index = i
					break
			
			set_focused(State.inner_selections[0], true)
			if State.inner_selections[0] != focused_index or is_action_button_focused:
				real_strips[focused_index].action_button.grab_focus(not get_viewport().gui_get_focus_owner().has_focus(true))
			elif is_relativity_button_focused:
				real_strips[focused_index].relativity_button.grab_focus(not get_viewport().gui_get_focus_owner().has_focus(true))
			elif field_focused_index != -1:
				real_strips[focused_index].fields[field_focused_index].grab_focus(not get_viewport().gui_get_focus_owner().has_focus(true))
	elif line_edit.has_focus():
		set_focused(-1, true)
	
	if get_rect().has_point(get_local_mouse_position()):
		HandlerGUI.throw_mouse_motion_event()
	commands_container.custom_minimum_size.y = STRIP_HEIGHT * cmd_count
	commands_container.queue_redraw()


func update_parameter(new_value: float, property: String, index: int) -> void:
	var attrib: AttributePathdata = element.get_attribute(attribute_name)
	var cmd := attrib.get_command(index)
	if cmd.relative:
		match property:
			"x", "x1", "x2": new_value += cmd.start_x
			"y", "y1", "y2": new_value += cmd.start_y
	attrib.set_command_property(index, property, new_value)
	State.save_svg()

func _on_relativity_button_pressed() -> void:
	element.get_attribute(attribute_name).toggle_relative_command(focused_index)
	set_focused(focused_index)
	State.save_svg()

func _on_add_move_button_pressed() -> void:
	element.get_attribute(attribute_name).insert_command(0, "M")
	line_edit.grab_focus(not add_move_button.has_focus(true))
	State.normal_select(element.xid, 0, true)
	State.save_svg()


# Path commands editor orchestration.

func _on_commands_mouse_exited() -> void:
	var cmd_idx := State.inner_hovered
	if State.semi_hovered_xid == element.xid:
		set_hovered(-1)
	State.remove_hovered(element.xid, cmd_idx)


# Prevents buttons from selecting a whole subpath when double-clicked.
func _eat_double_clicks(event: InputEvent, button: Button) -> void:
	if hovered_index >= 0 and event is InputEventMouseButton and event.double_click:
		button.accept_event()
		if event.is_pressed():
			if button.toggle_mode:
				button.toggled.emit(not button.button_pressed)
			else:
				button.pressed.emit()

func _on_commands_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return
	
	var cmd_idx := -1
	var event_pos: Vector2 = event.position
	if Rect2(Vector2.ZERO, commands_container.size).has_point(event_pos):
		cmd_idx = int(event_pos.y / STRIP_HEIGHT)
	
	set_hovered(cmd_idx)
	if event is InputEventMouseMotion and event.button_mask == 0:
		if cmd_idx >= 0:
			State.set_hovered(element.xid, cmd_idx)
		else:
			State.remove_hovered(element.xid, cmd_idx)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if event.double_click:
					var subpath_range: Vector2i = element.get_attribute(attribute_name).get_subpath(cmd_idx)
					if event.is_command_or_control_pressed():
						State.ctrl_select(element.xid, subpath_range.x)
						# ctrl_select() can deselect the first path command in the subpath, so make sure it's reselected if so.
						# This way we still get the conveniences in ctrl_select like changing the pivot.
						if not State.is_selected(element.xid, subpath_range.x):
							State.ctrl_select(element.xid, subpath_range.x)
					else:
						State.normal_select(element.xid, subpath_range.x)
					State.shift_select(element.xid, subpath_range.y)
				elif event.is_command_or_control_pressed():
					State.ctrl_select(element.xid, cmd_idx)
				elif event.shift_pressed:
					State.shift_select(element.xid, cmd_idx)
				else:
					State.normal_select(element.xid, cmd_idx)
			elif event.is_released() and not event.shift_pressed and not event.is_command_or_control_pressed() and\
			not event.double_click and State.inner_selections.size() > 1 and cmd_idx in State.inner_selections:
				State.normal_select(element.xid, cmd_idx)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if State.semi_selected_xid != element.xid or not cmd_idx in State.inner_selections:
				State.normal_select(element.xid, cmd_idx)
			# Popup the actions.
			var viewport := get_viewport()
			var popup_pos := viewport.get_mouse_position()
			HandlerGUI.popup_under_position(State.get_selection_context(HandlerGUI.popup_under_position.bind(popup_pos, viewport),
					Utils.LayoutPart.INSPECTOR), popup_pos, viewport)


func _commands_draw() -> void:
	RenderingServer.canvas_item_clear(ci)
	var path_attribute: AttributePathdata = element.get_attribute(attribute_name)
	var cmd_count := path_attribute.get_command_count()
	
	for i in cmd_count:
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
			stylebox.draw(ci, Rect2(Vector2(0, v_offset), Vector2(commands_container.size.x, STRIP_HEIGHT)))
		
		# Draw the child controls. They won't be added as nodes until necessary for UI purposes.
		# This is a hack to significantly improve performance.
		if i in real_strips.keys():
			continue
		
		var cmd := path_attribute.get_command(i)
		var cmd_char := cmd.command_char
		# Draw the action button.
		more_icon.draw(ci, Vector2(commands_container.size.x - 19, 4 + v_offset), ThemeUtils.context_icon_normal_color)
		# Draw the relative/absolute button.
		var relative_stylebox := get_theme_stylebox("normal", "PathCommandAbsoluteButton" if Utils.is_string_upper(cmd_char) else "PathCommandRelativeButton")
		relative_stylebox.draw(ci, Rect2(Vector2(3, 2 + v_offset), Vector2(18, STRIP_HEIGHT - 4)))
		ThemeUtils.mono_font.draw_string(ci, Vector2(6, v_offset + STRIP_HEIGHT - 6), cmd_char, HORIZONTAL_ALIGNMENT_CENTER, 12, 13, ThemeUtils.text_color)
		# Draw the fields.
		var rect := Rect2(Vector2(25, 2 + v_offset), Vector2(44, 18))
		match cmd_char.to_upper():
			"A":
				# Because of the flag editors, the procedure is more complex.
				draw_numfield(rect, "rx", cmd)
				rect.position.x = rect.end.x + 3
				draw_numfield(rect, "ry", cmd)
				rect.position.x = rect.end.x + 4
				draw_angle_numfield(rect, cmd)
				rect.position.x = rect.end.x + 4
				rect.size.x = 19
				var flag_field := FlagFieldScene.instantiate()
				var is_large_arc: bool = (cmd.large_arc_flag == 0)
				var is_sweep: bool = (cmd.sweep_flag == 0)
				flag_field.get_theme_stylebox("normal" if is_large_arc else "pressed").draw(ci, rect)
				ThemeUtils.mono_font.draw_string(ci, rect.position + Vector2(5, 14), String.num_uint64(cmd.large_arc_flag), HORIZONTAL_ALIGNMENT_LEFT,
						rect.size.x, 14, flag_field.get_theme_color("font_color" if is_large_arc else "font_pressed_color"))
				rect.position.x = rect.end.x + 4
				flag_field.get_theme_stylebox("normal" if is_sweep else "pressed").draw(ci, rect)
				ThemeUtils.mono_font.draw_string(ci, rect.position + Vector2(5, 14), String.num_uint64(cmd.sweep_flag), HORIZONTAL_ALIGNMENT_LEFT,
						rect.size.x, 14, flag_field.get_theme_color("font_color" if is_sweep else "font_pressed_color"))
				flag_field.free()
				rect.position.x = rect.end.x + 4
				rect.size.x = 44
				draw_numfield(rect, "x", cmd)
				rect.position.x = rect.end.x + 3
				draw_numfield(rect, "y", cmd)
			"C": draw_numfield_arr(rect, [3, 4, 3, 4, 3], ["x1", "y1", "x2", "y2", "x", "y"], cmd)
			"Q": draw_numfield_arr(rect, [3, 4, 3], ["x1", "y1", "x", "y"], cmd)
			"S": draw_numfield_arr(rect, [3, 4, 3], ["x2", "y2", "x", "y"], cmd)
			"M", "L", "T": draw_numfield_arr(rect, [3], ["x", "y"], cmd)
			"H": draw_numfield(rect, "x", cmd)
			"V": draw_numfield(rect, "y", cmd)
	
	# Draw subpath indicators.
	for start_idx in path_attribute.subpath_start_indices:
		var subpath_polyline_positions := PackedVector2Array()
		var current_subpath := path_attribute.get_subpath(start_idx)
		var subpath_start := current_subpath.x
		
		if subpath_start == current_subpath.y and path_attribute.get_command(subpath_start) is PathCommand.MoveCommand:
			continue
		
		var subpath_end_shifted := current_subpath.y + 1
		subpath_polyline_positions += PackedVector2Array([Vector2(0, subpath_start * STRIP_HEIGHT + 8), Vector2(-6, subpath_start * STRIP_HEIGHT + 8),
				Vector2(-6, subpath_end_shifted * STRIP_HEIGHT - 8), Vector2(0, subpath_end_shifted * STRIP_HEIGHT - 8)])
		
		var fully_selected := (subpath_end_shifted > subpath_start + 1)
		if fully_selected:
			for i in range(subpath_start, subpath_end_shifted):
				if not State.is_selected(element.xid, i):
					fully_selected = false
					break
		var color := Color(ThemeUtils.max_contrast_color, 0.24 if fully_selected else 0.1)
		RenderingServer.canvas_item_add_polyline(ci, subpath_polyline_positions, PackedColorArray([color, color, color, color]), 2.0 if fully_selected else 1.0)

func draw_angle_numfield(rect: Rect2, path_command: PathCommand) -> void:
	mini_line_edit_stylebox.draw(ci, rect)
	ThemeUtils.mono_font.draw_string(ci, rect.position + Vector2(3, 13), NumstringParser.basic_num_to_text(path_command.get("rot"), true),
			HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 6, mini_line_edit_font_size, mini_line_edit_font_color)

func draw_numfield(rect: Rect2, property: String, path_command: PathCommand) -> void:
	mini_line_edit_stylebox.draw(ci, rect)
	ThemeUtils.mono_font.draw_string(ci, rect.position + Vector2(3, 13), NumstringParser.basic_num_to_text(get_presented_num(path_command, property)),
			HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 6, mini_line_edit_font_size, mini_line_edit_font_color)

func draw_numfield_arr(first_rect: Rect2, spacings: Array, names: PackedStringArray, path_command: PathCommand) -> void:
	draw_numfield(first_rect, names[0], path_command)
	for i in spacings.size():
		first_rect.position.x = first_rect.end.x + spacings[i]
		draw_numfield(first_rect, names[i + 1], path_command)


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
	var cmd_count: int = element.get_attribute(attribute_name).get_command_count()
	
	if hovered_index >= 0 and hovered_index < cmd_count:
		wanted.append(hovered_index)
	
	if focused_index >= 0 and focused_index < cmd_count:
		for i in range(focused_index - 1, focused_index + 2):
			if i >= 0 and i < cmd_count and not i in wanted:
				wanted.append(i)
	elif line_edit.has_focus() and cmd_count > 0 and not 0 in wanted:
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
			real_strips[idx] = setup_path_command_controls(idx)
	
	HandlerGUI.forget_focus_sequence(commands_container)
	var focus_sequence: Array[Control] = []
	for idx in wanted:
		var strip := real_strips[idx]
		if is_instance_valid(strip):
			focus_sequence.append_array(strip.get_children())
	HandlerGUI.register_focus_sequence(commands_container, focus_sequence)
	commands_container.queue_redraw()

func check_if_strip_still_focused(index: int) -> void:
	if focused_index != index:
		return
	var strip := real_strips[index]
	if strip.relativity_button.has_focus() or strip.action_button.has_focus() or strip.action_button in HandlerGUI.suppressed_focused_controls:
		return
	for field in strip.fields:
		if field.has_focus():
			return
	set_focused(-1)


func setup_path_command_controls(index: int) -> Strip:
	var cmd: PathCommand = element.get_attribute(attribute_name).get_command(index)
	var cmd_char := cmd.command_char
	
	var strip := Strip.new()
	strip.position.y = index * STRIP_HEIGHT
	strip.size = Vector2(commands_container.size.x, STRIP_HEIGHT)
	strip.mouse_filter = Control.MOUSE_FILTER_PASS
	commands_container.add_child(strip)
	# Setup the relative button.
	var relativity_button := Button.new()
	relativity_button.mouse_filter = Control.MOUSE_FILTER_PASS
	relativity_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	relativity_button.add_theme_font_override("font", ThemeUtils.mono_font)
	relativity_button.theme_type_variation = "PathCommandAbsoluteButton" if Utils.is_string_upper(cmd_char) else "PathCommandRelativeButton"
	relativity_button.text = cmd_char
	relativity_button.tooltip_text = TranslationUtils.get_path_command_description(cmd_char, true)
	strip.relativity_button = relativity_button
	strip.add_child(relativity_button)
	relativity_button.pressed.connect(_on_relativity_button_pressed)
	relativity_button.gui_input.connect(_eat_double_clicks.bind(relativity_button))
	relativity_button.focus_entered.connect(set_focused.bind(index))
	relativity_button.focus_exited.connect(check_if_strip_still_focused.bind(index), CONNECT_DEFERRED)
	relativity_button.position = Vector2(3, 2)
	relativity_button.size = Vector2(STRIP_HEIGHT - 4, STRIP_HEIGHT - 4)
	# Setup the fields.
	var fields: Array[Control] = []
	var spacings := PackedInt32Array()
	var property_names: PackedStringArray = []
	match cmd_char.to_upper():
		"A":
			var field_rx := MiniNumberFieldScene.instantiate()
			var field_ry := MiniNumberFieldScene.instantiate()
			var field_rot := MiniNumberFieldScene.instantiate()
			field_rx.mode = field_rx.Mode.ONLY_POSITIVE
			field_ry.mode = field_ry.Mode.ONLY_POSITIVE
			field_rot.mode = field_rot.Mode.HALF_ANGLE
			var field_large_arc := FlagFieldScene.instantiate()
			var field_sweep := FlagFieldScene.instantiate()
			field_large_arc.gui_input.connect(_eat_double_clicks.bind(field_large_arc))
			field_sweep.gui_input.connect(_eat_double_clicks.bind(field_sweep))
			fields = [field_rx, field_ry, field_rot, field_large_arc, field_sweep,
					MiniNumberFieldScene.instantiate(), MiniNumberFieldScene.instantiate()]
			spacings = PackedInt32Array([3, 4, 4, 4, 4, 3])
			property_names = PackedStringArray(["rx", "ry", "rot", "large_arc_flag", "sweep_flag", "x", "y"])
		"C":
			fields = [MiniNumberFieldScene.instantiate(), MiniNumberFieldScene.instantiate(),
					MiniNumberFieldScene.instantiate(), MiniNumberFieldScene.instantiate(),
					MiniNumberFieldScene.instantiate(), MiniNumberFieldScene.instantiate()]
			spacings = PackedInt32Array([3, 4, 3, 4, 3])
			property_names = PackedStringArray(["x1", "y1", "x2", "y2", "x", "y"])
		"Q":
			fields = [MiniNumberFieldScene.instantiate(), MiniNumberFieldScene.instantiate(),
					MiniNumberFieldScene.instantiate(), MiniNumberFieldScene.instantiate()]
			spacings = PackedInt32Array([3, 4, 3])
			property_names = PackedStringArray(["x1", "y1", "x", "y"])
		"S":
			fields = [MiniNumberFieldScene.instantiate(), MiniNumberFieldScene.instantiate(),
					MiniNumberFieldScene.instantiate(), MiniNumberFieldScene.instantiate()]
			spacings = PackedInt32Array([3, 4, 3])
			property_names = PackedStringArray(["x2", "y2", "x", "y"])
		"M", "L", "T":
			fields = [MiniNumberFieldScene.instantiate(), MiniNumberFieldScene.instantiate()]
			spacings = PackedInt32Array([3])
			property_names = PackedStringArray(["x", "y"])
		"H":
			fields = [MiniNumberFieldScene.instantiate()]
			property_names = PackedStringArray(["x"])
		"V":
			fields = [MiniNumberFieldScene.instantiate()]
			property_names = PackedStringArray(["y"])
	strip.fields = fields
	# Setup the fields.
	if not fields.is_empty():
		for i in fields.size():
			var field := fields[i]
			var property_name := property_names[i]
			field.set_value(get_presented_num(cmd, property_name))
			field.tooltip_text = property_name
			field.value_changed.connect(update_parameter.bind(property_name, index))
			field.focus_entered.connect(set_focused.bind(index))
			field.focus_exited.connect(check_if_strip_still_focused.bind(index), CONNECT_DEFERRED)
			strip.add_child(field)
			field.position.y = 2
		fields[0].position.x = 25
		for i in fields.size() - 1:
			fields[i + 1].position.x = fields[i].get_end().x + spacings[i]
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
	action_button.focus_entered.connect(set_focused.bind(index))
	action_button.focus_exited.connect(check_if_strip_still_focused.bind(index), CONNECT_DEFERRED)
	action_button.position = Vector2(commands_container.size.x - 21, 2)
	action_button.size = Vector2(STRIP_HEIGHT - 4, STRIP_HEIGHT - 4)
	return strip


func get_presented_num(path_command: PathCommand, property: String) -> float:
	var num: float = path_command.get(property)
	if path_command.relative:
		match property:
			"x", "x1", "x2": num -= path_command.start_x
			"y", "y1", "y2": num -= path_command.start_y
	return num


func _on_action_button_pressed(action_button_ref: Button) -> void:
	# Update the selection immediately, since if this path command is in a multi-selection,
	# only the mouse button release would change the selection.
	var viewport := get_viewport()
	var action_button_rect := action_button_ref.get_global_rect()
	HandlerGUI.popup_under_rect_center(State.get_selection_context(HandlerGUI.popup_under_rect_center.bind(action_button_rect, viewport),
			Utils.LayoutPart.INSPECTOR), action_button_rect, viewport)
