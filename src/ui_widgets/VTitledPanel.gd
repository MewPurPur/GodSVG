@icon("res://godot_only/icons/VTitledPanel.svg")
class_name VTitledPanel extends TitledPanel

func _get_minimum_size() -> Vector2:
	return _get_minimum_size_common_logic(true)

func _notification(what: int) -> void:
	_notification_common_logic(what, true)
