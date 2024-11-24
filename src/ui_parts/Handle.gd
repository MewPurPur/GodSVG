# Base class for handles.
class_name Handle extends RefCounted

enum Display {BIG, SMALL}
var display_mode := Display.BIG

var element: Element
var pos: Vector2
var transform: Transform2D

func _init() -> void:
	pass

func sync() -> void:
	transform = element.get_transform()

func set_pos(_new_pos: Vector2) -> void:
	pass
