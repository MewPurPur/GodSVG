## An editor for a single path command.
extends MarginContainer

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

var tid := PackedInt32Array()
var cmd_char := ""
var cmd_idx := -1
var path_command: PathCommand

@onready var relative_button: Button = $HBox/RelativeButton
@onready var more_button: Button = $HBox/MoreButton
@onready var fields_container: CustomSpacedHBoxContainer = $HBox/Fields

var fields: Array[Control] = []

func update_type() -> void:
	cmd_char = path_command.command_char
	fields.clear()
	setup_relative_button()
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

func toggle_relative() -> void:
	get_path_attribute().toggle_relative_command(cmd_idx)

func open_actions(popup_from_mouse := false) -> void:
	if popup_from_mouse:
		Utils.popup_under_mouse(Indications.get_selection_context(),
				get_global_mouse_position())
	else:
		Utils.popup_under_control_centered(Indications.get_selection_context(), more_button)


func _ready() -> void:
	Indications.selection_changed.connect(determine_selection_state)
	Indications.hover_changed.connect(determine_selection_state)
	determine_selection_state()


# Helpers

func setup_relative_button() -> void:
	relative_button.text = cmd_char
	relative_button.pressed.connect(toggle_relative)
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


func add_number_field() -> BetterLineEdit:
	var new_field := MiniNumberField.instantiate()
	new_field.focus_entered.connect(Indications.normal_select.bind(tid, cmd_idx))
	fields_container.add_child(new_field)
	return new_field

func add_flag_field() -> Button:
	var new_field := FlagField.instantiate()
	fields_container.add_child(new_field)
	return new_field


func _on_relative_button_pressed() -> void:
	cmd_char = cmd_char.to_upper() if Utils.is_string_lower(cmd_char)\
			else cmd_char.to_lower()
	setup_relative_button()

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
			open_actions(true)


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


func _on_mouse_exited():
	Indications.remove_inner_hovered(tid, cmd_idx)

func _on_more_button_pressed() -> void:
	open_actions()

func get_path_attribute() -> AttributePath:
	return SVG.root_tag.get_tag(tid).attributes.d
