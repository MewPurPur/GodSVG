# A handle that binds to two numeric attributes.
class_name XYHandle extends Handle

var x_name: String
var y_name: String

func _init(new_tag: Tag, xref: String, yref: String) -> void:
	tag = new_tag
	x_name = xref
	y_name = yref
	sync()

func set_pos(new_pos: Vector2, save := false) -> void:
	if pos != new_pos:
		pos = new_pos
		tag.get_attribute(x_name).set_num(new_pos.x, save)
		tag.get_attribute(y_name).set_num(new_pos.y, save)

func sync() -> void:
	pos = Vector2(tag.get_attribute(x_name).get_num(), tag.get_attribute(y_name).get_num())
	super()
