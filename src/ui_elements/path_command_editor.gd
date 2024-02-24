## An editor for a single path command.
extends Control

@export var absolute_button_normal: StyleBoxFlat
@export var absolute_button_hovered: StyleBoxFlat
@export var absolute_button_pressed: StyleBoxFlat
@export var relative_button_normal: StyleBoxFlat
@export var relative_button_hovered: StyleBoxFlat
@export var relative_button_pressed: StyleBoxFlat

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const MiniNumberField = preload("mini_number_field.tscn")
const FlagField = preload("flag_field.tscn")
const PathCommandPopup = preload("res://src/ui_elements/path_popup.tscn")

const code_font = preload("res://visual/fonts/FontMono.ttf")
const more_icon = preload("res://visual/icons/SmallMore.svg")

var tid := PackedInt32Array()
var cmd_char := ""
var cmd_idx := -1
var path_command: PathCommand

var active := false
@onready var relative_button: Button
@onready var action_button: Button
var fields: Array[Control] = []


func update_value(new_value: float, property: StringName) -> void:
	get_path_attribute().set_command_property(cmd_idx, property, new_value)

func _on_relative_button_pressed() -> void:
	get_path_attribute().toggle_relative_command(cmd_idx)


func _ready() -> void:
	cmd_char = path_command.command_char
	Indications.selection_changed.connect(determine_selection_state)
	Indications.hover_changed.connect(determine_selection_state)
	determine_selection_state()


func add_numfield() -> BetterLineEdit:
	var new_field := MiniNumberField.instantiate()
	new_field.focus_entered.connect(Indications.normal_select.bind(tid, cmd_idx))
	return new_field


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == 0:
		Indications.set_hovered(tid, cmd_idx)
	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
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
			else:
				Indications.normal_select(tid, cmd_idx)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if Indications.semi_selected_tid != tid or\
			not cmd_idx in Indications.inner_selections:
				Indications.normal_select(tid, cmd_idx)
			# Popup the actions.
			var viewport := get_viewport()
			var popup_pos := viewport.get_mouse_position()
			Utils.popup_under_pos(Indications.get_selection_context(
					Utils.popup_under_pos.bind(popup_pos, viewport)), popup_pos, viewport)


var current_interaction_state := Utils.InteractionType.NONE

func determine_selection_state() -> void:
	var new_interaction_state := Utils.InteractionType.NONE
	if Indications.semi_selected_tid == tid and cmd_idx in Indications.inner_selections:
		if Indications.semi_hovered_tid == tid and Indications.inner_hovered == cmd_idx:
			new_interaction_state = Utils.InteractionType.HOVERED_SELECTED
		else:
			new_interaction_state = Utils.InteractionType.SELECTED
	elif Indications.semi_hovered_tid == tid and Indications.inner_hovered == cmd_idx:
		new_interaction_state = Utils.InteractionType.HOVERED
	
	if current_interaction_state != new_interaction_state:
		current_interaction_state = new_interaction_state
		queue_redraw()

