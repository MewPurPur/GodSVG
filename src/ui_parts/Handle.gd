class_name Handle extends RefCounted

signal moved(new_value: Vector2)

var pos: Vector2
var hovered := false
var dragged := false

func _init() -> void:
	pass

func set_pos(_new_pos: Vector2) -> void:
	pass

func sync() -> void:
	pass
