## An editor for a single path command.
extends PanelContainer

signal cmd_update_value(idx: int, new_value: float, property: StringName)
signal cmd_delete(idx: int)
signal cmd_toggle_relative(idx: int)
signal cmd_insert_after(idx: int, cmd_char: String)
signal cmd_convert_to(idx: int, cmd_char: String)

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const MiniNumberField = preload("mini_number_field.tscn")
const FlagField = preload("flag_field.tscn")
const PathCommandPopup = preload("path_popup.tscn")

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
			field_rot.mode = field_rot.Mode.ANGLE
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
			fields[0].set_value(cmd.rx)
			fields[1].set_value(cmd.ry)
			fields[2].set_value(cmd.rot)
			fields[3].set_value(cmd.large_arc_flag)
			fields[4].set_value(cmd.sweep_flag)
			fields[5].set_value(cmd.x)
			fields[6].set_value(cmd.y)
		"C":
			fields[0].set_value(cmd.x1)
			fields[1].set_value(cmd.y1)
			fields[2].set_value(cmd.x2)
			fields[3].set_value(cmd.y2)
			fields[4].set_value(cmd.x)
			fields[5].set_value(cmd.y)
		"Q":
			fields[0].set_value(cmd.x1)
			fields[1].set_value(cmd.y1)
			fields[2].set_value(cmd.x)
			fields[3].set_value(cmd.y)
		"S":
			fields[0].set_value(cmd.x2)
			fields[1].set_value(cmd.y2)
			fields[2].set_value(cmd.x)
			fields[3].set_value(cmd.y)
		"L", "M", "T":
			fields[0].set_value(cmd.x)
			fields[1].set_value(cmd.y)
		"H":
			fields[0].set_value(cmd.x)
		"V":
			fields[0].set_value(cmd.y)
		_: return


func update_value(value: float, property: StringName) -> void:
	cmd_update_value.emit(cmd_idx, value, property)

func delete() -> void:
	cmd_delete.emit(cmd_idx)

func toggle_relative() -> void:
	cmd_toggle_relative.emit(cmd_idx)

func insert_after() -> void:
	var command_picker := PathCommandPopup.instantiate()
	add_child(command_picker)
	match cmd_char.to_upper():
		"M": command_picker.disable_invalid(["M", "Z", "T"])
		"Z": command_picker.disable_invalid(["Z"])
		"L", "H", "V", "A": command_picker.disable_invalid(["S", "T"])
		"C", "S": command_picker.disable_invalid(["T"])
		"Q", "T": command_picker.disable_invalid(["S"])
	command_picker.path_command_picked.connect(_on_insert_path_command_picked)
	Utils.popup_under_control_centered(command_picker, more_button)

func convert_to() -> void:
	var command_picker := PathCommandPopup.instantiate()
	add_child(command_picker)
	command_picker.force_relativity(Utils.is_string_lower(cmd_char))
	command_picker.disable_invalid([cmd_char.to_upper()])
	command_picker.path_command_picked.connect(_on_convert_path_command_picked)
	Utils.popup_under_control_centered(command_picker, more_button)

func open_actions(popup_from_mouse := false) -> void:
	var action_popup := ContextPopup.instantiate()
	var buttons_arr: Array[Button] = []
	
	var insert_after_btn := Button.new()
	insert_after_btn.text = tr(&"#insert_after")
	insert_after_btn.icon = load("res://visual/icons/Plus.svg")
	insert_after_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	insert_after_btn.pressed.connect(insert_after)
	buttons_arr.append(insert_after_btn)
	
	if cmd_idx != 0 and Indications.inner_selections.size() == 1:
		var convert_btn := Button.new()
		convert_btn.text = tr(&"#convert_to")
		convert_btn.icon = load("res://visual/icons/Reload.svg")
		convert_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		convert_btn.pressed.connect(convert_to)
		buttons_arr.append(convert_btn)
	
	var delete_btn := Button.new()
	delete_btn.text = tr(&"#delete")
	delete_btn.icon = load("res://visual/icons/Delete.svg")
	delete_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	delete_btn.pressed.connect(delete)
	buttons_arr.append(delete_btn)
	
	add_child(action_popup)
	action_popup.set_btn_array(buttons_arr)
	if popup_from_mouse:
		Utils.popup_under_mouse(action_popup, get_global_mouse_position())
	else:
		Utils.popup_under_control_centered(action_popup, more_button)


