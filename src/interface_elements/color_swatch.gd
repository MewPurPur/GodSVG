extends PanelContainer

@export var color_hex := ""

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	if color_hex == "none":
		color_rect.queue_free()
	color_rect.color = Color.from_string(color_hex, Color(0, 0, 0))
