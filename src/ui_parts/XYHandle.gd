class_name XYHandle extends Handle

var x_attribute: Attribute
var y_attribute: Attribute

func _init(tag_idx: int, x_ref: Attribute, y_ref: Attribute) -> void:
	tag_index = tag_idx
	x_attribute = x_ref
	y_attribute = y_ref
	sync()

func set_pos(new_pos: Vector2) -> void:
	if new_pos.x != pos.x:
		x_attribute.set_value(new_pos.x, new_pos.y == pos.y)
	if new_pos.y != pos.y:
		y_attribute.set_value(new_pos.y)
	pos = new_pos
	super(new_pos)

func sync() -> void:
	pos = Vector2(x_attribute.get_value() if x_attribute != null else 0.0,
			y_attribute.get_value() if y_attribute != null else 0.0)
