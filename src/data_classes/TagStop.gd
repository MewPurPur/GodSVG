class_name TagStop extends Tag
## A <stop/> tag.

const name = "stop"
const possible_conversions = []
const known_attributes = ["offset", "stop-color", "stop-opacity"]
const icon = preload("res://visual/icons/tag/stop.svg")

func _init() -> void:
	attributes = {
		"offset": AttributeNumeric.new(0.0, 1.0, "0"),
		"stop-color": AttributeColor.new("black"),
		"stop-opacity": AttributeNumeric.new(0.0, 1.0, "1"),
	}
	super()
