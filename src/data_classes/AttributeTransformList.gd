## An attribute representing a list of transformations.
class_name AttributeTransformList extends Attribute

var _transform_list: Array[Transform] = []
var _final_precise_transform := PackedFloat64Array([1.0, 0.0, 0.0, 1.0, 0.0, 0.0])

func _sync() -> void:
	_transform_list = text_to_transform_list(get_value())
	_final_precise_transform = compute_final_precise_transform(_transform_list)

func sync_after_transforms_change() -> void:
	set_value(transform_list_to_text(_transform_list))

func format(text: String, formatter: Formatter) -> String:
	return transform_list_to_text(text_to_transform_list(text), formatter)

func set_transform_list(new_transform_list: Array[Transform]) -> void:
	_transform_list = new_transform_list
	_final_precise_transform = compute_final_precise_transform(new_transform_list)
	set_value(transform_list_to_text(new_transform_list))

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

func get_final_precise_transform() -> PackedFloat64Array:
	return _final_precise_transform


static func compute_final_precise_transform(
transform_list: Array[Transform]) -> PackedFloat64Array:
	var final_transform := PackedFloat64Array([1.0, 0.0, 0.0, 1.0, 0.0, 0.0])
	for t in transform_list:
		final_transform = Utils64Bit.transforms_mult(final_transform, t.compute_precise_transform())
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


func transform_list_to_text(transform_list: Array[Transform], formatter := Configs.savedata.editor_formatter) -> String:
	var output := ""
	var num_parser := NumstringParser.new()
	num_parser.compress_numbers = formatter.transform_list_compress_numbers
	num_parser.minimize_spacing = formatter.transform_list_minimize_spacing
	
	for t in transform_list:
		if t is Transform.TransformMatrix:
			output += "matrix(%s) " % num_parser.numstr_arr_to_text([
					num_parser.num_to_text(t.x1), num_parser.num_to_text(t.x2),
					num_parser.num_to_text(t.y1), num_parser.num_to_text(t.y2),
					num_parser.num_to_text(t.o1), num_parser.num_to_text(t.o2)])
		elif t is Transform.TransformTranslate:
			if t.y == 0 and formatter.transform_list_remove_unnecessary_params:
				output += "translate(%s) " % num_parser.num_to_text(t.x)
			else:
				output += "translate(%s) " % num_parser.numstr_arr_to_text([num_parser.num_to_text(t.x), num_parser.num_to_text(t.y)])
		elif t is Transform.TransformRotate:
			if t.x == 0 and t.y == 0 and formatter.transform_list_remove_unnecessary_params:
				output += "rotate(%s) " % num_parser.num_to_text(t.deg, true)
			else:
				output += "rotate(%s) " % num_parser.numstr_arr_to_text([num_parser.num_to_text(t.deg, true),
						num_parser.num_to_text(t.x), num_parser.num_to_text(t.y)])
		elif t is Transform.TransformScale:
			if t.x == t.y and formatter.transform_list_remove_unnecessary_params:
				output += "scale(%s) " % num_parser.num_to_text(t.x)
			else:
				output += "scale(%s) " % num_parser.numstr_arr_to_text([num_parser.num_to_text(t.x), num_parser.num_to_text(t.y)])
		elif t is Transform.TransformSkewX:
			output += "skewX(%s) " % num_parser.num_to_text(t.x, true)
		elif t is Transform.TransformSkewY:
			output += "skewY(%s) " % num_parser.num_to_text(t.y, true)
	return output.trim_suffix(" ")

static func text_to_transform_list(text: String) -> Array[Transform]:
	text = text.strip_edges()
	if text.is_empty() or not text.ends_with(")"):
		return []
	
	var output: Array[Transform] = []
	var transforms := text.split(")", false)
	for idx in transforms.size():
		var transform := transforms[idx]
		var transform_info := transform.split("(")
		if transform_info.size() != 2:
			return []
		
		var transform_params := transform_info[1].strip_edges()
		var transform_name := transform_info[0].strip_edges(false, true)
		if transform_name.is_empty() or (idx > 0 and not transform_name[0] in ", \t\n\r"):
			return []
		
		match transform_name.strip_edges(true, false).trim_prefix(",").strip_edges(true, false):
			"matrix":
				var result := NumstringParser.text_to_number_arr(transform_params, 0, 6)
				if result.is_empty() or result[1] < transform_params.length():
					return []
				output.append(Transform.TransformMatrix.new(result[0][0], result[0][1], result[0][2], result[0][3], result[0][4], result[0][5]))
			"translate":
				var result1 := NumstringParser.text_to_number_arr(transform_params, 0, 1)
				if result1.is_empty():
					return []
				var result2 := NumstringParser.text_to_number_arr(transform_params, result1[1], 1, true)
				if result2.is_empty():
					if result1[1] >= transform_params.length():
						output.append(Transform.TransformTranslate.new(result1[0][0], 0.0))
					else:
						return []
				elif result2[1] >= transform_params.length():
					output.append(Transform.TransformTranslate.new(result1[0][0], result2[0][0]))
				else:
					return []
			"rotate":
				var result1 := NumstringParser.text_to_number_arr(transform_params, 0, 1)
				if result1.is_empty():
					return []
				var result2 := NumstringParser.text_to_number_arr(transform_params, result1[1], 2, true)
				if result2.is_empty():
					if result1[1] >= transform_params.length():
						output.append(Transform.TransformRotate.new(result1[0][0], 0.0, 0.0))
					else:
						return []
				elif result2[1] >= transform_params.length():
					output.append(Transform.TransformRotate.new(result1[0][0], result2[0][0], result2[0][1]))
				else:
					return []
			"scale":
				var result1 := NumstringParser.text_to_number_arr(transform_params, 0, 1)
				if result1.is_empty():
					return []
				var result2 := NumstringParser.text_to_number_arr(transform_params, result1[1], 1, true)
				if result2.is_empty():
					if result1[1] >= transform_params.length():
						output.append(Transform.TransformScale.new(result1[0][0], result1[0][0]))
					else:
						return []
				elif result2[1] >= transform_params.length():
					output.append(Transform.TransformScale.new(result1[0][0], result2[0][0]))
				else:
					return []
			"skewX":
				var result := NumstringParser.text_to_number_arr(transform_params, 0, 1)
				if result.is_empty() or result[1] < transform_params.length():
					return []
				output.append(Transform.TransformSkewX.new(result[0][0]))
			"skewY":
				var result := NumstringParser.text_to_number_arr(transform_params, 0, 1)
				if result.is_empty() or result[1] < transform_params.length():
					return []
				output.append(Transform.TransformSkewY.new(result[0][0]))
			_:
				return []
	
	return output
