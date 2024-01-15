class_name TransformParser extends RefCounted

static func transform_to_text(transform: Transform2D) -> String:
	var output := "matrix(%s, %s, %s, %s, %s, %s)"%[transform[0].x, transform[0].y, transform[1].x, transform[1].y, transform[2].x, transform[2].y]
	return output

static func text_to_transform(text: String) -> Transform2D:
	if text.is_empty():
		return Transform2D.IDENTITY
	var formatted_text := text.strip_edges()
	formatted_text = formatted_text.trim_prefix("matrix(")
	formatted_text = formatted_text.trim_suffix(")")
	
	var output := Transform2D.IDENTITY
	
	var number_array := formatted_text.split_floats(",", false)
	output[0] = Vector2(number_array[0], number_array[1])
	output[1] = Vector2(number_array[2], number_array[3])
	output[2] = Vector2(number_array[4], number_array[5])
	
	return output
