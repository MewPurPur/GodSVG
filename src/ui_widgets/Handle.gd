## Base class for handles.
@abstract class_name Handle

enum Display {BIG, SMALL, SQUARE}
var display_mode := Display.BIG

var element: Element
var transform: Transform2D
var precise_transform := PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
var position: Vector2
var precise_position := PackedFloat64Array([0.0, 0.0])

func _init() -> void:
	pass

func sync() -> void:
	transform = element.get_transform()
	precise_transform = element.get_precise_transform()
	position = Vector2(precise_position[0], precise_position[1])

func set_position(_new_position: PackedFloat64Array) -> void:
	pass
