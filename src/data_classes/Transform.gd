class_name Transform extends RefCounted

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
