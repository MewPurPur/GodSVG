# A <stop/> tag.
class_name TagStop extends Tag

const name = "stop"
const possible_conversions = []
const known_attributes = ["offset", "stop-color", "stop-opacity"]
const icon = preload("res://visual/icons/tag/stop.svg")

func _init() -> void:
	for attrib_name in ["offset", "stop-color", "stop-opacity"]:
		attributes[attrib_name] = DB.attribute(attrib_name)
	super()
