# Base class for handles.
class_name Handle extends RefCounted

enum Display {BIG, SMALL}
var display_mode := Display.BIG

var element: Element
var transform: Transform2D
# TODO This property needs to be two floats for the sake of 64-bit accuracy.
var pos: Vector2

func _init() -> void:
	pass

func sync() -> void:
	transform = element.get_transform()

func set_pos(_new_pos: Vector2) -> void:
	pass
