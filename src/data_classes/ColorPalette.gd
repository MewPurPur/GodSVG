class_name ColorPalette extends Resource

@export var name: String  # Color palettes must be uniquely named.
@export var named_colors: Array[NamedColor]  # Array because consistent order is helpful.

func _init(new_name := "", new_colors: Array[NamedColor] = []) -> void:
	name = new_name
	named_colors = new_colors
