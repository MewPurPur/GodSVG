## A parser for [AttributeList].
class_name ListParser extends RefCounted

static func string_to_list(string: String) -> PackedFloat32Array:
	var nums_parsed := PackedFloat32Array()
	var current_num_string: String = ""
	var comma_exhausted := false
	var pos := 0
	while pos < string.length():
		@warning_ignore("shadowed_global_identifier")
		var char := string[pos]
		match char:
			"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "+", ".":
				current_num_string += char
			" ":
				if current_num_string.is_empty():
					pos += 1
					continue
				else:
					nums_parsed.append(current_num_string.to_float())
					current_num_string = ""
			",":
				if comma_exhausted:
					return nums_parsed
				elif current_num_string.is_empty():
					comma_exhausted = true
					pos += 1
					continue
				else:
					nums_parsed.append(current_num_string.to_float())
					current_num_string = ""
		pos += 1
	if not current_num_string.is_empty():
		nums_parsed.append(current_num_string.to_float())
	
	return nums_parsed

static func list_to_string(list: PackedFloat32Array) -> String:
	var params := PackedStringArray()
	for element in list:
		params.append(String.num(element, 4))
	return " ".join(params)