func _draw() -> void:
	# First draw interaction-based stuff, as the highlight is behind everything.
	if current_interaction_state != Utils.InteractionType.NONE:
		var stylebox := StyleBoxFlat.new()
		stylebox.set_corner_radius_all(3)
		if current_interaction_state == Utils.InteractionType.HOVERED:
			stylebox.bg_color = Color(0.8, 0.8, 1.0, 0.05)
		elif current_interaction_state == Utils.InteractionType.SELECTED:
			stylebox.bg_color = Color(0.6, 0.6, 1.0, 0.16)
		elif current_interaction_state == Utils.InteractionType.HOVERED_SELECTED:
			stylebox.bg_color = Color(0.7, 0.7, 1.0, 0.18)
		stylebox.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	# Draw the child controls. They are going to be drawn, not added as a node unless
	# the mouse hovers them. This is a hack to significantly improve performance.
	if not active:
		# Draw the relative/absolute button.
		var relative_button_rect := Rect2(Vector2(3, 2), Vector2(18, size.y - 4))
		draw_style_box(absolute_button_normal if Utils.is_string_upper(cmd_char) else\
				relative_button_normal, relative_button_rect)
		draw_string(code_font, Vector2(6, size.y - 6), cmd_char,
				HORIZONTAL_ALIGNMENT_CENTER, 12, 13)
		# Draw the action button.
		draw_texture_rect(more_icon, Rect2(Vector2(size.x - 19, 4),
				Vector2(14, 14)), false, Color("bfbfbf"))
		# Draw the fields.
		match cmd_char.to_upper():
			"A":
				# Because of the flag editors, the procedure is as simple as for the rest.
				var stylebox := get_theme_stylebox(&"normal", &"MiniLineEdit")
				var font_size := get_theme_font_size(&"font_size", &"MiniLineEdit")
				var font_color := get_theme_color(&"font_outline_color", &"MiniLineEdit")
				var rect := Rect2(Vector2(25, 2), Vector2(44, 18))
				draw_numfield(rect, stylebox, &"rx", font_size, font_color)
				rect.position.x = rect.end.x + 3
				draw_numfield(rect, stylebox, &"ry", font_size, font_color)
				rect.position.x = rect.end.x + 4
				draw_numfield(rect, stylebox, &"rot", font_size, font_color)
				rect.position.x = rect.end.x + 4
				rect.size.x = 19
				var flag_field := FlagField.instantiate()
				draw_style_box(flag_field.get_theme_stylebox(&"normal" if\
						path_command.large_arc_flag == 0 else &"pressed"), rect)
				draw_string(code_font, rect.position + Vector2(5, 14),
						String.num_uint64(path_command.large_arc_flag),
						HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, 14,
						flag_field.get_theme_color(&"font_color" if\
						path_command.large_arc_flag == 0 else &"font_pressed_color"))
				rect.position.x = rect.end.x + 4
				draw_style_box(flag_field.get_theme_stylebox(&"normal" if\
						path_command.sweep_flag == 0 else &"pressed"), rect)
				draw_string(code_font, rect.position + Vector2(5, 14),
						String.num_uint64(path_command.sweep_flag),
						HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, 14,
						flag_field.get_theme_color(&"font_color" if\
						path_command.sweep_flag == 0 else &"font_pressed_color"))
				flag_field.free()
				rect.position.x = rect.end.x + 4
				rect.size.x = 44
				draw_numfield(rect, stylebox, &"x", font_size, font_color)
				rect.position.x = rect.end.x + 3
				draw_numfield(rect, stylebox, &"y", font_size, font_color)
			"C": draw_numfield_arr([3, 4, 3, 4, 3], [&"x1", &"y1", &"x2", &"y2", &"x", &"y"])
			"Q": draw_numfield_arr([3, 4, 3], [&"x1", &"y1", &"x", &"y"])
			"S": draw_numfield_arr([3, 4, 3], [&"x2", &"y2", &"x", &"y"])
			"M", "L", "T": draw_numfield_arr([3], [&"x", &"y"])
			"H":
				var stylebox := get_theme_stylebox(&"normal", &"MiniLineEdit")
				var font_size := get_theme_font_size(&"font_size", &"MiniLineEdit")
				var font_color := get_theme_color(&"font_outline_color", &"MiniLineEdit")
				var rect := Rect2(Vector2(25, 2), Vector2(44, 18))
				draw_numfield(rect, stylebox, &"x", font_size, font_color)
			"V":
				var stylebox := get_theme_stylebox(&"normal", &"MiniLineEdit")
				var font_size := get_theme_font_size(&"font_size", &"MiniLineEdit")
				var font_color := get_theme_color(&"font_outline_color", &"MiniLineEdit")
				var rect := Rect2(Vector2(25, 2), Vector2(44, 18))
				draw_numfield(rect, stylebox, &"y", font_size, font_color)

func draw_numfield(rect: Rect2, stylebox: StyleBoxFlat, property: StringName,\
font_size: int, font_color: Color) -> void:
	draw_style_box(stylebox, rect)
	draw_string(code_font, rect.position + Vector2(4, 13),
			NumberArrayParser.basic_num_to_text(path_command.get(property)),
			HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 4, font_size, font_color)

func draw_numfield_arr(spacings: Array, names: Array[StringName]) -> void:
	var stylebox := get_theme_stylebox(&"normal", &"MiniLineEdit")
	var font_size := get_theme_font_size(&"font_size", &"MiniLineEdit")
	var font_color := get_theme_color(&"font_outline_color", &"MiniLineEdit")
	var rect := Rect2(Vector2(25, 2), Vector2(44, 18))
	draw_numfield(rect, stylebox, names[0], font_size, font_color)
	for i in spacings.size():
		rect.position.x = rect.end.x + spacings[i]
		draw_numfield(rect, stylebox, names[i + 1], font_size, font_color)

# Prevents the relative button from selecting a whole subpath when double-clicked.
func _on_relative_button_gui_input(event: InputEvent) -> void:
	if active:
		if event is InputEventMouseButton and event.double_click:
			relative_button.accept_event()
			relative_button.pressed.emit()

# Prevents the action button from selecting a whole subpath when double-clicked.
func _on_action_button_gui_input(event: InputEvent) -> void:
	if active:
		if event is InputEventMouseButton and event.double_click:
			action_button.accept_event()
			action_button.pressed.emit()

