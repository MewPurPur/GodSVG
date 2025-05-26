# Run with Ctrl+Shift+X.
# A script intended to test sensitive parts of the codebase.
# This isn't an invitation to add random tests, please discuss before doing so.
@tool
extends EditorScript

func _run() -> void:
	pathdata_tests()
	transform_list_tests()


func pathdata_tests() -> void:
	const tests: Dictionary[String, Array] = {
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
	"M4 1 2 - 4 4z": [["M", 4.0, 1.0]],
	"M1 6.9e-1": [["M", 1.0, 0.69]],
	}
	
	for test in tests:
		var result := AttributePathdata.pathdata_to_arrays(test)
		var expected: Array = tests[test]
		if result != expected:
			print('"' + test + '" generated ' + str(result) + ', expected ' + str(expected))

func transform_list_tests() -> void:
	var tests: Dictionary[String, Array] = {
	"Jerky": [],
	"matrix(1, 0, 0, 5, 0, 3)": [Transform.TransformMatrix.new(1, 0, 0, 5, 0, 3)],
	"matrix(1 0 0 5 0 3)": [Transform.TransformMatrix.new(1, 0, 0, 5, 0, 3)],
	}
	
	for test in tests:
		var test_passed := true
		var result := AttributeTransformList.text_to_transform_list(test)
		var expected := tests[test]
		if expected.size() != result.size():
			test_passed = false
		else:
			for i in expected.size():
				if expected[i] is Transform.TransformMatrix and\
				(not result[i] is Transform.TransformMatrix or\
				expected[i].x1 != result[i].x1 or expected[i].x2 != result[i].x2 or\
				expected[i].y1 != result[i].y1 or expected[i].y2 != result[i].y2 or\
				expected[i].o1 != result[i].o1 or expected[i].o2 != result[i].o2):
					test_passed = false
					break
		
		if not test_passed:
			print('"' + test + '" generated ' + str(result))
