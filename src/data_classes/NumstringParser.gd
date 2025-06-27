# A parser for compressed number arrays, used in pathdata and transform lists.
# Also for general utility around parsing numeric text.
# This parser has situational configuration options, so it isn't abstract.
class_name NumstringParser

var compress_numbers: bool
var minimize_spacing: bool

static func basic_num_to_text(num: float, is_angle := false) -> String:
	var text := Utils.num_simple(num, Utils.MAX_ANGLE_PRECISION if is_angle\
			else Utils.MAX_NUMERIC_PRECISION)
	if text == "-0":
		text = "0"
	return text

func num_to_text(num: float, is_angle := false) -> String:
	var text := Utils.num_simple(num, Utils.MAX_ANGLE_PRECISION if is_angle\
			else Utils.MAX_NUMERIC_PRECISION)
	if compress_numbers:
		if text.begins_with("0."):
			text = text.right(-1)
		elif text.begins_with("-0."):
			text = text.erase(1)
	if text == "-0":
		text = "0"
	return text

func numstr_arr_to_text(numstr_arr: PackedStringArray) -> String:
	var output := ""
	for i in numstr_arr.size() - 1:
		var current_numstr := numstr_arr[i]
		var next_char := numstr_arr[i + 1][0]
		output += current_numstr
		if not minimize_spacing or not (("." in current_numstr and next_char == ".") or\
		next_char in "-+"):
			output += " "
	return output + numstr_arr[-1]


# This function evaluates expressions even if "," or ";" is used as a decimal separator.
static func evaluate(text: String) -> float:
	text = text.strip_edges()
	text = text.trim_prefix("+")  # Expression can't handle unary plus.
	
	var expr := Expression.new()
	var err := expr.parse(text.replace(",", "."))
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed() and typeof(result) in [TYPE_FLOAT, TYPE_INT]:
			return result
	err = expr.parse(text.replace(";", "."))
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed() and typeof(result) in [TYPE_FLOAT, TYPE_INT]:
			return result
	err = expr.parse(text)
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed() and typeof(result) in [TYPE_FLOAT, TYPE_INT]:
			return result
	return NAN


enum NumberJumbleParseState {
	OUTSIDE_NUMBER_COMMA_FORBIDDEN,
	OUTSIDE_NUMBER_COMMA_ALLOWED,
	DIRECTLY_AFTER_SIGN,
	INSIDE_NUMBER,
	INSIDE_NUMBER_DIRECTLY_AFTER_NON_LEADING_FLOATING_POINT,
	INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT,
	INSIDE_NUMBER_INDIRECTLY_AFTER_FLOATING_POINT,
	INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT,
	INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT_SIGN,
	INSIDE_NUMBER_INDIRECTLY_AFTER_EXPONENT
}

