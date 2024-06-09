# An attribute representing a list of transformations.
class_name AttributeTransformList extends Attribute

var _transform_list: Array[Transform] = []
var _final_transform := Transform2D.IDENTITY

func _sync() -> void:
	_transform_list = TransformListParser.text_to_transform_list(get_value())
	_final_transform = compute_final_transform(_transform_list)

func sync_after_transforms_change() -> void:
	super.set_value(TransformListParser.transform_list_to_text(_transform_list))

func format(text: String) -> String:
	return TransformListParser.transform_list_to_text(
			TransformListParser.text_to_transform_list(text))

func set_transform_list(new_transform_list: Array[Transform]) -> void:
	_transform_list = new_transform_list
	_final_transform = compute_final_transform(new_transform_list)
	super.set_value(TransformListParser.transform_list_to_text(new_transform_list))

func set_transform_property(idx: int, property: String, new_value: float) -> void:
	if _transform_list[idx].get(property) != new_value:
		_transform_list[idx].set(property, new_value)
		sync_after_transforms_change()

func get_transform_list() -> Array[Transform]:
	return _transform_list

func get_transform_count() -> int:
	return _transform_list.size()

func get_transform(idx: int) -> Transform:
	return _transform_list[idx]

func get_final_transform() -> Transform2D:
	return _final_transform


static func compute_final_transform(transform_list: Array[Transform]) -> Transform2D:
	var final_transform := Transform2D.IDENTITY
	for t in transform_list:
		final_transform *= t.compute_transform()
	return final_transform

func delete_transform(idx: int) -> void:
	_transform_list.remove_at(idx)
	sync_after_transforms_change()

func insert_transform(idx: int, type: String) -> void:
	match type:
		"matrix": _transform_list.insert(idx, Transform.TransformMatrix.new(1, 0, 0, 1, 0, 0))
		"translate": _transform_list.insert(idx, Transform.TransformTranslate.new(0, 0))
		"rotate": _transform_list.insert(idx, Transform.TransformRotate.new(0, 0, 0))
		"scale": _transform_list.insert(idx, Transform.TransformScale.new(1, 1))
		"skewX": _transform_list.insert(idx, Transform.TransformSkewX.new(0))
		"skewY": _transform_list.insert(idx, Transform.TransformSkewY.new(0))
	sync_after_transforms_change()
