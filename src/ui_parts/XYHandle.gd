## A handle that binds to one or two numeric attributes.
class_name XYHandle extends Handle

var x_attribute: AttributeNumeric
var y_attribute: AttributeNumeric
var delta_x_attribute: AttributeNumeric
var delta_y_attribute: AttributeNumeric

func _init(id: PackedInt32Array, x_ref: Attribute, y_ref: Attribute) -> void:
	tid = id
	x_attribute = x_ref
	y_attribute = y_ref
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
	pos = Vector2(x_attribute.get_num() if x_attribute != null else 0.0,
			y_attribute.get_num() if y_attribute != null else 0.0)
