class_name TransformListParser extends RefCounted

static func transform_list_to_text(
transform_list: Array[AttributeTransform.Transform]) -> String:
	var output := ""
	var num_parser := NumberArrayParser.new()
	num_parser.compress_numbers = GlobalSettings.transform_compress_numbers
	num_parser.minimize_spacing = GlobalSettings.transform_minimize_spacing
	
	for t in transform_list:
		if t is AttributeTransform.TransformMatrix:
			output += "matrix(%s) " % num_parser.numstr_arr_to_text([
					num_parser.num_to_text(t.x1), num_parser.num_to_text(t.x2),
					num_parser.num_to_text(t.y1), num_parser.num_to_text(t.y2),
					num_parser.num_to_text(t.o1), num_parser.num_to_text(t.o2)])
		elif t is AttributeTransform.TransformTranslate:
			if t.y == 0 and GlobalSettings.transform_remove_unnecessary_params:
				output += "translate(%s) " % num_parser.num_to_text(t.x)
			else:
				output += "translate(%s) " % num_parser.numstr_arr_to_text([
						num_parser.num_to_text(t.x), num_parser.num_to_text(t.y)])
		elif t is AttributeTransform.TransformRotate:
			if t.x == 0 and t.y == 0 and GlobalSettings.transform_remove_unnecessary_params:
				output += "rotate(%s) " % num_parser.num_to_text(t.deg)
			else:
				output += "rotate(%s) " % num_parser.numstr_arr_to_text([
						num_parser.num_to_text(t.deg),
						num_parser.num_to_text(t.x), num_parser.num_to_text(t.y)])
		elif t is AttributeTransform.TransformScale:
			if t.x == t.y and GlobalSettings.transform_remove_unnecessary_params:
				output += "scale(%s) " % num_parser.num_to_text(t.x)
			else:
				output += "scale(%s) " % num_parser.numstr_arr_to_text([
						num_parser.num_to_text(t.x), num_parser.num_to_text(t.y)])
		elif t is AttributeTransform.TransformSkewX:
			output += "skewX(%s) " % num_parser.num_to_text(t.x)
		elif t is AttributeTransform.TransformSkewY:
			output += "skewY(%s) " % num_parser.num_to_text(t.y)
	
	return output.trim_suffix(" ")

static func text_to_transform_list(text: String) -> Array[AttributeTransform.Transform]:
	if text.is_empty():
		return []
	
	var output: Array[AttributeTransform.Transform] = []
	text = text.strip_edges()
	var transforms := text.split(")", false)
	for transform in transforms:
		var transform_info := transform.split("(")
		if transform_info.size() != 2:
			return []
		
		var transform_params := transform_info[1].strip_edges()
		var nums: Array[float] = []
		
		# Parse the numbers.
		# TODO maybe this can be moved to NumberArrayParser.
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
					output.append(AttributeTransform.TransformMatrix.new(nums[0], nums[1],
							nums[2], nums[3], nums[4], nums[5]))
				else:
					return []
			"translate":
				if nums.size() == 1:
					output.append(AttributeTransform.TransformTranslate.new(nums[0], 0.0))
				elif nums.size() == 2:
					output.append(AttributeTransform.TransformTranslate.new(nums[0], nums[1]))
				else:
					return []
			"rotate":
				if nums.size() == 1:
					output.append(AttributeTransform.TransformRotate.new(nums[0], 0.0, 0.0))
				elif nums.size() == 3:
					output.append(AttributeTransform.TransformRotate.new(
							nums[0], nums[1], nums[2]))
				else:
					return []
			"scale":
				if nums.size() == 1:
					output.append(AttributeTransform.TransformScale.new(nums[0], nums[0]))
				elif nums.size() == 2:
					output.append(AttributeTransform.TransformScale.new(nums[0], nums[1]))
				else:
					return []
			"skewX":
				if nums.size() == 1:
					output.append(AttributeTransform.TransformSkewX.new(nums[0]))
				else:
					return []
			"skewY":
				if nums.size() == 1:
					output.append(AttributeTransform.TransformSkewY.new(nums[0]))
				else:
					return []
			_:
				return []
	
	return output
