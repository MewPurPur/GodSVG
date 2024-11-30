# A parser to turn AttributeList's list into other useful things.
class_name ListParser extends RefCounted

static func rect_to_list(rect: Rect2) -> PackedFloat64Array:
	return PackedFloat64Array([rect.position.x, rect.position.y, rect.size.x, rect.size.y])

static func list_to_points(list: PackedFloat64Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	@warning_ignore("integer_division")
	for idx in list.size() / 2:
		points.append(Vector2(list[idx * 2], list[idx * 2 + 1]))
	return points
