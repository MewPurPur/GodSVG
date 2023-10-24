extends Node

signal redo_excuted(action_name)
signal undo_excuted(action_name)

var _undo_redo:UndoRedo = UndoRedo.new()
enum MergeMode{
	MERGE_DISABLE = 0,
	MERGE_ENDS = 1,
	MERGE_ALL = 2
	}
var is_excuting:bool = false

func _input(event) -> void:
	if event.is_action_pressed(&"redo"):
		if _undo_redo.has_redo():
			var action_name = _undo_redo.get_action_name(_undo_redo.get_current_action()+1) # +1 not sure if bug
			is_excuting = true
			_undo_redo.redo()
			is_excuting = false
			redo_excuted.emit(action_name)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"undo"):
		if _undo_redo.has_undo():
			var action_name = _undo_redo.get_current_action_name()
			is_excuting = true
			_undo_redo.undo()
			is_excuting = false
			undo_excuted.emit(action_name)
		get_viewport().set_input_as_handled()

func add_action_simple_methods(action_name:String,redo:Callable,\
	undo:Callable,add_reference:Object = null,execute:bool = true) -> void:
	UndoRedoManager.create_action(action_name)
	UndoRedoManager.add_do_reference(add_reference)
	UndoRedoManager.add_undo_reference(add_reference)
	UndoRedoManager.add_do_method(redo)
	UndoRedoManager.add_undo_method(undo)
	UndoRedoManager.commit_action(execute)
	
func add_action_simple_property(action_name:String,object: Object,\
	 property: StringName, redo_value: Variant, undo_value: Variant,execute:bool = true) -> void:
	UndoRedoManager.create_action(action_name)
	UndoRedoManager.add_do_reference(object)
	UndoRedoManager.add_undo_reference(object)
	UndoRedoManager.add_do_property(object, property, redo_value)
	UndoRedoManager.add_undo_property(object, property, undo_value)
	UndoRedoManager.commit_action(execute)

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
