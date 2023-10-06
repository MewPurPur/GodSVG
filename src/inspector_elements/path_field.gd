extends AttributeEditor

const CommandEditor = preload("path_command_editor.tscn")

@onready var command_picker: Popup = $PathPopup
@onready var line_edit: LineEdit = $MainLine/LineEdit
@onready var commands_container: VBoxContainer = $Commands

var commands := PathCommandArray.new()

signal value_changed(new_value: String)
var value := "":
	set(new_value):
		if value != new_value:
			value = new_value
			value_changed.emit(new_value)

func sync_value() -> void:
	value = PathDataParser.path_commands_to_value(commands)

func _ready() -> void:
	commands.changed.connect(sync_value)
	value_changed.connect(_on_value_changed)
	if attribute != null:
		value = attribute.value

func _on_value_changed(new_value: String) -> void:
	line_edit.text = new_value
	commands.set_value(new_value)
	rebuild_commands()
	if attribute != null:
		attribute.value = new_value

func _on_button_pressed() -> void:
	command_picker.popup(Rect2(global_position + Vector2(0, line_edit.size.y),
			command_picker.size))

func _on_path_command_picked(new_command: String) -> void:
	commands.add_command(new_command)


func rebuild_commands() -> void:
	for node in commands_container.get_children():
		node.queue_free()
	# Rebuild the container based on the commands array.
	for command_idx in commands.get_count():
		var command := commands.get_command(command_idx)
		var command_char := command.command_char
		var command_type := command_char.to_upper()
		
		var command_editor := CommandEditor.instantiate()
		command_editor.cmd_type = command_char
		# Instantiate the input fields.
		if command_type == "A":
			var field_rx: Control = command_editor.add_number_field()
			var field_ry: Control = command_editor.add_number_field()
			var field_rot: Control = command_editor.add_number_field()
			var field_large_arc_flag: Control = command_editor.add_flag_field()
			var field_sweep_flag: Control = command_editor.add_flag_field()
			field_large_arc_flag.value = command.large_arc_flag
			field_sweep_flag.value = command.sweep_flag
			field_rx.is_float = true
			field_rx.min_value = 0.001
			field_rx.allow_higher = true
			field_ry.is_float = true
			field_ry.min_value = 0.001
			field_ry.allow_higher = true
			field_rot.is_float = true
			field_rot.min_value = -360
			field_rot.max_value = 360
			field_rx.value = command.rx
			field_ry.value = command.ry
			field_rot.value = command.rot
			field_rx.value_changed.connect(_update_command_value.bind(command_idx, &"rx"))
			field_ry.value_changed.connect(_update_command_value.bind(command_idx, &"ry"))
			field_rot.value_changed.connect(_update_command_value.bind(command_idx, &"rot"))
			field_large_arc_flag.value_changed.connect(
						_update_command_value.bind(command_idx, &"large_arc_flag"))
			field_sweep_flag.value_changed.connect(
						_update_command_value.bind(command_idx, &"sweep_flag"))
		if command_type == "Q" or command_type == "C":
			var field_x1: Control = command_editor.add_number_field()
			var field_y1: Control = command_editor.add_number_field()
			field_x1.is_float = true
			field_x1.min_value = -1024
			field_x1.remove_limits()
			field_y1.is_float = true
			field_y1.min_value = -1024
			field_y1.remove_limits()
			field_x1.value = command.x1
			field_y1.value = command.y1
			field_x1.value_changed.connect(_update_command_value.bind(command_idx, &"x1"))
			field_y1.value_changed.connect(_update_command_value.bind(command_idx, &"y1"))
		if command_type == "C" or command_type == "S":
			var field_x2: Control = command_editor.add_number_field()
			var field_y2: Control = command_editor.add_number_field()
			field_x2.is_float = true
			field_x2.min_value = -1024
			field_x2.remove_limits()
			field_y2.is_float = true
			field_y2.min_value = -1024
			field_y2.remove_limits()
			field_x2.value = command.x2
			field_y2.value = command.y2
			field_x2.value_changed.connect(_update_command_value.bind(command_idx, &"x2"))
			field_y2.value_changed.connect(_update_command_value.bind(command_idx, &"y2"))
		if command_type != "Z" and command_type != "V":
			var field_x: Control = command_editor.add_number_field()
			field_x.is_float = true
			field_x.min_value = -1024
			field_x.remove_limits()
			field_x.value = command.x
			field_x.value_changed.connect(_update_command_value.bind(command_idx, &"x"))
		if command_type != "Z" and command_type != "H":
			var field_y: Control = command_editor.add_number_field()
			field_y.is_float = true
			field_y.min_value = -1024
			field_y.remove_limits()
			field_y.value = command.y
			field_y.value_changed.connect(_update_command_value.bind(command_idx, &"y"))
		commands_container.add_child(command_editor)
		command_editor.relative_button.pressed.connect(toggle_relative.bind(command_idx))
		command_editor.delete_button.pressed.connect(delete.bind(command_idx))


func _update_command_value(new_value: float, idx: int, property: StringName) -> void:
	commands.set_command_property(idx, property, new_value)

func delete(idx: int) -> void:
	commands.delete_command(idx)

func toggle_relative(idx: int) -> void:
	commands.toggle_relative_command(idx)


func _input(event: InputEvent) -> void:
	Utils.defocus_control_on_outside_click(line_edit, event)

func _on_line_edit_text_submitted(new_text: String) -> void:
	value = new_text
	line_edit.release_focus()
