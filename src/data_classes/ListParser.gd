# A parser to turn AttributeList's list into other useful things.
@abstract class_name ListParser

static func rect_to_list(rect: Rect2) -> PackedFloat64Array:
	return PackedFloat64Array([rect.position.x, rect.position.y, rect.size.x, rect.size.y])

# Converts the list of floats into a list of Vector2s.
static func list_to_points(list: PackedFloat64Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	@warning_ignore("integer_division")
	points.resize(list.size() / 2)
	for idx in points.size():
		points[idx] = Vector2(list[idx * 2], list[idx * 2 + 1])
	return points
