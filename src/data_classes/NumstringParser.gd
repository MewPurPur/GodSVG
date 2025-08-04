## Parser for numeric text, including the compressed number arrays used in pathdata and transform lists.
## This parser has situational configuration options, so it's not abstract.
class_name NumstringParser

var compress_numbers: bool
var minimize_spacing: bool

## Converts a number into text for the individual fields representing path parameters.
## Those aren't represent anything directly, so they are free to be made readable and not care about formatters.
static func basic_num_to_text(num: float, is_angle := false) -> String:
	var text := Utils.num_simple(num, Utils.MAX_ANGLE_PRECISION if is_angle else Utils.MAX_NUMERIC_PRECISION)
	if text == "-0":
		text = "0"
	return text

## Converts a number into text based on the parser configuration.
func num_to_text(num: float, is_angle := false) -> String:
	var text := Utils.num_simple(num, Utils.MAX_ANGLE_PRECISION if is_angle else Utils.MAX_NUMERIC_PRECISION)
	if compress_numbers:
		if text.begins_with("0."):
			text = text.right(-1)
		elif text.begins_with("-0."):
			text = text.erase(1)
	if text == "-0":
		text = "0"
	return text

## Combines an array of numeric strings based on the parser configuration.
func numstr_arr_to_text(numstr_arr: PackedStringArray) -> String:
	var output := ""
	for i in numstr_arr.size() - 1:
		var current_numstr := numstr_arr[i]
		var next_char := numstr_arr[i + 1][0]
		output += current_numstr
		if not minimize_spacing or not (("." in current_numstr and next_char == ".") or next_char in "-+"):
			output += " "
	return output + numstr_arr[-1]


## Evaluates expressions, so that when the user types "-2.2 + 4" or "sqrt(2)" it can be evaluated by GodSVG.
## Also works when "," is used as a decimal separator.
static func evaluate(text: String) -> float:
	text = text.strip_edges()
	text = text.trim_prefix("+")  # Expression can't handle unary plus.
	
	var expr := Expression.new()
	var err := expr.parse(text.replace(",", "."))
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

