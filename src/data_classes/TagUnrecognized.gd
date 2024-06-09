# A tag that GodSVG doesn't recognize.
class_name TagUnrecognized extends Tag

var name: String
const possible_conversions = []

func _init(new_name: String) -> void:
	name = new_name
