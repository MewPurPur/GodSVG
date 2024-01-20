class_name TransformParser extends RefCounted

static func num_to_text(num: float, precision := 4) -> String:
	var text := String.num(num, precision)
	if GlobalSettings.transform_compress_numbers:
		if text.begins_with("0."):
			text = text.right(-1)
		elif text.begins_with("-0."):
			text = text.erase(1)
	return text

static func num_arr_to_text(num_arr: Array[float]) -> String:
	var numstr_arr: Array[String] = []
	for i in num_arr.size():
		numstr_arr.append(num_to_text(num_arr[i]))
	var output := ""
	for i in numstr_arr.size() - 1:
		var current_numstr := numstr_arr[i]
		var next_char := numstr_arr[i + 1][0]
		output += current_numstr
		if not GlobalSettings.transform_minimize_spacing or not\
		(("." in current_numstr and next_char == ".") or next_char in "-+"):
			output += " "
	return output + numstr_arr.back()

# TODO needs a lot more work.
static func transform_to_text(transform: Transform2D) -> String:
	return "matrix(" + num_arr_to_text([transform[0].x, transform[0].y,
			transform[1].x, transform[1].y, transform[2].x, transform[2].y]) + ")"

static func text_to_transform(text: String) -> Transform2D:
	if text.is_empty():
		return Transform2D.IDENTITY
	
	var output := Transform2D.IDENTITY
	text = text.strip_edges()
	var transforms := text.split(")", false)
	for transform in transforms:
		var transform_info := transform.split("(")
		if transform_info.size() != 2:
			return Transform2D.IDENTITY
		
		var transform_params := transform_info[1].strip_edges()
		var nums: Array[float] = []
		
		# Parse the numbers.
		# TODO maybe we can do something about this being shared with PathDataParser.
		var comma_exhausted := false
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
							return Transform2D.IDENTITY
						else:
							comma_exhausted = true
							number_proceed = false
					"e":
						if passed_decimal_point:
							return Transform2D.IDENTITY
						else:
							end_idx += 1
							idx += 1
							exponent_just_passed = true
					_:
						if not transform_params.substr(start_idx,
						end_idx - start_idx).is_valid_float():
							return Transform2D.IDENTITY
						else:
							idx -= 1
							break
			nums.append(transform_params.substr(start_idx, end_idx - start_idx).to_float())
		
		match transform_info[0].strip_edges():
			"matrix":
				if nums.size() == 6:
					output = Transform2D(Vector2(nums[0], nums[1]), Vector2(nums[2], nums[3]),
							Vector2(nums[4], nums[5])) * output
				else:
					return Transform2D.IDENTITY
			"translate":
				if nums.size() == 1:
					output = output.translated(Vector2(nums[0], 0.0))
				elif nums.size() == 2:
					output = output.translated(Vector2(nums[0], nums[1]))
				else:
					return Transform2D.IDENTITY
			"scale":
				if nums.size() == 1:
					output = output.scaled(Vector2(nums[0], nums[0]))
				elif nums.size() == 2:
					output = output.scaled(Vector2(nums[0], nums[1]))
				else:
					return Transform2D.IDENTITY
			"rotate":
				if nums.size() == 1:
					output = output.rotated(deg_to_rad(nums[0]))
				elif nums.size() == 3:
					var point := Vector2(nums[1], nums[2])
					var rotation := Transform2D.IDENTITY
					rotation = rotation.translated(-point)
					rotation = rotation.rotated(deg_to_rad(nums[0]))
					rotation = rotation.translated(point)
					output = rotation * output
				else:
					return Transform2D.IDENTITY
			"skewX":
				if nums.size() == 1:
					var skew := Transform2D.IDENTITY
					skew[1].x = tan(deg_to_rad(transform_params.to_float()))
					output = skew * output
				else:
					return Transform2D.IDENTITY
			"skewY":
				if nums.size() == 1:
					var skew := Transform2D.IDENTITY
					skew[0].y = tan(deg_to_rad(transform_params.to_float()))
					output = skew * output
				else:
					return Transform2D.IDENTITY
			_:
				return Transform2D.IDENTITY
	
	return output
