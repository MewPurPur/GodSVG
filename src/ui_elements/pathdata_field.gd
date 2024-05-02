# An editor to be tied to a pathdata attribute.
extends VBoxContainer

# So, about this editor. Most of the code code is around implementing a huge optimization.
# All the path commands are a single node that draws fake-outs in order to prevent
# adding too many nodes to the scene tree. The real controls are only created when
# necessary, such as when hovered or focused.

const COMMAND_HEIGHT = 22.0

@export var absolute_button_normal: StyleBoxFlat
@export var absolute_button_hovered: StyleBoxFlat
@export var absolute_button_pressed: StyleBoxFlat
@export var relative_button_normal: StyleBoxFlat
@export var relative_button_hovered: StyleBoxFlat
@export var relative_button_pressed: StyleBoxFlat

signal focused
var attribute: AttributePath
var tid: PackedInt32Array  # The path field has inner selectables, so it needs this.

const MiniNumberField = preload("mini_number_field.tscn")
const FlagField = preload("flag_field.tscn")

const code_font = preload("res://visual/fonts/FontMono.ttf")
const more_icon = preload("res://visual/icons/SmallMore.svg")

var mini_line_edit_stylebox := get_theme_stylebox("normal", "MiniLineEdit")
var mini_line_edit_font_size := get_theme_font_size("font_size", "MiniLineEdit")
var mini_line_edit_font_color := get_theme_color("font_color", "MiniLineEdit")

@onready var line_edit: LineEdit = $LineEdit
@onready var commands_container: Control = $Commands
@onready var add_move: Button = $AddMove

# Variables around the big optimization.
var active_idx := -1  
@onready var ci := commands_container.get_canvas_item()
var fields: Array[Control] = []
var current_selections: Array[int] = []
var current_hovered: int = -1


func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR) -> void:
	sync(attribute.autoformat(new_value))
	if attribute.get_value() != new_value or update_type == Utils.UpdateType.FINAL:
		match update_type:
			Utils.UpdateType.INTERMEDIATE:
				attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
			Utils.UpdateType.FINAL:
				attribute.set_value(new_value, Attribute.SyncMode.FINAL)
			_:
				attribute.set_value(new_value)


func set_attribute(new_attribute: AttributePath) -> void:
	attribute = new_attribute
	set_value(attribute.get_value())
	attribute.value_changed.connect(set_value)
	line_edit.tooltip_text = attribute.name
	add_move.pressed.connect(attribute.insert_command.bind(0, "M"))
	line_edit.text_submitted.connect(set_value)
	line_edit.focus_entered.connect(_on_line_edit_focus_entered)
	commands_container.draw.connect(commands_draw)
	Indications.hover_changed.connect(_on_selections_or_hover_changed)
	Indications.selection_changed.connect(_on_selections_or_hover_changed)


func _on_line_edit_focus_entered() -> void:
	focused.emit()

func sync(new_value: String) -> void:
	line_edit.text = new_value
	# A plus button for adding a move command if empty.
	var cmd_count := attribute.get_command_count()
	add_move.visible = (cmd_count == 0)
	# Rebuild the path commands.
	commands_container.custom_minimum_size.y = cmd_count * COMMAND_HEIGHT
	commands_container.queue_redraw()


func update_value(new_value: float, property: String) -> void:
	attribute.set_command_property(active_idx, property, new_value)

func _on_relative_button_pressed() -> void:
	attribute.toggle_relative_command(active_idx)
	activate(active_idx, true)


# Path commands editor orchestration.

func _on_selections_or_hover_changed() -> void:
	var new_selections: Array[int] = []
	if Indications.semi_selected_tid == tid:
		new_selections = Indications.inner_selections
	var new_hovered: int = -1
	if Indications.semi_hovered_tid == tid:
		new_hovered = Indications.inner_hovered
	# Only redraw if selections or hovered changed.
	if new_selections != current_selections:
		# TODO Figure out why the fuck must I duplicate it.
		current_selections = new_selections.duplicate()
		commands_container.queue_redraw()
	if new_hovered != current_hovered:
		current_hovered = new_hovered
		commands_container.queue_redraw()

func _on_commands_mouse_exited() -> void:
	var cmd_idx := Indications.inner_hovered
	Indications.remove_hovered(tid, cmd_idx)
	if Indications.semi_hovered_tid == tid:
		for field in fields:
			if field.has_focus():
				active_idx = cmd_idx
		# Should switch out the controls for fake outs. This is safe even when
		# you've focused a BetterLineEdit, because it pauses the tree.
		if active_idx != cmd_idx:
			fields = []
			deactivate()


