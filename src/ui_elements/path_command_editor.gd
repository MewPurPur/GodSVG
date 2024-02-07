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

@onready var relative_button: Button
@onready var more_button: Button
@onready var fields_container: CustomSpacedHBoxContainer = $Fields

var fields: Array[Control] = []


func update_type() -> void:
	cmd_char = path_command.command_char
	fields.clear()
	# Instantiate the input fields.
	match cmd_char.to_upper():
		"A":
			var field_rx: BetterLineEdit = add_number_field()
			var field_ry: BetterLineEdit = add_number_field()
			var field_rot: BetterLineEdit = add_number_field()
			var field_large_arc_flag: Button = add_flag_field()
			var field_sweep_flag: Button = add_flag_field()
			var field_x: BetterLineEdit = add_number_field()
			var field_y: BetterLineEdit = add_number_field()
			field_rx.mode = field_rx.Mode.ONLY_POSITIVE
			field_ry.mode = field_ry.Mode.ONLY_POSITIVE
			field_rot.mode = field_rot.Mode.HALF_ANGLE
			field_rot.custom_minimum_size.x -= 6
			field_rx.set_value(path_command.rx)
			field_ry.set_value(path_command.ry)
			field_rot.set_value(path_command.rot)
			field_large_arc_flag.set_value(path_command.large_arc_flag)
			field_sweep_flag.set_value(path_command.sweep_flag)
			field_x.set_value(path_command.x)
			field_y.set_value(path_command.y)
			field_rx.tooltip_text = "rx"
			field_ry.tooltip_text = "ry"
			field_rot.tooltip_text = "rot"
			field_large_arc_flag.tooltip_text = "large_arc_flag"
			field_sweep_flag.tooltip_text = "sweep_flag"
			field_x.tooltip_text = "x"
			field_y.tooltip_text = "y"
			field_rx.value_changed.connect(update_value.bind(&"rx"))
			field_ry.value_changed.connect(update_value.bind(&"ry"))
			field_rot.value_changed.connect(update_value.bind(&"rot"))
			field_large_arc_flag.value_changed.connect(update_value.bind(&"large_arc_flag"))
			field_sweep_flag.value_changed.connect(update_value.bind(&"sweep_flag"))
			field_x.value_changed.connect(update_value.bind(&"x"))
			field_y.value_changed.connect(update_value.bind(&"y"))
			fields = [field_rx, field_ry, field_rot, field_large_arc_flag,
					field_sweep_flag, field_x, field_y]
			fields_container.set_spacing_array([3, 4, 4, 4, 4, 3])
		"C":
			var field_x1: BetterLineEdit = add_number_field()
			var field_y1: BetterLineEdit = add_number_field()
			var field_x2: BetterLineEdit = add_number_field()
			var field_y2: BetterLineEdit = add_number_field()
			var field_x: BetterLineEdit = add_number_field()
			var field_y: BetterLineEdit = add_number_field()
			field_x1.set_value(path_command.x1)
			field_y1.set_value(path_command.y1)
			field_x2.set_value(path_command.x2)
			field_y2.set_value(path_command.y2)
			field_x.set_value(path_command.x)
			field_y.set_value(path_command.y)
			field_x1.tooltip_text = "x1"
			field_y1.tooltip_text = "y1"
			field_x2.tooltip_text = "x2"
			field_y2.tooltip_text = "y2"
			field_x.tooltip_text = "x"
			field_y.tooltip_text = "y"
			field_x1.value_changed.connect(update_value.bind(&"x1"))
			field_y1.value_changed.connect(update_value.bind(&"y1"))
			field_x2.value_changed.connect(update_value.bind(&"x2"))
			field_y2.value_changed.connect(update_value.bind(&"y2"))
			field_x.value_changed.connect(update_value.bind(&"x"))
			field_y.value_changed.connect(update_value.bind(&"y"))
			fields = [field_x1, field_y1, field_x2, field_y2, field_x, field_y]
			fields_container.set_spacing_array([3, 4, 3, 4, 3])
		"Q":
			var field_x1: BetterLineEdit = add_number_field()
			var field_y1: BetterLineEdit = add_number_field()
			var field_x: BetterLineEdit = add_number_field()
			var field_y: BetterLineEdit = add_number_field()
			field_x1.set_value(path_command.x1)
			field_y1.set_value(path_command.y1)
			field_x.set_value(path_command.x)
			field_y.set_value(path_command.y)
			field_x1.tooltip_text = "x1"
			field_y1.tooltip_text = "y1"
			field_x.tooltip_text = "x"
			field_y.tooltip_text = "y"
			field_x1.value_changed.connect(update_value.bind(&"x1"))
			field_y1.value_changed.connect(update_value.bind(&"y1"))
			field_x.value_changed.connect(update_value.bind(&"x"))
			field_y.value_changed.connect(update_value.bind(&"y"))
			fields = [field_x1, field_y1, field_x, field_y]
			fields_container.set_spacing_array([3, 4, 3])
		"S":
			var field_x2: BetterLineEdit = add_number_field()
			var field_y2: BetterLineEdit = add_number_field()
			var field_x: BetterLineEdit = add_number_field()
			var field_y: BetterLineEdit = add_number_field()
			field_x2.set_value(path_command.x2)
			field_y2.set_value(path_command.y2)
			field_x.set_value(path_command.x)
			field_y.set_value(path_command.y)
			field_x2.tooltip_text = "x2"
			field_y2.tooltip_text = "y2"
			field_x.tooltip_text = "x"
			field_y.tooltip_text = "y"
			field_x2.value_changed.connect(update_value.bind(&"x2"))
			field_y2.value_changed.connect(update_value.bind(&"y2"))
			field_x.value_changed.connect(update_value.bind(&"x"))
			field_y.value_changed.connect(update_value.bind(&"y"))
			fields = [field_x2, field_y2, field_x, field_y]
			fields_container.set_spacing_array([3, 4, 3])
		"M", "L", "T":
			var field_x: BetterLineEdit = add_number_field()
			var field_y: BetterLineEdit = add_number_field()
			field_x.set_value(path_command.x)
			field_y.set_value(path_command.y)
			field_x.tooltip_text = "x"
			field_y.tooltip_text = "y"
			field_x.value_changed.connect(update_value.bind(&"x"))
			field_y.value_changed.connect(update_value.bind(&"y"))
			fields = [field_x, field_y]
			fields_container.set_spacing_array([3])
		"H":
			var field_x: BetterLineEdit = add_number_field()
			field_x.set_value(path_command.x)
			field_x.tooltip_text = "x"
			field_x.value_changed.connect(update_value.bind(&"x"))
			fields = [field_x]
		"V":
			var field_y: BetterLineEdit = add_number_field()
			field_y.set_value(path_command.y)
			field_y.tooltip_text = "y"
			field_y.value_changed.connect(update_value.bind(&"y"))
			fields = [field_y]

