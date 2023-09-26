extends SubViewport

@onready var checkerboard: TextureRect = $Checkerboard

func _ready() -> void:
	resize()
	SVG.data.resized.connect(resize)

func resize() -> void:
	checkerboard.size = Vector2(SVG.data.w, SVG.data.h) * 10.0
	checkerboard.position = (size * 1.0 - checkerboard.size) / 2
