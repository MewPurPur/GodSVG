class_name NumberParser extends RefCounted

static func num_to_text(number: float) -> String:
	var output := String.num(number, GlobalSettings.general_number_precision)
	if GlobalSettings.number_remove_leading_zero and "." in output:
		if output.begins_with("0"):
			output = output.right(-1)
		elif output.begins_with("-0") or output.begins_with("+0"):
			output = output.erase(1)
	return output

static func text_to_num(text: String) -> float:
	return NAN if text.is_empty() else text.to_float()

# The passed text should already be a valid number.
static func format_text(text: String) -> String:
	if text.is_empty():
		return ""  # Equivalent to NAN in the app's logic.
	
	var leading_decimal_point := text.begins_with(".") or text.begins_with("-.") or\
		text.begins_with("+.")
	var padded_zeros := 0
	if "." in text and not GlobalSettings.number_remove_zero_padding:
		while text.ends_with("0"):
			text = text.left(-1)
			padded_zeros += 1
	
	text = String.num(text.to_float(), GlobalSettings.general_number_precision)
	if text == "-0":
		text = "0"
	
	if leading_decimal_point or\
	(GlobalSettings.number_remove_leading_zero and "." in text):
		if text.begins_with("0"):
			text = text.right(-1)
		if text.begins_with("-0") or text.begins_with("+0"):
			text = text.erase(1)
	
	if padded_zeros > 0:
		if not "." in text:
			text += "."
		text += "0".repeat(padded_zeros)
	text = text.left(text.find(".") + 5)
	
	return text

# This function evaluates expressions even if "," or ";" is used as a decimal separator.
static func evaluate(text: String) -> float:
	text = text.trim_prefix("+")  # Expression can't handle unary plus.
	var expr := Expression.new()
	var err := expr.parse(text.replace(",", "."))
	if err == OK:
		var result: String = var_to_str(expr.execute())
		if not expr.has_execute_failed() and result.is_valid_float():
			return str_to_var(result)
	err = expr.parse(text.replace(";", "."))
	if err == OK:
		var result: String = var_to_str(expr.execute())
		if not expr.has_execute_failed() and result.is_valid_float():
			return str_to_var(result)
	err = expr.parse(text)
	if err == OK:
		var result: String = var_to_str(expr.execute())
		if not expr.has_execute_failed() and result.is_valid_float():
			return str_to_var(result)
	return NAN
