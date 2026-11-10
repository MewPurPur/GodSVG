## Parser for numeric arrays with configuration options.
class_name ParserNumstring

var compress_numbers: bool
var minimize_spacing: bool

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
