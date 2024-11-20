# A parser for compressed number arrays, used in TransformListParser and PathDataParser.
class_name NumstringParser extends RefCounted

var compress_numbers: bool
var minimize_spacing: bool

static func basic_num_to_text(num: float, is_angle := false) -> String:
	var text := String.num(num, Utils.MAX_ANGLE_PRECISION if is_angle\
			else Utils.MAX_NUMERIC_PRECISION)
	if text == "-0":
		text = "0"
	return text

func num_to_text(num: float, is_angle := false) -> String:
	var text := String.num(num, Utils.MAX_ANGLE_PRECISION if is_angle\
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
		if not expr.has_execute_failed() and typeof(result) == TYPE_FLOAT:
			return result
	err = expr.parse(text.replace(";", "."))
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed() and typeof(result) == TYPE_FLOAT:
			return result
	err = expr.parse(text)
	if err == OK:
		var result: Variant = expr.execute()
		if not expr.has_execute_failed() and typeof(result) == TYPE_FLOAT:
			return result
	return NAN
