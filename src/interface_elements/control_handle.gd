class_name Handle extends RefCounted

signal moved_x(new_value: float)
signal moved_y(new_value: float)

var pos: Vector2
var hovered := false
var dragged := false
var x_attribute: SVGAttribute
var y_attribute: SVGAttribute

func _init(x_ref: SVGAttribute, y_ref: SVGAttribute) -> void:
	x_attribute = x_ref
	y_attribute = y_ref
	sync()

func set_pos(new_pos: Vector2) -> void:
	if new_pos.x != pos.x:
		pos.x = new_pos.x
		x_attribute.value = new_pos.x
	if new_pos.y != pos.y:
		pos.y = new_pos.y
		y_attribute.value = new_pos.y

func sync() -> void:
	pos = Vector2(x_attribute.value if x_attribute != null else 0.0,
			y_attribute.value if y_attribute != null else 0.0)
