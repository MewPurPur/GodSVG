# An attribute representing a list of numbers.
class_name AttributeList extends Attribute

var _list: PackedFloat64Array

func _sync() -> void:
	_list = text_to_list(get_value())

func format(text: String, formatter: Formatter) -> String:
	return list_to_text(text_to_list(text), formatter)


func set_list(new_list: PackedFloat64Array) -> void:
	_list = new_list
	_sync_after_list_change()

func _sync_after_list_change() -> void:
	set_value(list_to_text(_list))

func get_list() -> PackedFloat64Array:
	return _list

func get_list_size() -> int:
	return _list.size()


func set_list_element(idx: int, new_value: float) -> void:
	_list[idx] = new_value
	_sync_after_list_change()

func get_list_element(idx: int) -> float:
	return _list[idx] if idx < _list.size() else NAN

func delete_elements(indices: Array[int]) -> void:
	if indices.is_empty():
		return
	
	indices = indices.duplicate()
	indices.sort()
	indices.reverse()
	for idx in indices:
		_list.remove_at(idx)
	_sync_after_list_change()

func insert_element(idx: int, value: float) -> void:
	_list.insert(idx, value)
	_sync_after_list_change()


static func text_to_list(string: String) -> PackedFloat64Array:
	var nums_parsed := PackedFloat64Array()
	var current_num_string := ""
	var comma_exhausted := false
	var pos := 0
	while pos < string.length():
		@warning_ignore("shadowed_global_identifier")
		var char := string[pos]
		match char:
			"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "+", ".", "e", "E":
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

func list_to_text(list: PackedFloat64Array,
formatter := Configs.savedata.editor_formatter) -> String:
	var params := PackedStringArray()
	for element in list:
		# It's fine to use this parser, AttributeList is just a list of numbers.
		params.append(NumberParser.num_to_text(element, formatter))
	return " ".join(params)
