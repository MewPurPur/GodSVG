## The "stroke-dasharray" attribute.
class_name AttributeDasharray extends Attribute

var _dash_array: PackedFloat64Array

func _sync() -> void:
	_dash_array = text_to_dash_array(get_value())

func format(text: String, formatter: Formatter) -> String:
	return dash_array_to_text(text_to_dash_array(text), formatter)


func set_list(new_list: PackedFloat64Array) -> void:
	_dash_array = new_list
	_sync_after_list_change()

func _sync_after_list_change() -> void:
	set_value(dash_array_to_text(_dash_array))

func get_list() -> PackedFloat64Array:
	return _dash_array

func get_dash_array_size() -> int:
	return _dash_array.size()


func set_dash_array_element(index: int, new_value: float) -> void:
	_dash_array[index] = new_value
	_sync_after_list_change()

func get_dash_array_element(index: int) -> float:
	return _dash_array[index] if index < _dash_array.size() else NAN

func delete_elements(indices: PackedInt64Array) -> void:
	if indices.is_empty():
		return
	
	indices = indices.duplicate()
	indices.sort()
	indices.reverse()
	for i in indices:
		_dash_array.remove_at(i)
	_sync_after_list_change()

func insert_zeros(index: int, zeros_count: int) -> void:
	for i in zeros_count:
		_dash_array.insert(index, 0.0)
	_sync_after_list_change()

func rotate_start(start_index: int) -> void:
	if _dash_array.is_empty() or start_index == 0:
		return
	var size := _dash_array.size()
	start_index = posmod(start_index, size)
	_dash_array = _dash_array.slice(start_index) + _dash_array.slice(0, start_index)
	_sync_after_list_change()


static func text_to_dash_array(string: String) -> PackedFloat64Array:
	var nums_parsed := PackedFloat64Array()
	var current_num_string := ""
	var comma_exhausted := false
	var pos := 0
	while pos < string.length():
		var current_char := string[pos]
		match current_char:
			"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "+", ".", "e", "E":
				current_num_string += current_char
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

func dash_array_to_text(list: PackedFloat64Array, formatter := Configs.savedata.editor_formatter) -> String:
	var params := PackedStringArray()
	for element in list:
		# It's fine to use this parser, AttributeList is just a list of numbers.
		params.append(NumberParser.num_to_text(element, formatter))
	return " ".join(params)