# Alternative to fully rebuilding the path command editor, if the layout is unchanged.
func sync_values(cmd: PathCommand) -> void:
	# Instantiate the input fields.
	match cmd_char.to_upper():
		"A":
			fields[0].set_value(cmd.rx, true)
			fields[1].set_value(cmd.ry, true)
			fields[2].set_value(cmd.rot, true)
			fields[3].set_value(cmd.large_arc_flag, true)
			fields[4].set_value(cmd.sweep_flag, true)
			fields[5].set_value(cmd.x, true)
			fields[6].set_value(cmd.y, true)
		"C":
			fields[0].set_value(cmd.x1, true)
			fields[1].set_value(cmd.y1, true)
			fields[2].set_value(cmd.x2, true)
			fields[3].set_value(cmd.y2, true)
			fields[4].set_value(cmd.x, true)
			fields[5].set_value(cmd.y, true)
		"Q":
			fields[0].set_value(cmd.x1, true)
			fields[1].set_value(cmd.y1, true)
			fields[2].set_value(cmd.x, true)
			fields[3].set_value(cmd.y, true)
		"S":
			fields[0].set_value(cmd.x2, true)
			fields[1].set_value(cmd.y2, true)
			fields[2].set_value(cmd.x, true)
			fields[3].set_value(cmd.y, true)
		"L", "M", "T":
			fields[0].set_value(cmd.x, true)
			fields[1].set_value(cmd.y, true)
		"H":
			fields[0].set_value(cmd.x, true)
		"V":
			fields[0].set_value(cmd.y, true)
		_: return