# Returns an array with a PackedFloat64Array and an int for the final current index.
# Returns an empty array if there's a parsing error.
static func text_to_number_arr(text: String, current_index: int, expected_count: int,
allow_starting_comma := false) -> Array:
	var text_length := text.length()
	if current_index >= text.length():
		return []
	
	var state := NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_ALLOWED if \
			allow_starting_comma else NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN
	var current_number_start_idx := -1
	var parsed_numbers := PackedFloat64Array()
	while true:
		var unrecognized_symbol := false
		if current_index == text_length:
			unrecognized_symbol = true
		else:
			var current_char := text[current_index]
			match state:
				NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN:
					match current_char:
						" ", "\t", "\n", "\r":
							pass
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
							state = NumberJumbleParseState.INSIDE_NUMBER
							current_number_start_idx = current_index
						"+", "-":
							state = NumberJumbleParseState.DIRECTLY_AFTER_SIGN
							current_number_start_idx = current_index
						".":
							state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT
							current_number_start_idx = current_index
						_:
							unrecognized_symbol = true
				NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_ALLOWED:
					match current_char:
						" ", "\t", "\n", "\r":
							pass
						",":
							state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
							state = NumberJumbleParseState.INSIDE_NUMBER
							current_number_start_idx = current_index
						"+", "-":
							state = NumberJumbleParseState.DIRECTLY_AFTER_SIGN
							current_number_start_idx = current_index
						".":
							state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT
							current_number_start_idx = current_index
						_:
							unrecognized_symbol = true
				NumberJumbleParseState.DIRECTLY_AFTER_SIGN:
					match current_char:
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
							state = NumberJumbleParseState.INSIDE_NUMBER
						".":
							state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT
						_:
							unrecognized_symbol = true
				NumberJumbleParseState.INSIDE_NUMBER:
					match current_char:
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
							pass
						" ", "\t", "\n", "\r":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_ALLOWED
							current_number_start_idx = -1
						",":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN
							current_number_start_idx = -1
						"-", "+":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.DIRECTLY_AFTER_SIGN
							current_number_start_idx = current_index
						".":
							state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_NON_LEADING_FLOATING_POINT
						"e", "E":
							state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT
						_:
							unrecognized_symbol = true
				NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_NON_LEADING_FLOATING_POINT:
					match current_char:
						".":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT
							current_number_start_idx = current_index
						"-", "+":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.DIRECTLY_AFTER_SIGN
							current_number_start_idx = current_index
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
							state = NumberJumbleParseState.INSIDE_NUMBER_INDIRECTLY_AFTER_FLOATING_POINT
						" ", "\t", "\n", "\r":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_ALLOWED
							current_number_start_idx = -1
						",":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN
							current_number_start_idx = -1
						"e", "E":
							state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT
						_:
							unrecognized_symbol = true
				NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT:
					match current_char:
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
							state = NumberJumbleParseState.INSIDE_NUMBER_INDIRECTLY_AFTER_FLOATING_POINT
						_:
							unrecognized_symbol = true
				NumberJumbleParseState.INSIDE_NUMBER_INDIRECTLY_AFTER_FLOATING_POINT:
					match current_char:
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
							pass
						".":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT
							current_number_start_idx = current_index
						" ", "\t", "\n", "\r":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_ALLOWED
							current_number_start_idx = -1
						",":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN
							current_number_start_idx = -1
						"-", "+":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.DIRECTLY_AFTER_SIGN
							current_number_start_idx = current_index
						"e", "E":
							state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT
						_:
							unrecognized_symbol = true
				NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT:
					match current_char:
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
							state = NumberJumbleParseState.INSIDE_NUMBER_INDIRECTLY_AFTER_EXPONENT
						"-", "+":
							state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT_SIGN
						_:
							unrecognized_symbol = true
				NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT_SIGN:
					match current_char:
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
							state = NumberJumbleParseState.INSIDE_NUMBER_INDIRECTLY_AFTER_EXPONENT
						_:
							unrecognized_symbol = true
				NumberJumbleParseState.INSIDE_NUMBER_INDIRECTLY_AFTER_EXPONENT:
					match current_char:
						"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
							pass
						".":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT
							current_number_start_idx = current_index
						" ", "\t", "\n", "\r":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_ALLOWED
							current_number_start_idx = -1
						",":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN
							current_number_start_idx = -1
						"-", "+":
							parsed_numbers.append(text.substr(current_number_start_idx,
									current_index - current_number_start_idx).to_float())
							state = NumberJumbleParseState.DIRECTLY_AFTER_SIGN
							current_number_start_idx = current_index
						_:
							unrecognized_symbol = true
		
		if unrecognized_symbol:
			if current_number_start_idx >= 0 and parsed_numbers.size() == expected_count - 1 and\
			state != NumberJumbleParseState.DIRECTLY_AFTER_SIGN and\
			state != NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT and\
			state != NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT and\
			state != NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT_SIGN:
				parsed_numbers.append(text.substr(current_number_start_idx,
						current_index - current_number_start_idx).to_float())
				return [parsed_numbers, current_index]
			elif (current_number_start_idx < 0 and parsed_numbers.size() == expected_count):
				return [parsed_numbers, current_index]
			else:
				return []
		
		if parsed_numbers.size() == expected_count:
			return [parsed_numbers, current_index]
		
		current_index += 1
	
	return []
