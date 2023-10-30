## Base class for handles.
class_name Handle extends RefCounted

signal moved(new_value: Vector2)

enum DisplayMode {BIG, SMALL}
var display_mode := DisplayMode.BIG

var tag: Tag
var tag_index := -1
var pos: Vector2

func _init() -> void:
	pass

func set_pos(new_pos: Vector2) -> void:
	moved.emit(new_pos)

func sync() -> void:
	pass
