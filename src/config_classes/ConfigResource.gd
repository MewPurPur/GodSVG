# Implements a very useful signal.
@abstract class_name ConfigResource extends Resource

signal changed_deferred

var _initial_load_finished := false
var _changed_deferred_pending := false

func _init() -> void:
	changed.connect(_queue_emit_changed_deferred)
	set_deferred("_initial_load_finished", true)

func _queue_emit_changed_deferred() -> void:
	if _initial_load_finished:
		emit_changed_deferred.call_deferred()
		_changed_deferred_pending = true

func emit_changed_deferred() -> void:
	if _changed_deferred_pending:
		_changed_deferred_pending = false
		changed_deferred.emit()

func external_call(callback: Callable) -> void:
	if _initial_load_finished:
		callback.call_deferred()
