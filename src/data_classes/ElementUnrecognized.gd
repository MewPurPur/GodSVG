# An element that GodSVG doesn't recognize.
class_name ElementUnrecognized extends Element

var name: String
const possible_conversions: Array[String] = []

func _init(new_name: String) -> void:
	name = new_name
	super()
