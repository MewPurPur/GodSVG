@icon("res://godot_only/icons/HTitledPanel.svg")
@tool
class_name HTitledPanel extends TitledPanel

func _get_minimum_size() -> Vector2:
	return _get_minimum_size_common_logic(false)

func _notification(what: int) -> void:
	_notification_common_logic(what, false)
