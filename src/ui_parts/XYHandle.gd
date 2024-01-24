## A handle that binds to two numeric attributes.
class_name XYHandle extends Handle

var x_attribute: AttributeNumeric
var y_attribute: AttributeNumeric
var t_attribute: AttributeTransform

func _init(id: PackedInt32Array, xref: AttributeNumeric, yref: AttributeNumeric, tref: AttributeTransform) -> void:
	tid = id
	x_attribute = xref
	y_attribute = yref
	t_attribute = tref
	sync()

func set_pos(new_pos: Vector2, undo_redo := false) -> void:
	if undo_redo:
		if initial_pos != new_pos:
			x_attribute.set_num(new_pos.x, Attribute.SyncMode.NO_PROPAGATION)
			y_attribute.set_num(new_pos.y, Attribute.SyncMode.FINAL)
	else:
		if new_pos.x != pos.x:
			x_attribute.set_num(new_pos.x, Attribute.SyncMode.INTERMEDIATE if\
					new_pos.y == pos.y else Attribute.SyncMode.NO_PROPAGATION)
		if new_pos.y != pos.y:
			y_attribute.set_num(new_pos.y, Attribute.SyncMode.INTERMEDIATE)
	pos = new_pos

func sync() -> void:
	pos = Vector2(x_attribute.get_num(), y_attribute.get_num())
	transform = t_attribute.get_final_transform()