## Returns an array with a PackedFloat64Array and an int for the final current index. Returns an empty array if there's a parsing error.
# TODO In 4.5, I had to avoid the match keyword in this parser for performance: #75682.
static func text_to_number_arr(text: String, current_index: int, expected_count: int, allow_starting_comma := false) -> Array:
	var text_length := text.length()
	if current_index >= text_length:
		return []
	
	var state := NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_ALLOWED if allow_starting_comma else NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN
	var current_number_start_idx := -1
	var parsed_numbers := PackedFloat64Array()
	while true:
		var unrecognized_symbol := false
		if current_index == text_length:
			unrecognized_symbol = true
		else:
			var current_char := text[current_index]
			if state == NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN:
				if current_char in " \t\n\r":
					pass
				elif current_char in "1234567890":
					state = NumberJumbleParseState.INSIDE_NUMBER
					current_number_start_idx = current_index
				elif current_char in "-+":
					state = NumberJumbleParseState.DIRECTLY_AFTER_SIGN
					current_number_start_idx = current_index
				elif current_char == ".":
					state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT
					current_number_start_idx = current_index
				else:
					unrecognized_symbol = true
			elif state == NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_ALLOWED:
				if current_char in " \t\n\r":
					pass
				elif current_char == ",":
					state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN
				elif current_char in "1234567890":
					state = NumberJumbleParseState.INSIDE_NUMBER
					current_number_start_idx = current_index
				elif current_char in "-+":
					state = NumberJumbleParseState.DIRECTLY_AFTER_SIGN
					current_number_start_idx = current_index
				elif current_char == ".":
					state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT
					current_number_start_idx = current_index
				else:
					unrecognized_symbol = true
			elif state == NumberJumbleParseState.DIRECTLY_AFTER_SIGN:
				if current_char in "1234567890":
					state = NumberJumbleParseState.INSIDE_NUMBER
				elif current_char == ".":
					state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT
				else:
					unrecognized_symbol = true
			elif state == NumberJumbleParseState.INSIDE_NUMBER:
				if current_char in "1234567890":
					pass
				elif current_char in " \t\n\r":
					parsed_numbers.append(text.substr(current_number_start_idx, current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_ALLOWED
					current_number_start_idx = -1
				elif current_char == ",":
					parsed_numbers.append(text.substr(current_number_start_idx, current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN
					current_number_start_idx = -1
				elif current_char in "-+":
					parsed_numbers.append(text.substr(current_number_start_idx, current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.DIRECTLY_AFTER_SIGN
					current_number_start_idx = current_index
				elif current_char == ".":
					state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_NON_LEADING_FLOATING_POINT
				elif current_char in "eE":
					state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT
				else:
					unrecognized_symbol = true
			elif state == NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_NON_LEADING_FLOATING_POINT:
				if current_char == ".":
					parsed_numbers.append(text.substr(current_number_start_idx, current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT
					current_number_start_idx = current_index
				elif current_char in "-+":
					parsed_numbers.append(text.substr(current_number_start_idx, current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.DIRECTLY_AFTER_SIGN
					current_number_start_idx = current_index
				elif current_char in "1234567890":
					state = NumberJumbleParseState.INSIDE_NUMBER_INDIRECTLY_AFTER_FLOATING_POINT
				elif current_char in " \t\n\r":
					parsed_numbers.append(text.substr(current_number_start_idx, current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_ALLOWED
					current_number_start_idx = -1
				elif current_char == ",":
					parsed_numbers.append(text.substr(current_number_start_idx, current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN
					current_number_start_idx = -1
				elif current_char == "eE":
					state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT
				else:
					unrecognized_symbol = true
			elif state == NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT:
				if current_char in "1234567890":
					state = NumberJumbleParseState.INSIDE_NUMBER_INDIRECTLY_AFTER_FLOATING_POINT
				else:
					unrecognized_symbol = true
			elif state == NumberJumbleParseState.INSIDE_NUMBER_INDIRECTLY_AFTER_FLOATING_POINT:
				if current_char in "1234567890":
					pass
				elif current_char == ".":
					parsed_numbers.append(text.substr(current_number_start_idx, current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT
					current_number_start_idx = current_index
				elif current_char in " \t\n\r":
					parsed_numbers.append(text.substr(current_number_start_idx, current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_ALLOWED
					current_number_start_idx = -1
				elif current_char == ",":
					parsed_numbers.append(text.substr(current_number_start_idx, current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN
					current_number_start_idx = -1
				elif current_char in "-+":
					parsed_numbers.append(text.substr(current_number_start_idx, current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.DIRECTLY_AFTER_SIGN
					current_number_start_idx = current_index
				elif current_char in "eE":
					state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT
				else:
					unrecognized_symbol = true
			elif state == NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT:
				if current_char in "1234567890":
					state = NumberJumbleParseState.INSIDE_NUMBER_INDIRECTLY_AFTER_EXPONENT
				elif current_char in "-+":
					state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT_SIGN
				else:
					unrecognized_symbol = true
			elif state == NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT_SIGN:
				if current_char in "1234567890":
					state = NumberJumbleParseState.INSIDE_NUMBER_INDIRECTLY_AFTER_EXPONENT
				else:
					unrecognized_symbol = true
			elif state == NumberJumbleParseState.INSIDE_NUMBER_INDIRECTLY_AFTER_EXPONENT:
				if current_char in "01234567890":
					pass
				elif current_char == ".":
					parsed_numbers.append(text.substr(current_number_start_idx,
							current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT
					current_number_start_idx = current_index
				elif current_char in " \t\n\r":
					parsed_numbers.append(text.substr(current_number_start_idx,
							current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_ALLOWED
					current_number_start_idx = -1
				elif current_char == ",":
					parsed_numbers.append(text.substr(current_number_start_idx,
							current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.OUTSIDE_NUMBER_COMMA_FORBIDDEN
					current_number_start_idx = -1
				elif current_char in "-+":
					parsed_numbers.append(text.substr(current_number_start_idx,
							current_index - current_number_start_idx).to_float())
					state = NumberJumbleParseState.DIRECTLY_AFTER_SIGN
					current_number_start_idx = current_index
				else:
					unrecognized_symbol = true
		
		if unrecognized_symbol:
			if current_number_start_idx >= 0 and parsed_numbers.size() == expected_count - 1 and\
			not state in [NumberJumbleParseState.DIRECTLY_AFTER_SIGN, NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT,
			NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_LEADING_FLOATING_POINT, NumberJumbleParseState.INSIDE_NUMBER_DIRECTLY_AFTER_EXPONENT_SIGN]:
				parsed_numbers.append(text.substr(current_number_start_idx, current_index - current_number_start_idx).to_float())
				return [parsed_numbers, current_index]
			elif (current_number_start_idx < 0 and parsed_numbers.size() == expected_count):
				return [parsed_numbers, current_index]
			else:
				return []
		
		if parsed_numbers.size() == expected_count:
			return [parsed_numbers, current_index]
		
		current_index += 1
	
	return []
