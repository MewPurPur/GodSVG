class_name XYHandle extends Handle

var x_attribute: Attribute
var y_attribute: Attribute

func _init(x_ref: Attribute, y_ref: Attribute) -> void:
	x_attribute = x_ref
	y_attribute = y_ref
	sync()

func set_pos(new_pos: Vector2) -> void:
	if new_pos.x != pos.x:
		x_attribute.value = new_pos.x
		pos.x = new_pos.x
	if new_pos.y != pos.y:
		y_attribute.value = new_pos.y
		pos.y = new_pos.y
	super(new_pos)

func sync() -> void:
	pos = Vector2(x_attribute.value if x_attribute != null else 0.0,
			y_attribute.value if y_attribute != null else 0.0)
