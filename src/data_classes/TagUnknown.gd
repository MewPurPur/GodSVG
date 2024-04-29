# A tag that GodSVG doesn't recognize.
class_name TagUnknown extends Tag

var name: String
const possible_conversions = []
const known_shape_attributes = []
const known_inheritable_attributes = []
const icon = preload("res://visual/icons/tag/unknown.svg")

func _init(new_name: String) -> void:
	name = new_name
