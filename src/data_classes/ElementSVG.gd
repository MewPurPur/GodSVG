# An <svg> element.
class_name ElementSVG extends Element

# TODO Fix up the logic for handling x, y, and aspect ratio handling.
#var x: float
#var y: float
var width: float
var height: float
var normalized_diagonal: float
var viewbox: Rect2

var canvas_transform: Transform2D  # Automatically updated with the precise transform.
var canvas_precise_transform: PackedFloat64Array:
	set(new_value):
		canvas_precise_transform = new_value
		canvas_transform = Utils64Bit.get_transform(canvas_precise_transform)

const name = "svg"
const possible_conversions: Array[String] = []

func _init() -> void:
	attribute_changed.connect(_conditional_update_cache)
	# If attributes change in an ancestor, it can affect percentage calculations.
	ancestor_attribute_changed.connect(_conditional_update_cache)
	super()

func _conditional_update_cache(attribute_name: String) -> void:
	if attribute_name in ["width", "height", "viewBox"]:
		update_cache()

func update_cache() -> void:
	if svg == null and root != self:
		return
	
	var has_valid_width := has_attribute("width")
	var has_valid_height := has_attribute("height")
	var has_valid_viewbox := has_attribute("viewBox")
	# Return early on invalid input.
	if not has_valid_viewbox and not (has_valid_width and has_valid_height):
		width = get_attribute_num("width") if has_valid_width else 0.0
		height = get_attribute_num("height") if has_valid_height else 0.0
		normalized_diagonal = Vector2(width, height).length() / sqrt(2)
		viewbox = Rect2(0, 0, 0, 0)
		canvas_precise_transform = PackedFloat64Array([1.0, 0.0, 0.0, 1.0, 0.0, 0.0])
		return
	
	# From now on we're sure the input is valid. Cache width and height.
	if has_valid_width:
		width = get_attribute_num("width")
		if not has_valid_height:
			height = width / get_attribute("viewBox").get_list_element(2) *\
					get_attribute("viewBox").get_list_element(3)
		else:
			height = get_attribute_num("height")
	elif has_valid_height:
		height = get_attribute_num("height")
		width = height / get_attribute("viewBox").get_list_element(3) *\
				get_attribute("viewBox").get_list_element(2)
	else:
		width = get_attribute("viewBox").get_list_element(2)
		height = get_attribute("viewBox").get_list_element(3)
	
	# Cache viewbox.
	if has_valid_viewbox and get_attribute("viewBox").get_list_size() >= 4:
		var viewbox_attrib: AttributeList = get_attribute("viewBox")
		viewbox = Rect2(viewbox_attrib.get_list_element(0), viewbox_attrib.get_list_element(1),
				viewbox_attrib.get_list_element(2), viewbox_attrib.get_list_element(3))
	else:
		viewbox = Rect2(0, 0, get_attribute_num("width"), get_attribute_num("height"))
	# Cache canvas transform.
	var width_ratio := width / viewbox.size.x
	var height_ratio := height / viewbox.size.y
	if width_ratio < height_ratio:
		canvas_precise_transform = PackedFloat64Array([
				width_ratio, 0.0, 0.0, width_ratio, -viewbox.position.x * width_ratio,
				-viewbox.position.y * width_ratio + (height - width_ratio * viewbox.size.y) / 2.0])
	else:
		canvas_precise_transform = PackedFloat64Array([
				height_ratio, 0.0, 0.0, height_ratio, -viewbox.position.x * height_ratio +\
				(width - height_ratio * viewbox.size.x) / 2, -viewbox.position.y * height_ratio])
	if not canvas_transform.is_finite():
		canvas_precise_transform = PackedFloat64Array([1.0, 0.0, 0.0, 1.0, 0.0, 0.0])
	normalized_diagonal = Vector2(width, height).length() / sqrt(2)


func canvas_to_world(pos: Vector2) -> Vector2:
	return canvas_transform * pos

func world_to_canvas(pos: Vector2) -> Vector2:
	return canvas_transform.affine_inverse() * pos

func world_to_canvas_64_bit(pos: PackedFloat64Array) -> PackedFloat64Array:
	return Utils64Bit.transform_vector_mult(Utils64Bit.get_transform_affine_inverse(
			canvas_precise_transform), pos)

func get_size() -> Vector2:
	return Vector2(width, height)


func _get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"x", "y": return "0"
		_: return ""
