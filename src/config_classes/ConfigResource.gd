# Implements a very useful signal.
abstract class_name ConfigResource extends Resource

signal changed_deferred

var _changed_deferred_pending := false

func _init() -> void:
	changed.connect(_queue_emit_changed_deferred)

func _queue_emit_changed_deferred() -> void:
	emit_changed_deferred.call_deferred()
	_changed_deferred_pending = true

func emit_changed_deferred() -> void:
	if _changed_deferred_pending:
		_changed_deferred_pending = false
		changed_deferred.emit()
