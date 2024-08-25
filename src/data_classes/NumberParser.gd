# Common parser for AttributeNumeric and AttributeList
class_name NumberParser extends RefCounted

static func num_to_text(number: float, formatter: Formatter) -> String:
	if not is_finite(number):
		return ""
	
	if number == -0.0:
		number = absf(number)
	
	if formatter.number_use_exponent_if_shorter and not is_zero_approx(number):
		var e := 2
		while is_zero_approx(fposmod(absf(number), 10 ** (e + 1))):
			e += 1
		if e >= 3:
			return String.num_int64(int(number / 10 ** e)) + "e" + String.num_int64(e)
	
	var output := String.num(number, Utils.MAX_NUMERIC_PRECISION)
	if formatter.number_remove_leading_zero and not is_zero_approx(fmod(number, 1)):
		if output.begins_with("0"):
			output = output.right(-1)
		elif output.begins_with("-0"):
			output = output.erase(1)
	
	return output