func _on_commands_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return
	
	var cmd_idx: int = (event.global_position.y - commands_container.global_position.y) /\
			COMMAND_HEIGHT
	
	if event is InputEventMouseMotion and event.button_mask == 0:
		Indications.set_hovered(tid, cmd_idx)
		activate(cmd_idx)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if event.double_click:
					# Unselect the tag, so then it's selected again.
					Indications.ctrl_select(tid, cmd_idx)
					var subpath_range: Vector2i =\
							SVG.root_tag.get_tag(tid).attributes.d.get_subpath(cmd_idx)
					for idx in range(subpath_range.x, subpath_range.y + 1):
						Indications.ctrl_select(tid, idx)
				elif event.is_command_or_control_pressed():
					Indications.ctrl_select(tid, cmd_idx)
				elif event.shift_pressed:
					Indications.shift_select(tid, cmd_idx)
				elif not cmd_idx in Indications.inner_selections:
					Indications.normal_select(tid, cmd_idx)
			elif event.is_released() and not event.shift_pressed and\
			not event.is_command_or_control_pressed() and not event.double_click and\
			Indications.inner_selections.size() > 1 and\
			cmd_idx in Indications.inner_selections:
				Indications.normal_select(tid, cmd_idx)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if Indications.semi_selected_tid != tid or\
			not cmd_idx in Indications.inner_selections:
				Indications.normal_select(tid, cmd_idx)
			# Popup the actions.
			var viewport := get_viewport()
			var popup_pos := viewport.get_mouse_position()
			HandlerGUI.popup_under_pos(Indications.get_selection_context(
					HandlerGUI.popup_under_pos.bind(popup_pos, viewport)), popup_pos, viewport)


func commands_draw() -> void:
	RenderingServer.canvas_item_clear(ci)
	for i in attribute.get_command_count():
		var v_offset := COMMAND_HEIGHT * i
		# Draw the background hover or selection stylebox.
		var hovered := Indications.is_hovered(tid, i)
		var selected := Indications.is_selected(tid, i)
		if selected or hovered:
			var stylebox := StyleBoxFlat.new()
			stylebox.set_corner_radius_all(3)
			if selected:
				if hovered:
					stylebox.bg_color = Color(0.7, 0.7, 1.0, 0.18)
				else:
					stylebox.bg_color = Color(0.6, 0.6, 1.0, 0.16)
			else:
				stylebox.bg_color = Color(0.8, 0.8, 1.0, 0.05)
			stylebox.draw(ci, Rect2(Vector2(0, v_offset), Vector2(commands_container.size.x,
					COMMAND_HEIGHT)))
		# Draw the child controls. They are going to be drawn, not added as a node unless
		# the mouse hovers them. This is a hack to significantly improve performance.
		if i == active_idx:
			continue
		
		var cmd := attribute.get_command(i)
		var cmd_char := cmd.command_char
		# Draw the action button.
		more_icon.draw_rect(ci, Rect2(Vector2(commands_container.size.x - 19, 4 + v_offset),
				Vector2(14, 14)), false, ThemeGenerator.icon_normal_color)
		# Draw the relative/absolute button.
		var relative_stylebox := absolute_button_normal if\
				Utils.is_string_upper(cmd_char) else relative_button_normal
		relative_stylebox.draw(ci, Rect2(Vector2(3, 2 + v_offset),
				Vector2(18, COMMAND_HEIGHT - 4)))
		code_font.draw_string(ci, Vector2(6, v_offset + COMMAND_HEIGHT - 6),
				cmd_char, HORIZONTAL_ALIGNMENT_CENTER, 12, 13)
		# Draw the fields.
		var rect := Rect2(Vector2(25, 2 + v_offset), Vector2(44, 18))
		match cmd_char.to_upper():
			"A":
				# Because of the flag editors, the procedure is more complex.
				draw_numfield(rect, "rx", cmd)
				rect.position.x = rect.end.x + 3
				draw_numfield(rect, "ry", cmd)
				rect.position.x = rect.end.x + 4
				draw_numfield(rect, "rot", cmd)
				rect.position.x = rect.end.x + 4
				rect.size.x = 19
				var flag_field := FlagField.instantiate()
				var is_large_arc: bool = (cmd.large_arc_flag == 0)
				var is_sweep: bool = (cmd.sweep_flag == 0)
				flag_field.get_theme_stylebox("normal" if is_large_arc\
						else "pressed").draw(ci, rect)
				code_font.draw_string(ci, rect.position + Vector2(5, 14),
						String.num_uint64(cmd.large_arc_flag),
						HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, 14,
						flag_field.get_theme_color("font_color" if is_large_arc\
								else "font_pressed_color"))
				rect.position.x = rect.end.x + 4
				flag_field.get_theme_stylebox("normal" if is_sweep
						else "pressed").draw(ci, rect)
				code_font.draw_string(ci, rect.position + Vector2(5, 14),
						String.num_uint64(cmd.sweep_flag), HORIZONTAL_ALIGNMENT_LEFT,
						rect.size.x, 14, flag_field.get_theme_color("font_color" if is_sweep\
						else "font_pressed_color"))
				flag_field.free()
				rect.position.x = rect.end.x + 4
				rect.size.x = 44
				draw_numfield(rect, "x", cmd)
				rect.position.x = rect.end.x + 3
				draw_numfield(rect, "y", cmd)
			"C": draw_numfield_arr(rect, [3, 4, 3, 4, 3], ["x1", "y1", "x2", "y2", "x", "y"],
					cmd)
			"Q": draw_numfield_arr(rect, [3, 4, 3], ["x1", "y1", "x", "y"], cmd)
			"S": draw_numfield_arr(rect, [3, 4, 3], ["x2", "y2", "x", "y"], cmd)
			"M", "L", "T": draw_numfield_arr(rect, [3], ["x", "y"], cmd)
			"H": draw_numfield(rect, "x", cmd)
			"V": draw_numfield(rect, "y", cmd)

