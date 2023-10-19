extends AttributeEditor

const CommandEditor = preload("path_command_editor.tscn")

@onready var command_picker: Popup = $PathPopup
@onready var line_edit: LineEdit = $MainLine/LineEdit
@onready var commands_container: VBoxContainer = $Commands
@onready var action_popup: Popup = $ActionsPopup

signal value_changed(new_value: String)
var _value: String  # Must not be updated directly.

func set_value(new_value: String, emit_value_changed := true):
	if _value != new_value:
		_value = new_value
		if emit_value_changed:
			value_changed.emit(new_value)

func get_value() -> String:
	return _value

func sync_value() -> void:
	set_value(PathDataParser.path_commands_to_value(attribute.commands))

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		attribute.command_changed.connect(sync_value)
		set_value(attribute.value)

func _on_value_changed(new_value: String) -> void:
	line_edit.text = new_value
	if attribute != null:
		attribute.set_value(new_value)
	rebuild_commands()

func _on_button_pressed() -> void:
	command_picker.popup(Utils.calculate_popup_rect(
			line_edit.global_position, line_edit.size, command_picker.size))

func _on_path_command_picked(new_command: String) -> void:
	attribute.add_command(new_command)


func rebuild_commands() -> void:
	for node in commands_container.get_children():
		node.queue_free()
	# Rebuild the container based on the commands array.
	for command_idx in attribute.get_command_count():
		var command: PathCommand = attribute.get_command(command_idx)
		var command_char := command.command_char
		var command_type := command_char.to_upper()
		
		var command_editor := CommandEditor.instantiate()
		command_editor.cmd_type = command_char
		# Instantiate the input fields.
		if command_type == "A":
			var field_rx: BetterLineEdit = command_editor.add_number_field()
			var field_ry: BetterLineEdit = command_editor.add_number_field()
			var field_rot: BetterLineEdit = command_editor.add_number_field()
			var field_large_arc_flag: Button = command_editor.add_flag_field()
			var field_sweep_flag: Button = command_editor.add_flag_field()
			field_large_arc_flag.set_value(command.large_arc_flag)
			field_sweep_flag.set_value(command.sweep_flag)
			field_rx.mode = field_rx.Mode.ONLY_POSITIVE
			field_ry.mode = field_ry.Mode.ONLY_POSITIVE
			field_rot.mode = field_rot.Mode.ANGLE
			field_rx.set_value(command.rx)
			field_ry.set_value(command.ry)
			field_rot.set_value(command.rot)
			field_rx.tooltip_text = "rx"
			field_ry.tooltip_text = "ry"
			field_rot.tooltip_text = "rot"
			field_large_arc_flag.tooltip_text = "large_arc_flag"
			field_sweep_flag.tooltip_text = "sweep_flag"
			field_rx.value_changed.connect(_update_command_value.bind(command_idx, &"rx"))
			field_ry.value_changed.connect(_update_command_value.bind(command_idx, &"ry"))
			field_rot.value_changed.connect(_update_command_value.bind(command_idx, &"rot"))
			field_large_arc_flag.value_changed.connect(
						_update_command_value.bind(command_idx, &"large_arc_flag"))
			field_sweep_flag.value_changed.connect(
						_update_command_value.bind(command_idx, &"sweep_flag"))
		if command_type == "Q" or command_type == "C":
			var field_x1: BetterLineEdit = command_editor.add_number_field()
			var field_y1: BetterLineEdit = command_editor.add_number_field()
			field_x1.set_value(command.x1)
			field_y1.set_value(command.y1)
			field_x1.tooltip_text = "x1"
			field_y1.tooltip_text = "y1"
			field_x1.value_changed.connect(_update_command_value.bind(command_idx, &"x1"))
			field_y1.value_changed.connect(_update_command_value.bind(command_idx, &"y1"))
		if command_type == "C" or command_type == "S":
			var field_x2: BetterLineEdit = command_editor.add_number_field()
			var field_y2: BetterLineEdit = command_editor.add_number_field()
			field_x2.set_value(command.x2)
			field_y2.set_value(command.y2)
			field_x2.tooltip_text = "x2"
			field_y2.tooltip_text = "y2"
			field_x2.value_changed.connect(_update_command_value.bind(command_idx, &"x2"))
			field_y2.value_changed.connect(_update_command_value.bind(command_idx, &"y2"))
		if command_type != "Z" and command_type != "V":
			var field_x: BetterLineEdit = command_editor.add_number_field()
			field_x.set_value(command.x)
			field_x.tooltip_text = "x"
			field_x.value_changed.connect(_update_command_value.bind(command_idx, &"x"))
		if command_type != "Z" and command_type != "H":
			var field_y: BetterLineEdit = command_editor.add_number_field()
			field_y.set_value(command.y)
			field_y.tooltip_text ="y"
			field_y.value_changed.connect(_update_command_value.bind(command_idx, &"y"))
		commands_container.add_child(command_editor)
		command_editor.relative_button.pressed.connect(toggle_relative.bind(command_idx))
		command_editor.more_button.pressed.connect(open_actions.bind(command_idx))


func _update_command_value(new_value: float, idx: int, property: StringName) -> void:
	attribute.set_command_property(idx, property, new_value)

func open_actions(idx: int) -> void:
	var buttons_arr: Array[Button] = []
	
	var delete_button := Button.new()
	delete_button.text = tr(&"#delete")
	delete_button.icon = load("res://visual/icons/Delete.svg")
	delete_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	delete_button.pressed.connect(delete.bind(idx))
	buttons_arr.append(delete_button)
	
	action_popup.set_btn_array(buttons_arr)
	action_popup.popup(Utils.calculate_popup_rect(get_global_mouse_position(),
			Vector2.ZERO, action_popup.size, true))

func delete(idx: int) -> void:
	action_popup.hide()
	attribute.delete_command(idx)

func toggle_relative(idx: int) -> void:
	attribute.toggle_relative_command(idx)


func _on_line_edit_text_submitted(new_text: String) -> void:
	set_value(new_text)