func _ready() -> void:
	Indications.selection_changed.connect(determine_selection_highlight)
	Indications.hover_changed.connect(determine_selection_highlight)
	determine_selection_highlight()


# Helpers

func create_stylebox(inside_color: Color, border_color: Color) -> StyleBoxFlat:
	var new_stylebox := StyleBoxFlat.new()
	new_stylebox.bg_color = inside_color
	new_stylebox.border_color = border_color
	new_stylebox.set_border_width_all(2)
	new_stylebox.set_corner_radius_all(4)
	new_stylebox.content_margin_bottom = 0.5
	new_stylebox.content_margin_top = 0.5
	new_stylebox.content_margin_left = 5
	new_stylebox.content_margin_right = 5
	return new_stylebox

func setup_relative_button() -> void:
	relative_button.text = cmd_char
	relative_button.pressed.connect(toggle_relative)
	if Utils.is_string_upper(cmd_char):
		relative_button.add_theme_stylebox_override(&"normal", create_stylebox(
				Color.from_hsv(0.08, 0.8, 0.8), Color.from_hsv(0.1, 0.6, 0.9)))
		relative_button.add_theme_stylebox_override(&"hover", create_stylebox(
				Color.from_hsv(0.09, 0.75, 0.9), Color.from_hsv(0.11, 0.55, 0.95)))
		relative_button.add_theme_stylebox_override(&"pressed", create_stylebox(
				Color.from_hsv(0.11, 0.6, 1.0), Color.from_hsv(0.13, 0.4, 1.0)))
	else:
		relative_button.add_theme_stylebox_override(&"normal", create_stylebox(
				Color.from_hsv(0.8, 0.8, 0.8), Color.from_hsv(0.76, 0.6, 0.9)))
		relative_button.add_theme_stylebox_override(&"hover", create_stylebox(
				Color.from_hsv(0.78, 0.75, 0.9), Color.from_hsv(0.74, 0.55, 0.95)))
		relative_button.add_theme_stylebox_override(&"pressed", create_stylebox(
				Color.from_hsv(0.74, 0.6, 1.0), Color.from_hsv(0.7, 0.4, 1.0)))


func add_number_field() -> BetterLineEdit:
	var new_field := MiniNumberField.instantiate()
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

func _on_insert_path_command_picked(new_command: String) -> void:
	cmd_insert_after.emit(cmd_idx + 1, new_command)

func _on_convert_path_command_picked(new_command: String) -> void:
	cmd_convert_to.emit(cmd_idx, new_command)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.ctrl_pressed:
				Indications.ctrl_select(tid, cmd_idx)
			elif event.shift_pressed:
				Indications.shift_select(tid, cmd_idx)
			else:
				Indications.normal_select(tid, cmd_idx)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			prints(Indications.semi_selected_tid, Indications.inner_selections)
			prints(tid, cmd_idx)
			if Indications.semi_selected_tid != tid or\
			not cmd_idx in Indications.inner_selections:
				Indications.normal_select(tid, cmd_idx)
			open_actions(true)

func determine_selection_highlight() -> void:
	var stylebox: StyleBox
	if Indications.semi_selected_tid == tid and cmd_idx in Indications.inner_selections:
		stylebox = StyleBoxFlat.new()
		stylebox.set_corner_radius_all(3)
		if Indications.semi_hovered_tid == tid and Indications.inner_hovered == cmd_idx:
			stylebox.bg_color = Color(0.7, 0.7, 1.0, 0.18)
		else:
			stylebox.bg_color = Color(0.6, 0.6, 1.0, 0.16)
	elif Indications.semi_hovered_tid == tid and Indications.inner_hovered == cmd_idx:
		stylebox = StyleBoxFlat.new()
		stylebox.set_corner_radius_all(3)
		stylebox.bg_color = Color(0.8, 0.8, 1.0, 0.05)
	else:
		stylebox = StyleBoxEmpty.new()
	stylebox.content_margin_left = 3
	stylebox.content_margin_right = 2
	stylebox.content_margin_top = 2
	stylebox.content_margin_bottom = 2
	add_theme_stylebox_override(&"panel", stylebox)


func _on_mouse_entered():
	Indications.set_inner_hovered(tid, cmd_idx)

func _on_mouse_exited():
	Indications.remove_inner_hovered(tid, cmd_idx)

func _on_more_button_pressed() -> void:
	Indications.normal_select(tid, cmd_idx)
	open_actions()