func update_value(new_value: float, property: StringName) -> void:
	get_path_attribute().set_command_property(cmd_idx, property, new_value)

func _on_relative_button_pressed() -> void:
	get_path_attribute().toggle_relative_command(cmd_idx)


func _ready() -> void:
	Indications.selection_changed.connect(determine_selection_state)
	Indications.hover_changed.connect(determine_selection_state)
	determine_selection_state()


func add_number_field() -> BetterLineEdit:
	var new_field := MiniNumberField.instantiate()
	new_field.focus_entered.connect(Indications.normal_select.bind(tid, cmd_idx))
	fields_container.add_child(new_field)
	return new_field

func add_flag_field() -> Button:
	var new_field := FlagField.instantiate()
	fields_container.add_child(new_field)
	return new_field


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == 0:
		Indications.set_inner_hovered(tid, cmd_idx)
	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				# Unselect the tag, so then it's selected again.
				Indications.ctrl_select(tid, cmd_idx)
				var subpath_range: Vector2i =\
						SVG.root_tag.get_tag(tid).attributes.d.get_subpath(cmd_idx)
				for idx in range(subpath_range.x, subpath_range.y + 1):
					Indications.ctrl_select(tid, idx)
			elif event.ctrl_pressed:
				Indications.ctrl_select(tid, cmd_idx)
			elif event.shift_pressed:
				Indications.shift_select(tid, cmd_idx)
			else:
				Indications.normal_select(tid, cmd_idx)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if Indications.semi_selected_tid != tid or\
			not cmd_idx in Indications.inner_selections:
				Indications.normal_select(tid, cmd_idx)
			Utils.popup_under_mouse(Indications.get_selection_context(),
					get_global_mouse_position())


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
	# Draw the relative button. It's going to be only drawn, not added as a node, until
	# the mouse enters. This is a hack to significantly improve performance.
	if relative_button == null:
		var relative_button_rect := Rect2(Vector2(3, 2), Vector2(18, size.y - 4))
		if Utils.is_string_upper(cmd_char):
			draw_style_box(absolute_button_normal, relative_button_rect)
		else:
			draw_style_box(relative_button_normal, relative_button_rect)
		draw_string(code_font, Vector2(6, size.y - 6), cmd_char,
				HORIZONTAL_ALIGNMENT_CENTER, 12, 13)
		fields_container.position = Vector2(25, 2)
	# Draw the action button.
	if more_button == null:
		draw_texture_rect(more_icon, Rect2(Vector2(size.x - 19, 4),
				Vector2(14, 14)), false, Color("bfbfbf"))

# When the mouse enters the path command editor, wake it up by adding the real nodes.
# Otherwise, the nodes should only be drawn. This is important for performance.
func _on_mouse_entered() -> void:
	# Setup the relative button.
	relative_button = Button.new()
	relative_button.focus_mode = Control.FOCUS_NONE
	relative_button.mouse_filter = Control.MOUSE_FILTER_PASS
	relative_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	relative_button.add_theme_font_override(&"font", code_font)
	relative_button.add_theme_font_size_override(&"font_size", 13)
	relative_button.text = cmd_char
	relative_button.begin_bulk_theme_override()
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
	relative_button.position = Vector2(3, 2)
	relative_button.size = Vector2(18, size.y - 4)
	# Setup the action button.
	more_button = Button.new()
	more_button.icon = more_icon
	more_button.theme_type_variation = &"FlatButton"
	more_button.focus_mode = Control.FOCUS_NONE
	more_button.mouse_filter = Control.MOUSE_FILTER_PASS
	more_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(more_button)
	more_button.pressed.connect(_on_more_button_pressed)
	more_button.position = Vector2(size.x - 21, 2)
	more_button.size = Vector2(18, 18)
	# Update the graphics.
	queue_redraw()

func _on_mouse_exited() -> void:
	relative_button.queue_free()
	more_button.queue_free()
	Indications.remove_inner_hovered(tid, cmd_idx)
	queue_redraw()

func _on_more_button_pressed() -> void:
	Utils.popup_under_control_centered(Indications.get_selection_context(), more_button)

func get_path_attribute() -> AttributePath:
	return SVG.root_tag.get_tag(tid).attributes.d
