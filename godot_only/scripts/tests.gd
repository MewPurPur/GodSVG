# Run with Ctrl+Shift+X.
# A script intended to test sensitive parts of the codebase.
# This isn't an invitation to add tests to random methods.
# Please discuss before adding more tests here.
@tool
extends EditorScript

func _run() -> void:
	var pathdata_test_passed := pathdata_tests()
	if pathdata_test_passed:
		print("All tests passed!")


func pathdata_tests(print_success := false) -> bool:
	var tests := {
	"Jerky": [],
	"M 3s 6 h 6 v 3 z": [],
	"M 3 s6 h 6 v 3 z": [],
	"M 3 .s6 h 6 v 3 z": [],
	" 0 2": [],
	"M 0 0": [["M", 0.0, 0.0]],
	"M2 1 L3 4": [["M", 2.0, 1.0], ["L", 3.0, 4.0]],
	"m2 0 3 4": [["m", 2.0, 0.0], ["l", 3.0, 4.0]],
	"m-2.3.7-4,4": [["m", -2.3, 0.7], ["l", -4.0, 4.0]],
	"m2 3a7 3 0 101.2.3": [["m", 2.0, 3.0], ["a", 7.0, 3.0, 0.0, 1, 0, 1.2, 0.3]],
	"M 2 0  c3 2-.6.8 11.0 3Jh3": [["M", 2.0, 0.0], ["c", 3.0, 2.0, -0.6, 0.8, 11.0, 3.0]],
	"z": [["z"]],
	"M 0 0 z 2 3": [["M", 0.0, 0.0], ["z"]],
	"M3e1 4e-2": [["M", 3e1, 4e-2]],
	"M5,1 A4,4,0,1,1,5,9": [["M", 5.0, 1.0], ["A", 4.0, 4.0, 0.0, 1, 1, 5.0, 9.0]],
	}
	
	var tests_passed := true
	for test in tests.keys():
		var result := PathdataParser.pathdata_to_arrays(test)
		var expected: Array = tests[test]
		if result != expected:
			tests_passed = false
			print('"' + test + '" generated ' + str(result) + ', expected ' + str(expected))
		elif print_success:
			print('"' + test + '" generated ' + str(result) + ' (SUCCESS)')
	return tests_passed
