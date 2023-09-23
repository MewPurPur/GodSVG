class_name Handle extends RefCounted

signal moved_x(new_value: float)
signal moved_y(new_value: float)

var pos: Vector2
var hovered := false
var dragged := false
var tag: SVGTag
var callable: Callable
func _init(new_pos: Vector2, new_tag: SVGTag, new_callable: Callable) -> void:
	pos = new_pos
	tag = new_tag
	callable = new_callable
func set_pos(new_pos: Vector2) -> void:
	pos = new_pos
	callable.call(pos, tag)
