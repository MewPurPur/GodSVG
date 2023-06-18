extends Button

@export var command_char := ""

func _ready() -> void:
	text = command_char
