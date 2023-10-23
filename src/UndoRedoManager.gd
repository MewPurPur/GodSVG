extends Node

var _undo_redo:UndoRedo = UndoRedo.new()
enum MergeMode{
	MERGE_DISABLE = 0,
	MERGE_ENDS = 1,
	MERGE_ALL = 2
	}

func _input(event) -> void:
	if event.is_action_pressed(&"redo"):
		if _undo_redo.has_redo():
			_undo_redo.redo()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"undo"):
		if _undo_redo.has_undo():
			_undo_redo.undo()
		get_viewport().set_input_as_handled()

func add_do_method(callable: Callable) -> void:
	_undo_redo.add_do_method(callable)
	
func add_do_property(object: Object, property: StringName, value: Variant) -> void:
	_undo_redo.add_do_property(object, property, value)
	
func add_do_reference(object: Object) -> void:
	_undo_redo.add_do_reference(object)
	
func add_undo_method(callable: Callable) -> void:
	_undo_redo.add_undo_method(callable)
	
func add_undo_property(object: Object, property: StringName, value: Variant) -> void:
	_undo_redo.add_undo_property(object, property , value )
	
func add_undo_reference(object: Object) -> void:
	_undo_redo.add_undo_reference(object)
	
func clear_history(increase_version: bool = true) -> void:
	_undo_redo.clear_history(increase_version)
	
func commit_action(execute: bool = true) -> void:
	_undo_redo.commit_action(execute)
	
func create_action(action_name: String, merge_mode: MergeMode = MergeMode.MERGE_DISABLE , backward_undo_ops: bool = false) -> void:
	match  merge_mode:
		_undo_redo.MERGE_DISABLE:
			_undo_redo.create_action(action_name,_undo_redo.MERGE_DISABLE, backward_undo_ops)
		_undo_redo.MERGE_ENDS:
			_undo_redo.create_action(action_name,_undo_redo.MERGE_ENDS, backward_undo_ops)
		_undo_redo.MERGE_ALL:
			_undo_redo.create_action(action_name,_undo_redo.MERGE_ALL, backward_undo_ops)
