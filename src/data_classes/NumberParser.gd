## Parser for AttributeNumeric and individual elements in AttributeList
@abstract class_name NumberParser

## Converts a single number into a string based on a formatter.
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
			return numstr.left(-e) + "e" + String.num_uint64(e)
		else:
			var numstr_abs := numstr.trim_prefix("-")
			# Leading zeros aren't removed yet.
			if numstr_abs.begins_with("0.00") and (not formatter.number_remove_leading_zero or numstr_abs.begins_with("0.000")):
				var is_num_negative := numstr.begins_with("-")
				var e := 3
				while e + 1 < numstr.length() and numstr_abs[e + 1] == "0":
					e += 1
				
				var output := "-" if is_num_negative else ""
				return output + numstr_abs.right(-e - 1) + "e-" + String.num_uint64(e)
	
	if formatter.number_remove_leading_zero and not is_zero_approx(fmod(number, 1)):
		if numstr.begins_with("0"):
			numstr = numstr.right(-1)
		elif numstr.begins_with("-0"):
			numstr = numstr.erase(1)
	
	return numstr
