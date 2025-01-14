# Common parser for AttributeNumeric and AttributeList
class_name NumberParser extends RefCounted

static func num_to_text(number: float, formatter: Formatter) -> String:
	if not is_finite(number):
		return ""
	
	if number == -0.0:
		number = absf(number)
	
	var numstr := Utils.num_simple(number, Utils.MAX_NUMERIC_PRECISION)
	
	if formatter.number_use_exponent_if_shorter:
		if numstr.ends_with("000"):
			var e := 3
			while numstr[-e - 1] == "0":
				e += 1
			return String.num_int64(int(number / 10 ** e)) + "e" + String.num_int64(e)
		elif numstr.begins_with("0.00"):
			if not formatter.number_remove_leading_zero or numstr.begins_with("0.000"):
				var e := 2
				var r := 3 if numstr.begins_with("-") else 2
				while e + r < numstr.length() and numstr[e + r] == "0":
					e += 1
				var output := "-" if numstr.begins_with("-") else ""
				return output + String.num_int64(numstr.right(e + r - 1).to_int()) +\
						"e-" + String.num_int64(e + 1)
	
	if formatter.number_remove_leading_zero and not is_zero_approx(fmod(number, 1)):
		if numstr.begins_with("0"):
			numstr = numstr.right(-1)
		elif numstr.begins_with("-0"):
			numstr = numstr.erase(1)
	
	return numstr
