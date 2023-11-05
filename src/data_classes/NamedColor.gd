class_name NamedColor extends Resource

@export var name: String  # Names don't need to be unique.
@export var color: String

func _init(new_color := "", new_name := "") -> void:
	color = new_color
	name = new_name
