# Base class for handles.
class_name Handle extends RefCounted

enum Display {BIG, SMALL}
var display_mode := Display.BIG

var element: Element
var transform: Transform2D
var precise_transform := PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
var pos: Vector2
var precise_pos := PackedFloat64Array([0.0, 0.0])

func _init() -> void:
	pass

func sync() -> void:
	transform = element.get_transform()
	precise_transform = element.get_precise_transform()
	pos = Vector2(precise_pos[0], precise_pos[1])

func set_pos(_new_pos: PackedFloat64Array) -> void:
	pass
