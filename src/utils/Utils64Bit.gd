## Vector2 and Transform2D aren't precise enough to have their numbers used directly in the SVG, as they are 32-bit.
## GodSVG uses PackedFloat64Array to mock them and this class implements the necessary functionality to make them work.
@abstract class_name Utils64Bit

## Converts a PackedFloat64Array with two elements meant to represent a Vector2 into a Vector2.
static func get_vector(vector: PackedFloat64Array) -> Vector2:
	return Vector2(vector[0], vector[1])

## Converts a PackedFloat64Array with six elements meant to represent a Transform2D into a Transform2D.
static func get_transform(transform: PackedFloat64Array) -> Transform2D:
	return Transform2D(Vector2(transform[0], transform[1]), Vector2(transform[2], transform[3]), Vector2(transform[4], transform[5]))

## 64-bit version of Vector2 * Transform2D = Vector2
static func transform_vector_mult(transform: PackedFloat64Array, vector: PackedFloat64Array) -> PackedFloat64Array:
	var x := vector[0]
	var y := vector[1]
	var xx := transform[0]
	var xy := transform[1]
	var yx := transform[2]
	var yy := transform[3]
	var ox := transform[4]
	var oy := transform[5]
	return PackedFloat64Array([xx * x + yx * y + ox, xy * x + yy * y + oy])

## 64-bit version of Transform2D.determinant() = float
static func get_transform_determinant(transform: PackedFloat64Array) -> float:
	var xx := transform[0]
	var xy := transform[1]
	var yx := transform[2]
	var yy := transform[3]
	return xx * yy - xy * yx

## 64-bit version of Transform2D.affine_inverse() = Transform2D
static func get_transform_affine_inverse(transform: PackedFloat64Array) -> PackedFloat64Array:
	var det := get_transform_determinant(transform)
	if det == 0:
		return PackedFloat64Array([NAN, NAN, NAN, NAN, NAN, NAN])
	var idet := 1.0 / det
	
	var xx := transform[0]
	var xy := transform[1]
	var yx := transform[2]
	var yy := transform[3]
	var ox := transform[4]
	var oy := transform[5]
	
	var new_xx := yy * idet
	var new_xy := -xy * idet
	var new_yx := -yx * idet
	var new_yy := xx * idet
	var new_ox := -(new_xx * ox + new_yx * oy)
	var new_oy := -(new_xy * ox + new_yy * oy)
	return PackedFloat64Array([new_xx, new_xy, new_yx, new_yy, new_ox, new_oy])

## 64-bit version of Transform2D * Transform2D = Transform2D
static func transforms_mult(a: PackedFloat64Array, b: PackedFloat64Array) -> PackedFloat64Array:
	var a_xx := a[0]
	var a_xy := a[1]
	var a_yx := a[2]
	var a_yy := a[3]
	var a_ox := a[4]
	var a_oy := a[5]
	
	var b_xx := b[0]
	var b_xy := b[1]
	var b_yx := b[2]
	var b_yy := b[3]
	var b_ox := b[4]
	var b_oy := b[5]
	
	var xx := a_xx * b_xx + a_yx * b_xy
	var xy := a_yy * b_xy + a_xy * b_xx
	var yx := a_yx * b_yy + a_xx * b_yx
	var yy := a_xy * b_yx + a_yy * b_yy
	var ox := a_xx * b_ox + a_yx * b_oy + a_ox
	var oy := a_xy * b_ox + a_yy * b_oy + a_oy
	return PackedFloat64Array([xx, xy, yx, yy, ox, oy])

## 64-bit version of Vector2.project(Vector2) = Vector2
static func vector_project(a: PackedFloat64Array, b: PackedFloat64Array) -> PackedFloat64Array:
	var scalar := dot(a, b) / dot(b, b)
	return [b[0] * scalar, b[1] * scalar]

## 64-bit version of Vector2.dot(Vector2) = float
static func dot(a: PackedFloat64Array, b: PackedFloat64Array) -> float:
	return a[0] * b[0] + a[1] * b[1]


static func transform_vector_array_mult(transform: PackedFloat64Array, vectors: PackedVector2Array) -> PackedVector2Array:
	var result: PackedVector2Array
	result.resize(vectors.size())
	for i in vectors.size():
		result[i] = get_vector(transform_vector_mult(transform, [vectors[i].x, vectors[i].y]))
	return result