func draw_numfield(rect: Rect2, property: String, path_command: PathCommand) -> void:
	mini_line_edit_stylebox.draw(ci, rect)
	code_font.draw_string(ci, rect.position + Vector2(3, 13),
			NumberArrayParser.basic_num_to_text(path_command.get(property)),
			HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 6,
			mini_line_edit_font_size, mini_line_edit_font_color)

func draw_numfield_arr(first_rect: Rect2, spacings: Array, names: Array[String],
path_command: PathCommand) -> void:
	draw_numfield(first_rect, names[0], path_command)
	for i in spacings.size():
		first_rect.position.x = first_rect.end.x + spacings[i]
		draw_numfield(first_rect, names[i + 1], path_command)

# Prevents buttons from selecting a whole subpath when double-clicked.
func _eat_double_clicks(event: InputEvent, button: Button) -> void:
	if active_idx and event is InputEventMouseButton and event.double_click:
		button.accept_event()
		if event.is_pressed():
			if button.toggle_mode:
				button.toggled.emit(not button.button_pressed)
			else:
				button.pressed.emit()


func activate(idx: int, force := false) -> void:
	if not force and active_idx == idx:
		return
	
	for child in commands_container.get_children():
		child.queue_free()
	var cmd := attribute.get_command(idx)
	var cmd_char := cmd.command_char
	active_idx = idx
	# Setup the relative button.
	var relative_button := Button.new()
	relative_button.focus_mode = Control.FOCUS_NONE
	relative_button.mouse_filter = Control.MOUSE_FILTER_PASS
	relative_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var is_absolute := Utils.is_string_upper(cmd_char)
	relative_button.begin_bulk_theme_override()
	relative_button.add_theme_font_override("font", code_font)
	relative_button.add_theme_font_size_override("font_size", 13)
	relative_button.add_theme_color_override("font_color", Color(1, 1, 1))
	if is_absolute:
		relative_button.add_theme_stylebox_override("normal", absolute_button_normal)
		relative_button.add_theme_stylebox_override("hover", absolute_button_hovered)
		relative_button.add_theme_stylebox_override("pressed", absolute_button_pressed)
	else:
		relative_button.add_theme_stylebox_override("normal", relative_button_normal)
		relative_button.add_theme_stylebox_override("hover", relative_button_hovered)
		relative_button.add_theme_stylebox_override("pressed", relative_button_pressed)
	relative_button.end_bulk_theme_override()
	relative_button.text = cmd_char
	relative_button.tooltip_text = "%s (%s)" %\
			[TranslationUtils.new().get_command_char_description(cmd_char),
			tr("Absolute") if is_absolute else tr("Relative")]
	commands_container.add_child(relative_button)
	relative_button.pressed.connect(_on_relative_button_pressed)
	relative_button.gui_input.connect(_eat_double_clicks.bind(relative_button))
	relative_button.position = Vector2(3, 2 + idx * COMMAND_HEIGHT)
	relative_button.size = Vector2(18, COMMAND_HEIGHT - 4)
	# Setup the action button.
	var action_button := Button.new()
	action_button.icon = more_icon
	action_button.theme_type_variation = "FlatButton"
	action_button.focus_mode = Control.FOCUS_NONE
	action_button.mouse_filter = Control.MOUSE_FILTER_PASS
	action_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	commands_container.add_child(action_button)
	action_button.pressed.connect(_on_action_button_pressed.bind(action_button))
	action_button.gui_input.connect(_eat_double_clicks.bind(action_button))
	action_button.position = Vector2(commands_container.size.x - 21,
			2 + idx * COMMAND_HEIGHT)
	action_button.size = Vector2(COMMAND_HEIGHT - 4, COMMAND_HEIGHT - 4)
	# Setup the fields.
	match cmd_char.to_upper():
		"A":
			var field_rx: BetterLineEdit = add_numfield(idx)
			var field_ry: BetterLineEdit = add_numfield(idx)
			var field_rot: BetterLineEdit = add_numfield(idx)
			field_rx.mode = field_rx.Mode.ONLY_POSITIVE
			field_ry.mode = field_ry.Mode.ONLY_POSITIVE
			field_rot.mode = field_rot.Mode.HALF_ANGLE
			var field_large_arc := FlagField.instantiate()
			var field_sweep := FlagField.instantiate()
			field_large_arc.gui_input.connect(_eat_double_clicks.bind(field_large_arc))
			field_sweep.gui_input.connect(_eat_double_clicks.bind(field_sweep))
			fields = [field_rx, field_ry, field_rot, field_large_arc, field_sweep,
					add_numfield(idx), add_numfield(idx)]
			setup_fields(cmd, [3, 4, 4, 4, 4, 3],
					["rx", "ry", "rot", "large_arc_flag", "sweep_flag", "x", "y"])
		"C":
			fields = [add_numfield(idx), add_numfield(idx), add_numfield(idx),
					add_numfield(idx), add_numfield(idx), add_numfield(idx)]
			setup_fields(cmd, [3, 4, 3, 4, 3], ["x1", "y1", "x2", "y2", "x", "y"])
		"Q":
			fields = [add_numfield(idx), add_numfield(idx), add_numfield(idx),
					add_numfield(idx)]
			setup_fields(cmd, [3, 4, 3], ["x1", "y1", "x", "y"])
		"S":
			fields = [add_numfield(idx), add_numfield(idx), add_numfield(idx),
					add_numfield(idx)]
			setup_fields(cmd, [3, 4, 3], ["x2", "y2", "x", "y"])
		"M", "L", "T":
			fields = [add_numfield(idx), add_numfield(idx)]
			setup_fields(cmd, [3], ["x", "y"])
		"H":
			fields = [add_numfield(idx)]
			setup_fields(cmd, [], ["x"])
		"V":
			fields = [add_numfield(idx)]
			setup_fields(cmd, [], ["y"])
		"Z": fields.clear()
	# Remove the graphics, as now there are real nodes.
	commands_container.queue_redraw()

