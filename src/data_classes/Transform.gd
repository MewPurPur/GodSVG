@abstract class_name Transform

@abstract func compute_transform() -> Transform2D
@abstract func compute_precise_transform() -> PackedFloat64Array
@abstract func is_redundant() -> bool

class TransformMatrix extends Transform:
	const name = "matrix"
	
	var x1: float
	var x2: float
	var y1: float
	var y2: float
	var o1: float
	var o2: float
	
	func _init(new_x1: float, new_x2: float, new_y1: float, new_y2: float, new_o1: float, new_o2: float) -> void:
		x1 = new_x1
		x2 = new_x2
		y1 = new_y1
		y2 = new_y2
		o1 = new_o1
		o2 = new_o2
	
	func compute_transform() -> Transform2D:
		return Transform2D(Vector2(x1, x2), Vector2(y1, y2), Vector2(o1, o2))
	
	func compute_precise_transform() -> PackedFloat64Array:
		return PackedFloat64Array([x1, x2, y1, y2, o1, o2])
	
	func is_redundant() -> bool:
		return x1 == 1.0 and x2 == 0.0 and y1 == 0.0 and y2 == 1.0 and o1 == 0.0 and o2 == 0.0
	
	func get_equivalent_basic_transform() -> Transform:
		if x1 == 1.0 and x2 == 0.0 and y1 == 0.0 and y2 == 1.0:
			if o1 == 0.0 and o2 == 0.0:
				return null  # The matrix is redundant.
			return TransformTranslate.new(o1, o2)
		
		if o1 == 0.0 and o2 == 0.0:
			if x2 == 0.0 and y1 == 0.0:
				return TransformScale.new(x1, y2)
			if x1 == 1.0 and y2 == 1.0:
				if x2 == 0.0:
					return TransformSkewX.new(rad_to_deg(atan(y1)))
				if y1 == 0.0:
					return TransformSkewY.new(rad_to_deg(atan(x2)))
		
		# For rotation, we need determinant and scale in both directions to be 1.
		if is_equal_approx(x1 * y2 - x2 * y1, 1.0) and is_equal_approx(sqrt(x1 * x1 + x2 * x2), 1.0) and is_equal_approx(sqrt(y1 * y1 + y2 * y2), 1.0):
			return TransformRotate.new(rad_to_deg(atan2(x2, x1)), o1, o2)
		
		return null

class TransformTranslate extends Transform:
	const name = "translate"
	
	var x: float
	var y: float
	
	func _init(new_x: float, new_y: float) -> void:
		x = new_x
		y = new_y
	
	func compute_transform() -> Transform2D:
		return Transform2D(Vector2.RIGHT, Vector2.DOWN, Vector2(x, y))
	
	func compute_precise_transform() -> PackedFloat64Array:
		return PackedFloat64Array([1.0, 0.0, 0.0, 1.0, x, y])
	
	func is_redundant() -> bool:
		return x == 0.0 and y == 0.0

class TransformRotate extends Transform:
	const name = "rotate"
	
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
	
	func compute_precise_transform() -> PackedFloat64Array:
		var rad := deg_to_rad(deg)
		var cos_val := cos(rad)
		var sin_val := sin(rad)
		return PackedFloat64Array([cos_val, sin_val, -sin_val, cos_val, x - x * cos_val + y * sin_val, y - x * sin_val - y * cos_val])
	
	func is_redundant() -> bool:
		return fmod(deg, 360.0) == 0.0

class TransformScale extends Transform:
	const name = "scale"
	
	var x: float
	var y: float
	
	func _init(new_x: float, new_y: float) -> void:
		x = new_x
		y = new_y
	
	func compute_transform() -> Transform2D:
		return Transform2D(Vector2.RIGHT * x, Vector2.DOWN * y, Vector2.ZERO)
	
	func compute_precise_transform() -> PackedFloat64Array:
		return PackedFloat64Array([x, 0, 0, y, 0, 0])
	
	func is_redundant() -> bool:
		return x == 1.0 and y == 1.0

class TransformSkewX extends Transform:
	const name = "skewX"
	
	var x: float
	
	func _init(new_x: float) -> void:
		x = new_x
	
	func compute_transform() -> Transform2D:
		return Transform2D(Vector2.RIGHT, Vector2(tan(deg_to_rad(x)), 1), Vector2.ZERO)
	
	func compute_precise_transform() -> PackedFloat64Array:
		return PackedFloat64Array([1.0, 0.0, tan(deg_to_rad(x)), 1.0, 0.0, 0.0])
	
	func is_redundant() -> bool:
		return x == 0.0


class TransformSkewY extends Transform:
	const name = "skewY"
	
	var y: float
	
	func _init(new_y: float) -> void:
		y = new_y
	
	func compute_transform() -> Transform2D:
		return Transform2D(Vector2(1, tan(deg_to_rad(y))), Vector2.DOWN, Vector2.ZERO)
	
	func compute_precise_transform() -> PackedFloat64Array:
		return PackedFloat64Array([1.0, tan(deg_to_rad(y)), 0.0, 1.0, 0.0, 0.0])
	
	func is_redundant() -> bool:
		return y == 0.0
