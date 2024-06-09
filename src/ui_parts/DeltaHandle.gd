# A handle that binds to a numeric attribute, relative to two other numeric attributes.
class_name DeltaHandle extends Handle

# Required.
var x_name: String
var y_name: String
var d_name: String
var horizontal: bool

func _init(new_tag: Tag, xref: String, yref: String, dref: String, p_horizontal: bool) -> void:
	tag = new_tag
	x_name = xref
	y_name = yref
	d_name = dref
	horizontal = p_horizontal
	display_mode = Display.SMALL
	sync()

func set_pos(new_pos: Vector2, save := true) -> void:
	if horizontal:
		new_pos = Vector2(tag.get_attribute(x_name).get_num() +\
				tag.get_attribute(d_name).get_num(), tag.get_attribute(y_name).get_num())
	else:
		new_pos = Vector2(tag.get_attribute(x_name).get_num(),
				tag.get_attribute(y_name).get_num() + tag.get_attribute(d_name).get_num())
	
	if pos != new_pos:
		pos = new_pos
		tag.get_attribute(d_name).set_num(
				absf(new_pos.x - tag.get_attribute(x_name).get_num() if horizontal\
				else new_pos.y - tag.get_attribute(y_name).get_num()), save)

func sync() -> void:
	if horizontal:
		pos = Vector2(tag.get_attribute(x_name).get_num() +\
				tag.get_attribute(d_name).get_num(), tag.get_attribute(y_name).get_num())
	else:
		pos = Vector2(tag.get_attribute(x_name).get_num(),
				tag.get_attribute(y_name).get_num() + tag.get_attribute(d_name).get_num())
	super()
