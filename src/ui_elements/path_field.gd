## An editor to be tied to an AttributePath.
extends AttributeEditor

const CommandEditor = preload("path_command_editor.tscn")

@onready var line_edit: LineEdit = $LineEdit
@onready var commands_container: VBoxContainer = $HBox/Commands
@onready var add_move: Button = $AddMove

signal value_changed(new_value: String, update_type: UpdateType)
var _value: String  # Must not be updated directly.

func set_value(new_value: String, update_type := UpdateType.REGULAR):
	if _value != new_value or update_type == UpdateType.FINAL:
		_value = new_value
		if update_type != UpdateType.NO_SIGNAL:
			value_changed.emit(new_value, update_type)

func get_value() -> String:
	return _value

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	if attribute != null:
		set_value(attribute.get_value())
		attribute.value_changed.connect(set_value)

func _on_value_changed(new_value: String, update_type: UpdateType) -> void:
	line_edit.text = new_value
	if attribute != null:
		match update_type:
			UpdateType.INTERMEDIATE:
				attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
			UpdateType.FINAL:
				attribute.set_value(new_value, Attribute.SyncMode.FINAL)
			_:
				attribute.set_value(new_value)
		# A plus button for adding a move command if empty.
		add_move.visible =  attribute.commands.is_empty()
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
		command_editor.tid = get_node(^"../../../../..").tid
		command_editor.cmd_idx = command_idx
		command_editor.cmd_update_value.connect(_update_command_value)
		command_editor.cmd_delete.connect(_delete)
		command_editor.cmd_toggle_relative.connect(_toggle_relative)
		command_editor.cmd_insert_after.connect(_insert_after)
		command_editor.cmd_convert_to.connect(_convert_to)
		commands_container.add_child(command_editor)
		command_editor.update_type()
		command_idx += 1


func _update_command_value(idx: int, new_value: float, property: StringName) -> void:
	attribute.set_command_property(idx, property, new_value)

func _delete(idx: int) -> void:
	var arr: Array[int] = [idx]
	attribute.delete_commands(arr)

func _toggle_relative(idx: int) -> void:
	attribute.toggle_relative_command(idx)

func _insert_after(idx: int, cmd_type: String) -> void:
	attribute.insert_command(idx, cmd_type)

func _convert_to(idx: int, new_type: String) -> void:
	attribute.convert_command(idx, new_type)


func _on_line_edit_text_submitted(new_text: String) -> void:
	set_value(new_text)

func _on_add_move_pressed() -> void:
	attribute.insert_command(0, "M")
