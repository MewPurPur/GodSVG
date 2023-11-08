## An editor to be tied to an AttributePath.
extends AttributeEditor

const CommandEditor = preload("path_command_editor.tscn")

@onready var line_edit: LineEdit = $MainLine/LineEdit
@onready var commands_container: VBoxContainer = $Commands
@onready var add_move: Button = $AddMove

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
		set_value(attribute.get_value())

func _on_value_changed(new_value: String) -> void:
	line_edit.text = new_value
	if attribute != null:
		attribute.set_value(new_value)
		if attribute.commands.is_empty():
			add_move.show()
		else:
			add_move.hide()
	rebuild_commands()


func rebuild_commands() -> void:
	var command_idx := 0
	for command_editor in commands_container.get_children():
		if command_idx >= attribute.get_command_count():
			break
		var command: PathCommand = attribute.get_command(command_idx)
		if command_editor.cmd_char == command.command_char:
			command_editor.sync_values(command)
			command_idx += 1
		else:
			break

	for command_editor in commands_container.get_children():
		if command_editor.cmd_idx >= command_idx:
			command_editor.queue_free()
	# Rebuild the container based on the commands array.
	while command_idx < attribute.get_command_count():
		var command_editor := CommandEditor.instantiate()
		command_editor.path_command = attribute.get_command(command_idx)
		# TODO Fix this mess, it's needed for individual path commands selection.
		command_editor.tid = get_node(^"../../../../../../..").tid
		command_editor.cmd_idx = command_idx
		command_editor.update_type()
		command_editor.cmd_update_value.connect(_update_command_value)
		command_editor.cmd_delete.connect(_delete)
		command_editor.cmd_toggle_relative.connect(_toggle_relative)
		command_editor.cmd_insert_after.connect(_insert_after)
		commands_container.add_child(command_editor)
		command_idx += 1


func _update_command_value(idx: int, new_value: float, property: StringName) -> void:
	attribute.set_command_property(idx, property, new_value)

func _delete(idx: int) -> void:
	attribute.delete_command(idx)

func _toggle_relative(idx: int) -> void:
	attribute.toggle_relative_command(idx)

func _insert_after(idx: int, cmd_type: String) -> void:
	attribute.insert_command(idx, cmd_type)


func _on_line_edit_text_submitted(new_text: String) -> void:
	set_value(new_text)

func _on_add_move_pressed() -> void:
	attribute.add_command("M")
