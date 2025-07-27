# This class only exists because it's stupid how Godot's UndoRedo extends Object.
# I mean, every class you're expected to construct is a RefCounted. Objects are used
# for sitting ducks like singletons and read-only stuff. Except UndoRedo, which is easy
# memory leaks if you forget to free it.
class_name UndoRedoRef

signal version_changed

var _undo_redo := UndoRedo.new()

func _init() -> void:
	_undo_redo.version_changed.connect(version_changed.emit)

func create_action(name := "") -> void:
	_undo_redo.create_action(name)

func add_do_method(callable: Callable) -> void:
	_undo_redo.add_do_method(callable)

func add_undo_method(callable: Callable) -> void:
	_undo_redo.add_undo_method(callable)

func add_do_property(object: Object, property: StringName, value: Variant) -> void:
	_undo_redo.add_do_property(object, property, value)

func add_undo_property(object: Object, property: StringName, value: Variant) -> void:
	_undo_redo.add_undo_property(object, property, value)

func add_do_reference(object: Object) -> void:
	_undo_redo.add_do_reference(object)

func add_undo_reference(object: Object) -> void:
	_undo_redo.add_undo_reference(object)

func commit_action() -> void:
	_undo_redo.commit_action()

func undo() -> bool:
	return _undo_redo.undo()

func redo() -> bool:
	return _undo_redo.redo()

func has_undo() -> bool:
	return _undo_redo.has_undo()

func has_redo() -> bool:
	return _undo_redo.has_redo()

func clear_history() -> void:
	_undo_redo.clear_history()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_undo_redo):
			_undo_redo.free()