func deactivate() -> void:
	active_idx = -1
	for child in commands_container.get_children():
		child.queue_free()
	commands_container.queue_redraw()

func add_numfield(cmd_idx: int) -> BetterLineEdit:
	var new_field := MiniNumberField.instantiate()
	new_field.focus_entered.connect(Indications.normal_select.bind(tid, cmd_idx))
	return new_field

func setup_fields(path_command: PathCommand, spacings: Array, names: Array) -> void:
	for i in fields.size():
		var property_str: String = names[i]
		fields[i].set_value(path_command.get(property_str))
		fields[i].tooltip_text = property_str
		fields[i].value_changed.connect(update_value.bind(property_str))
		commands_container.add_child(fields[i])
		fields[i].position.y = 2 + active_idx * COMMAND_HEIGHT
	
	fields[0].position.x = 25
	for i in fields.size() - 1:
		fields[i + 1].position.x = fields[i].get_end().x + spacings[i]


func _on_action_button_pressed(action_button_ref: Button) -> void:
	# Update the selection immediately, since if this path command is
	# in a multi-selection, only the mouse button release would change the selection.
	Indications.normal_select(tid, active_idx)
	var viewport := get_viewport()
	var action_button_rect := action_button_ref.get_global_rect()
	HandlerGUI.popup_under_rect_center(Indications.get_selection_context(
			HandlerGUI.popup_under_rect_center.bind(action_button_rect, viewport)),
			action_button_rect, viewport)
