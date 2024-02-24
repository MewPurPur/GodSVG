## An editor to be tied to an AttributePath.
extends VBoxContainer

signal focused
var attribute: AttributePath
var attribute_name: String

const CommandEditor = preload("path_command_editor.tscn")

@onready var line_edit: LineEdit = $LineEdit
@onready var commands_container: VBoxContainer = $HBox/Commands
@onready var add_move: Button = $AddMove

func set_value(new_value: String, update_type := Utils.UpdateType.REGULAR):
	sync(attribute.autoformat(new_value))
	if attribute.get_value() != new_value or update_type == Utils.UpdateType.FINAL:
		match update_type:
			Utils.UpdateType.INTERMEDIATE:
				attribute.set_value(new_value, Attribute.SyncMode.INTERMEDIATE)
			Utils.UpdateType.FINAL:
				attribute.set_value(new_value, Attribute.SyncMode.FINAL)
			_:
				attribute.set_value(new_value)

func _ready() -> void:
	set_value(attribute.get_value())
	attribute.value_changed.connect(set_value)
	line_edit.tooltip_text = attribute_name


func rebuild_commands() -> void:
	var command_idx := 0
	for command_editor in commands_container.get_children():
		if command_idx >= attribute.get_command_count():
			command_editor.queue_free()
		else:
			var command: PathCommand = attribute.get_command(command_idx)
			if command_editor.cmd_char == command.command_char:
				command_editor.path_command = command
				command_editor.queue_redraw()
			else:
				command_editor.queue_free()
				var new_command_editor := CommandEditor.instantiate()
				new_command_editor.path_command = command
				# TODO Fix this mess, it's needed for individual path commands selection.
				new_command_editor.tid = get_node(^"../../../../..").tid
				new_command_editor.cmd_idx = command_idx
				commands_container.add_child(new_command_editor)
				commands_container.move_child(new_command_editor, command_idx)
		command_idx += 1
	
	while command_idx < attribute.get_command_count():
		var command_editor := CommandEditor.instantiate()
		command_editor.path_command = attribute.get_command(command_idx)
		# TODO Fix this mess, it's needed for individual path commands selection.
		command_editor.tid = get_node(^"../../../../..").tid
		command_editor.cmd_idx = command_idx
		commands_container.add_child(command_editor)
		command_idx += 1


func _on_line_edit_text_submitted(new_text: String) -> void:
	set_value(new_text)

func _on_line_edit_focus_entered() -> void:
	focused.emit()

func _on_add_move_pressed() -> void:
	attribute.insert_command(0, "M")

func sync(new_value: String) -> void:
	line_edit.text = new_value
	# A plus button for adding a move command if empty.
	add_move.visible = (attribute.get_command_count() == 0)
	rebuild_commands()
