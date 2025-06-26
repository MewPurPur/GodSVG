# Run with Ctrl+Shift+X.
# A script intended to test sensitive parts of the codebase.
# This isn't an invitation to add random tests, please discuss before doing so.
@tool
extends EditorScript

var report := PackedStringArray()

func _run() -> void:
	pathdata_tests()
	transform_list_tests()
	if report.is_empty():
		print_rich("[rainbow sat=0.4 val=1.0]Success[/rainbow]")
	else:
		for report_line in report:
			print_rich(report_line)

func add_to_report(test_category: String, test: String, result: String,
expected: String) -> void:
	report.append('%s: [b]"%s"[/b] returned [b]"%s"[/b], expected [b]"%s"[/b]' %\
			[test_category, test, result, expected])

# This test is dependent on specifics of the Formatter and AttributePathdata classes.
# But its logic would likely not change enough in the future to make the tests obsolete.
# https://www.w3.org/TR/SVG11/paths.html#PathDataBNF
# We have a difference in logic where we don't require starting with MoveTo
# in order to make pathdata easier to edit.
# ClosePath are also merged, so you don't end up with invalid syntax after commands are deleted.
func pathdata_tests() -> void:
	var spacious_formatter := Formatter.new()
	spacious_formatter.pathdata_compress_numbers = false
	spacious_formatter.pathdata_minimize_spacing = false
	spacious_formatter.pathdata_remove_consecutive_commands = false
	spacious_formatter.pathdata_remove_spacing_after_flags = false
	const tests: Dictionary[String, String] = {
		"": "",
		" \n\r\t": "",
		"Jerky": "",
		"M 3s 6 h 6 v 3 z": "",
		"M 3 s6 h 6 v 3 z": "",
		"M 3 .s6 h 6 v 3 z": "",
		" 0 2": "",
		"M , 1 2": "",
		"M1 2": "M 1 2",
		"M 1 2,": "M 1 2",
		"M 1 2, h 3": "M 1 2 h 3",
		"M2..5": "M 2 0.5",
		"q 1, 2  ,3 , 4 l 5 ,, 6": "q 1 2 3 4",
		"M2 1 L3 4": "M 2 1 L 3 4",
		"m2 0 3 4": "m 2 0 l 3 4",
		"m-2.3.7-4,4": "m -2.3 0.7 l -4 4",
		"a7 3 0 101.2.3": "a 7 3 0 1 0 1.2 0.3",
		"A10 10 0 2 0 100 100": "",
		"a5,5,45,-10,50,50": "",
		"A4 4 0 1 0. 9 7": "",
		"A4 4 0 1 0.9 7": "A 4 4 0 1 0 0.9 7",
		"A 10 0 2 0 100 7": "A 10 0 2 0 1 0 7",
		"M 2 0  c3 2-.6.8 11.0 3Jh3": "M 2 0 c 3 2 -0.6 0.8 11 3",
		"z": "z",
		"M 0 0 z 2 3": "M 0 0 z",
		"M3e1 4e-2 h2e+2": "M 30 0.04 h 200",
		"M2. 3.": "M 2 3",
		"M5,1 A4,4,0,1,1,5,9": "M 5 1 A 4 4 0 1 1 5 9",
		"M4 1 2 - 4 4z": "M 4 1",
		"M1 6.9E-1": "M 1 0.69",
		" \tM\t1\t,\t2": "M 1 2",
		"M 1 2 zZzz M 3 4": "M 1 2 z M 3 4",
	}
	
	for test in tests:
		var result := AttributePathdata.new("d")._format(test, spacious_formatter)
		if result != tests[test]:
			add_to_report("Pathdata parser", test, result, tests[test])

# This test is dependent on specifics of the Formatter and AttributeTransformList classes.
# But its logic would likely not change enough in the future to make the tests obsolete.
# https://www.w3.org/TR/SVG11/coords.html#TransformAttribute
func transform_list_tests() -> void:
	var spacious_formatter := Formatter.new()
	spacious_formatter.transform_list_compress_numbers = false
	spacious_formatter.transform_list_minimize_spacing = false
	spacious_formatter.transform_list_remove_unnecessary_params = false
	var tests: Dictionary[String, String] = {
		"": "",
		" \n\r\t": "",
		"Jerky": "",
		"matrix(1 0 0 5 0 3)": "matrix(1 0 0 5 0 3)",
		"matrix(1, 0, 0 , 5, 0, 3)": "matrix(1 0 0 5 0 3)",
		"\tmatrix (1. 0. 0. .5 0. 3.  )": "matrix(1 0 0 0.5 0 3)",
		"translate(10.) scale(.5) rotate(7)": "translate(10 0) scale(0.5 0.5) rotate(7 0 0)",
		"skewX(3) , skewY(4)": "skewX(3) skewY(4)",
		"skewX(3) , skewY(4 2)": "",
		"skewX(3) ,, skewY(4)": "",
		"scale(2,)": "",
		"translate(,10)": "",
		"matrix(1e2,0,0,1e-2,1.2E+1.4e1)": "matrix(100 0 0 0.01 12 14)",
		"matrix(1 0 0 1)": "",
		"matrix(1.2 0 0 1 0 0 0)": "",
	}
	
	for test in tests:
		var result := AttributeTransformList.new("transform")._format(test, spacious_formatter)
		if result != tests[test]:
			add_to_report("Transform list parser", test, result, tests[test])
