# Common parser for AttributeNumeric and AttributeList
class_name NumberParser extends RefCounted

static func num_to_text(number: float, formatter: Formatter) -> String:
	if not is_finite(number):
		return ""
	
	if formatter.number_use_exponent_if_shorter and absf(number) >= 1000.0:
		var ending_zeros := 0
		while is_zero_approx(fmod(number, 10 ** (ending_zeros + 1))):
			ending_zeros += 1
		if ending_zeros >= 3:
			return String.num_int64(int(number / 10 ** ending_zeros)) + "e" +\
					String.num_uint64(ending_zeros)
	
	var output := String.num(number, Utils.MAX_NUMERIC_PRECISION)
	if formatter.number_remove_leading_zero and not is_zero_approx(fmod(number, 1)):
		if output.begins_with("0"):
			output = output.right(-1)
		elif output.begins_with("-0"):
			output = output.erase(1)
	return output
