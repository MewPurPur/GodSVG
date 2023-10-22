extends Node

var undo_redo:UndoRedo = UndoRedo.new()
func _input(event):
	if event.is_action_pressed(&"redo"):
		if undo_redo.has_redo():
			undo_redo.redo()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"undo"):
		if undo_redo.has_undo():
			undo_redo.undo()
		get_viewport().set_input_as_handled()