# When the mouse enters the path command editor, activate it by adding the real nodes.
# Otherwise, the nodes should only be drawn. This is important for performance.
func _on_mouse_entered() -> void:
	if active:
		return
	
	active = true
	# Setup the relative button.
	relative_button = Button.new()
	relative_button.focus_mode = Control.FOCUS_NONE
	relative_button.mouse_filter = Control.MOUSE_FILTER_PASS
	relative_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	relative_button.text = cmd_char
	relative_button.begin_bulk_theme_override()
	relative_button.add_theme_font_override(&"font", code_font)
	relative_button.add_theme_font_size_override(&"font_size", 13)
	relative_button.add_theme_color_override(&"font_color", Color(1, 1, 1))
	if Utils.is_string_upper(cmd_char):
		relative_button.tooltip_text = "%s (%s)" %\
				[Utils.path_command_char_dict[cmd_char.to_upper()], tr(&"absolute")]
		relative_button.add_theme_stylebox_override(&"normal", absolute_button_normal)
		relative_button.add_theme_stylebox_override(&"hover", absolute_button_hovered)
		relative_button.add_theme_stylebox_override(&"pressed", absolute_button_pressed)
	else:
		relative_button.tooltip_text = "%s (%s)" %\
				[Utils.path_command_char_dict[cmd_char.to_upper()], tr(&"relative")]
		relative_button.add_theme_stylebox_override(&"normal", relative_button_normal)
		relative_button.add_theme_stylebox_override(&"hover", relative_button_hovered)
		relative_button.add_theme_stylebox_override(&"pressed", relative_button_pressed)
	relative_button.end_bulk_theme_override()
	add_child(relative_button)
	relative_button.pressed.connect(_on_relative_button_pressed)
	relative_button.gui_input.connect(_on_relative_button_gui_input)
	relative_button.position = Vector2(3, 2)
	relative_button.size = Vector2(18, size.y - 4)
	# Setup the action button.
	action_button = Button.new()
	action_button.icon = more_icon
	action_button.theme_type_variation = &"FlatButton"
	action_button.focus_mode = Control.FOCUS_NONE
	action_button.mouse_filter = Control.MOUSE_FILTER_PASS
	action_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(action_button)
	action_button.pressed.connect(_on_action_button_pressed)
	action_button.gui_input.connect(_on_action_button_gui_input)
	action_button.position = Vector2(size.x - 21, 2)
	action_button.size = Vector2(size.y - 4, size.y - 4)
	# Setup the fields.
	match cmd_char.to_upper():
		"A":
			var field_rx: BetterLineEdit = add_numfield()
			var field_ry: BetterLineEdit = add_numfield()
			var field_rot: BetterLineEdit = add_numfield()
			field_rx.mode = field_rx.Mode.ONLY_POSITIVE
			field_ry.mode = field_ry.Mode.ONLY_POSITIVE
			field_rot.mode = field_rot.Mode.HALF_ANGLE
			fields = [field_rx, field_ry, field_rot, FlagField.instantiate(),
					FlagField.instantiate(), add_numfield(), add_numfield()]
			setup_fields([3, 4, 4, 4, 4, 3],
					["rx", "ry", "rot", "large_arc_flag", "sweep_flag", "x", "y"])
		"C":
			fields = [add_numfield(), add_numfield(), add_numfield(), add_numfield(),
					add_numfield(), add_numfield()]
			setup_fields([3, 4, 3, 4, 3], ["x1", "y1", "x2", "y2", "x", "y"])
		"Q":
			fields = [add_numfield(), add_numfield(), add_numfield(), add_numfield()]
			setup_fields([3, 4, 3], ["x1", "y1", "x", "y"])
		"S":
			fields = [add_numfield(), add_numfield(), add_numfield(), add_numfield()]
			setup_fields([3, 4, 3], ["x2", "y2", "x", "y"])
		"M", "L", "T":
			fields = [add_numfield(), add_numfield()]
			setup_fields([3], ["x", "y"])
		"H":
			fields = [add_numfield()]
			setup_fields([], ["x"])
		"V":
			fields = [add_numfield()]
			setup_fields([], ["y"])
		"Z": fields.clear()
	# Remove the graphics, as now there are real nodes.
	queue_redraw()

func setup_fields(spacings: Array, names: Array) -> void:
	for i in fields.size():
		var property_string: String = names[i]
		var property_stringname := StringName(property_string)
		fields[i].set_value(path_command.get(property_stringname))
		fields[i].tooltip_text = property_string
		fields[i].value_changed.connect(update_value.bind(property_stringname))
		add_child(fields[i])
		fields[i].position.y = 2
	
	fields[0].position.x = 25
	for i in fields.size() - 1:
		fields[i + 1].position.x = fields[i].get_end().x + spacings[i]

func _on_mouse_exited() -> void:
	Indications.remove_hovered(tid, cmd_idx)
	
	if active:
		active = false
		for field in fields:
			if field.has_focus():
				active = true
		# Should switch out the controls for fake outs. This is safe even when
		# you've focused a BetterLineEdit, because it pauses the tree.
		if not active:
			for field in fields:
				field.queue_free()
			relative_button.queue_free()
			action_button.queue_free()
			queue_redraw()

func _on_action_button_pressed() -> void:
	var viewport := get_viewport()
	var action_button_rect := action_button.get_global_rect()
	Utils.popup_under_rect_center(Indications.get_selection_context(
			Utils.popup_under_rect_center.bind(action_button_rect, viewport)),
			action_button_rect, viewport)

func get_path_attribute() -> AttributePath:
	return SVG.root_tag.get_tag(tid).attributes.d
