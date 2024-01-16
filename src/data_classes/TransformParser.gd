class_name TransformParser extends RefCounted

static func transform_to_text(transform: Transform2D) -> String:
	var output := "matrix(%s, %s, %s, %s, %s, %s)"%[transform[0].x, transform[0].y, transform[1].x, transform[1].y, transform[2].x, transform[2].y]
	return output

static func text_to_transform(text: String) -> Transform2D:
	var output := Transform2D.IDENTITY
	
	if text.is_empty():
		return output
	
	var formatted_text := text.strip_edges().trim_suffix(")").replace(" ", "")
	var transformations := formatted_text.split(")", false)
	for transformation in transformations:
		var transform_information := transformation.split("(")
		if transform_information.size() != 2:
			return output
		match transform_information[0]:
			"matrix":
				var number_array := transform_information[1].split_floats(",", false)
				if number_array.size() < 6:
					return output
				var matrix_transform := Transform2D.IDENTITY
				matrix_transform[0] = Vector2(number_array[0], number_array[1])
				matrix_transform[1] = Vector2(number_array[2], number_array[3])
				matrix_transform[2] = Vector2(number_array[4], number_array[5])
				output = matrix_transform * output
			"translate":
				var number_array := transform_information[1].split_floats(",", false)
				if number_array.size() == 1:
					output = output.translated(Vector2(number_array[0], 0.0))
				elif number_array.size() == 2:
					output = output.translated(Vector2(number_array[0], number_array[1]))
				else:
					return output
			"scale":
				var number_array := transform_information[1].split_floats(",", false)
				if number_array.size() == 1:
					output = output.scaled(Vector2(number_array[0], number_array[0]))
				elif number_array.size() == 2:
					output = output.scaled(Vector2(number_array[0], number_array[1]))
				else:
					return output
			"rotate":
				var number_array := transform_information[1].split_floats(",", false)
				if number_array.size() == 1:
					output = output.rotated(deg_to_rad(number_array[0]))
				elif number_array.size() == 3:
					var point := Vector2(number_array[1], number_array[2])
					var rotation := Transform2D.IDENTITY
					rotation = rotation.translated(-point)
					rotation = rotation.rotated(deg_to_rad(number_array[0]))
					rotation = rotation.translated(point)
					output = rotation * output
				else:
					return output
			"skewX":
				var number_array := transform_information[1].split_floats(",", false)
				if number_array.size() == 1:
					var skew := Transform2D.IDENTITY
					skew[1].x = tan(deg_to_rad(number_array[0]));
					output = skew * output
				else:
					return output
			"skewY":
				var number_array := transform_information[1].split_floats(",", false)
				if number_array.size() == 1:
					var skew := Transform2D.IDENTITY
					skew[0].y = tan(deg_to_rad(number_array[0]));
					output = skew * output
				else:
					return output
	
	return output
