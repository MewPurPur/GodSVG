## An attribute representing a list of transforms.
class_name AttributeTransform extends Attribute

class Transform extends RefCounted:
	func compute_transform() -> Transform2D:
		return Transform2D.IDENTITY

class TransformMatrix extends Transform:
	var x1: float
	var x2: float
	var y1: float
	var y2: float
	var o1: float
	var o2: float
	
	func _init(new_x1: float, new_x2: float, new_y1: float, new_y2: float, new_o1: float,
	new_o2: float) -> void:
		x1 = new_x1
		x2 = new_x2
		y1 = new_y1
		y2 = new_y2
		o1 = new_o1
		o2 = new_o2
	
	func compute_transform() -> Transform2D:
		return Transform2D(Vector2(x1, x2), Vector2(y1, y2), Vector2(o1, o2))

class TransformTranslate extends Transform:
	var x: float
	var y: float
	
	func _init(new_x: float, new_y: float) -> void:
		x = new_x
		y = new_y
	
	func compute_transform() -> Transform2D:
		return Transform2D(Vector2.RIGHT, Vector2.DOWN, Vector2(x, y))

class TransformRotate extends Transform:
	var deg: float
	var x: float
	var y: float
	
	func _init(new_deg: float, new_x: float, new_y: float) -> void:
		deg = new_deg
		x = new_x
		y = new_y
	
	func compute_transform() -> Transform2D:
		var pt := Vector2(x, y)
		return Transform2D.IDENTITY.translated(-pt).rotated(deg_to_rad(deg)).translated(pt)

class TransformScale extends Transform:
	var x: float
	var y: float
	
	func _init(new_x: float, new_y: float) -> void:
		x = new_x
		y = new_y
	
	func compute_transform() -> Transform2D:
		return Transform2D(Vector2.RIGHT * x, Vector2.DOWN * y, Vector2.ZERO)

class TransformSkewX extends Transform:
	var x: float
	
	func _init(new_x: float) -> void:
		x = new_x
	
	func compute_transform() -> Transform2D:
		return Transform2D(Vector2.RIGHT, Vector2(tan(deg_to_rad(x)), 1), Vector2.ZERO)

class TransformSkewY extends Transform:
	var y: float
	
	func _init(new_y: float) -> void:
		y = new_y
	
	func compute_transform() -> Transform2D:
		return Transform2D(Vector2(1, tan(deg_to_rad(y))), Vector2.DOWN, Vector2.ZERO)


var _transform_list: Array[Transform] = []
var _final_transform := Transform2D.IDENTITY

func _init() -> void:
	default = ""
	set_value(default, SyncMode.SILENT)

func _sync() -> void:
	_transform_list = TransformListParser.text_to_transform_list(get_value())
	_final_transform = AttributeTransform.compute_final_transform(_transform_list)

func sync_after_transforms_change(sync_mode := SyncMode.LOUD) -> void:
	super.set_value(TransformListParser.transform_list_to_text(_transform_list), sync_mode)

func autoformat(text: String) -> String:
	return TransformListParser.transform_list_to_text(
			TransformListParser.text_to_transform_list(text))

func set_transform_list(new_transform_list: Array[Transform],
sync_mode := SyncMode.LOUD) -> void:
	_transform_list = new_transform_list
	_final_transform = AttributeTransform.compute_final_transform(new_transform_list)
	super.set_value(TransformListParser.transform_list_to_text(new_transform_list),
			sync_mode)

func set_transform_property(idx: int, property: String, new_value: float,
sync_mode := SyncMode.LOUD) -> void:
	if _transform_list[idx].get(property) != new_value or sync_mode == SyncMode.FINAL:
		_transform_list[idx].set(property, new_value)
		sync_after_transforms_change(sync_mode)

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
		"matrix": _transform_list.insert(idx, TransformMatrix.new(1, 0, 0, 1, 0, 0))
		"translate": _transform_list.insert(idx, TransformTranslate.new(0, 0))
		"rotate": _transform_list.insert(idx, TransformRotate.new(0, 0, 0))
		"scale": _transform_list.insert(idx, TransformScale.new(1, 1))
		"skewX": _transform_list.insert(idx, TransformSkewX.new(0))
		"skewY": _transform_list.insert(idx, TransformSkewY.new(0))
	sync_after_transforms_change()
