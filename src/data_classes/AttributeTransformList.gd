# An attribute representing a list of transformations.
class_name AttributeTransformList extends Attribute

var _transform_list: Array[Transform] = []
var _final_transform := Transform2D.IDENTITY

func _sync() -> void:
	_transform_list = text_to_transform_list(get_value())
	_final_transform = compute_final_transform(_transform_list)

func sync_after_transforms_change() -> void:
	set_value(transform_list_to_text(_transform_list))

func format(text: String) -> String:
	return transform_list_to_text(text_to_transform_list(text))

func set_transform_list(new_transform_list: Array[Transform]) -> void:
	_transform_list = new_transform_list
	_final_transform = compute_final_transform(new_transform_list)
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


func transform_list_to_text(transform_list: Array[Transform]) -> String:
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
				output += "translate(%s) " % num_parser.numstr_arr_to_text([
						num_parser.num_to_text(t.x), num_parser.num_to_text(t.y)])
		elif t is Transform.TransformRotate:
			if t.x == 0 and t.y == 0 and formatter.transform_list_remove_unnecessary_params:
				output += "rotate(%s) " % num_parser.num_to_text(t.deg, true)
			else:
				output += "rotate(%s) " % num_parser.numstr_arr_to_text([
						num_parser.num_to_text(t.deg, true),
						num_parser.num_to_text(t.x), num_parser.num_to_text(t.y)])
		elif t is Transform.TransformScale:
			if t.x == t.y and formatter.transform_list_remove_unnecessary_params:
				output += "scale(%s) " % num_parser.num_to_text(t.x)
			else:
				output += "scale(%s) " % num_parser.numstr_arr_to_text([
						num_parser.num_to_text(t.x), num_parser.num_to_text(t.y)])
		elif t is Transform.TransformSkewX:
			output += "skewX(%s) " % num_parser.num_to_text(t.x, true)
		elif t is Transform.TransformSkewY:
			output += "skewY(%s) " % num_parser.num_to_text(t.y, true)
	return output.trim_suffix(" ")

static func text_to_transform_list(text: String) -> Array[Transform]:
	text = text.strip_edges()
	if text.is_empty():
		return []
	
	var output: Array[Transform] = []
	var transforms := text.split(")", false)
	for transform in transforms:
		var transform_info := transform.split("(")
		if transform_info.size() != 2:
			return []
		
		var transform_params := transform_info[1].strip_edges()
		var nums: Array[float] = []
		
		# Parse the numbers.
		# TODO maybe this can be moved to NumstringParser.
		var comma_exhausted := false  # Can ignore many whitespaces, but only one comma.
		var idx := -1
		while idx < transform_params.length() - 1:
			idx += 1
			@warning_ignore("shadowed_global_identifier")
			var char := transform_params[idx]
			
			if comma_exhausted and not char in " \n\t\r":
				comma_exhausted = false
			
			var start_idx := idx
			var end_idx := idx
			var number_proceed := true
			var passed_decimal_point := false
			var exponent_just_passed := true
			while number_proceed and idx < transform_params.length():
				char = transform_params[idx]
				match char:
					"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
						idx += 1
						end_idx += 1
						if exponent_just_passed:
							exponent_just_passed = false
					"-", "+":
						if end_idx == start_idx or exponent_just_passed:
							end_idx += 1
							idx += 1
							if exponent_just_passed:
								exponent_just_passed = false
						else:
							number_proceed = false
							idx -= 1
					".":
						if not passed_decimal_point:
							passed_decimal_point = true
							end_idx += 1
							idx += 1
						else:
							idx -= 1
							number_proceed = false
					" ", "\n", "\t", "\r":
						if end_idx == start_idx:
							idx += 1
							start_idx += 1
							end_idx += 1
							continue
						if not transform_params.substr(start_idx, idx - start_idx).is_valid_float():
							return []
						number_proceed = false
					",":
						if comma_exhausted:
							return []
						else:
							comma_exhausted = true
							number_proceed = false
					"e":
						if passed_decimal_point:
							return []
						else:
							end_idx += 1
							idx += 1
							exponent_just_passed = true
					_:
						if not transform_params.substr(start_idx,
						end_idx - start_idx).is_valid_float():
							return []
						else:
							idx -= 1
							break
			nums.append(transform_params.substr(start_idx, end_idx - start_idx).to_float())
		
		match transform_info[0].strip_edges():
			"matrix":
				if nums.size() == 6:
					output.append(Transform.TransformMatrix.new(nums[0], nums[1],
							nums[2], nums[3], nums[4], nums[5]))
				else:
					return []
			"translate":
				if nums.size() == 1:
					output.append(Transform.TransformTranslate.new(nums[0], 0.0))
				elif nums.size() == 2:
					output.append(Transform.TransformTranslate.new(nums[0], nums[1]))
				else:
					return []
			"rotate":
				if nums.size() == 1:
					output.append(Transform.TransformRotate.new(nums[0], 0.0, 0.0))
				elif nums.size() == 3:
					output.append(Transform.TransformRotate.new(
							nums[0], nums[1], nums[2]))
				else:
					return []
			"scale":
				if nums.size() == 1:
					output.append(Transform.TransformScale.new(nums[0], nums[0]))
				elif nums.size() == 2:
					output.append(Transform.TransformScale.new(nums[0], nums[1]))
				else:
					return []
			"skewX":
				if nums.size() == 1:
					output.append(Transform.TransformSkewX.new(nums[0]))
				else:
					return []
			"skewY":
				if nums.size() == 1:
					output.append(Transform.TransformSkewY.new(nums[0]))
				else:
					return []
			_:
				return []
	
	return output
