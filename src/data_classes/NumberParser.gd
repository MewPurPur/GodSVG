class_name NumberParser extends RefCounted

static func num_to_text(number: float) -> String:
	var output := String.num(number, 4)
	if GlobalSettings.number_remove_leading_zero and output.find(".") != -1:
		if output.begins_with("0"):
			output = output.right(-1)
		elif output.begins_with("-0") or output.begins_with("+0"):
			output = output.erase(1)
	
	return output

static func text_to_num(text: String) -> float:
	return NAN if text.is_empty() else text.to_float()

# The passed text should already be a valid number.
static func format_text(text: String) -> String:
	if GlobalSettings.number_remove_plus_sign:
		if text.begins_with("+"):
			text = text.right(-1)
	
	var decimal_point_pos := text.find(".")
	if decimal_point_pos != -1 and text.length() > decimal_point_pos + 5:
		var round_up := text[decimal_point_pos + 5] in ["5", "6", "7", "8", "9"]
		text = text.left(decimal_point_pos + 5)
		if round_up:
			while true:
				var last_char := text[text.length() - 1]
				if last_char == "9":
					text = text.left(-1)
				elif last_char == ".":
					text = text.left(-1)
					text[text.length() - 1] = String.num_uint64(
							text[text.length() - 1].to_int() + 1)
					break
				else:
					text[text.length() - 1] = String.num_uint64(last_char.to_int() + 1)
					break
	
	if GlobalSettings.number_remove_leading_zero:
		decimal_point_pos = text.find(".")
		if decimal_point_pos != -1:
			while text.begins_with("0"):
				text = text.right(-1)
			while text.begins_with("-0") or text.begins_with("+0"):
				text = text.erase(1)
	
	if GlobalSettings.number_remove_zero_padding:
		decimal_point_pos = text.find(".")
		if decimal_point_pos != -1:
			while text[text.length() - 1] in ["0", "."]:
				text = text.left(-1)
	
	return text
