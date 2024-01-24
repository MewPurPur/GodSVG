## A handle that binds to a numeric attribute, relative to two other numeric attributes.
class_name DeltaHandle extends Handle

# Required.
var x_attribute: AttributeNumeric
var y_attribute: AttributeNumeric
var t_attribute : AttributeTransform

var horizontal: bool
var d_attribute: AttributeNumeric

func _init(id: PackedInt32Array, xref: AttributeNumeric, yref: AttributeNumeric, tref : AttributeTransform,\
dref: AttributeNumeric, p_horizontal: bool) -> void:
	tid = id
	x_attribute = xref
	y_attribute = yref
	t_attribute = tref
	d_attribute = dref
	horizontal = p_horizontal
	display_mode = Display.SMALL
	sync()

func set_pos(new_pos: Vector2, undo_redo := false) -> void:
	if initial_pos != new_pos and undo_redo:
		d_attribute.set_num(absf(new_pos.x - x_attribute.get_num() if horizontal else\
				new_pos.y - y_attribute.get_num()), Attribute.SyncMode.FINAL)
	else:
		d_attribute.set_num(absf(new_pos.x - x_attribute.get_num() if horizontal else\
				new_pos.y - y_attribute.get_num()), Attribute.SyncMode.FINAL if undo_redo\
				else Attribute.SyncMode.INTERMEDIATE)
	pos = Vector2(x_attribute.get_num(), y_attribute.get_num())
	if horizontal:
		pos += Vector2(d_attribute.get_num(), 0.0)
	else:
		pos += Vector2(0.0, d_attribute.get_num())

func sync() -> void:
	if horizontal:
		pos = Vector2(x_attribute.get_num() + d_attribute.get_num(), y_attribute.get_num())
	else:
		pos = Vector2(x_attribute.get_num(), y_attribute.get_num() + d_attribute.get_num())
	transform = t_attribute.get_final_transform()
