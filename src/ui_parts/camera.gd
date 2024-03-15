extends Control

var limit_left := 0
var limit_right := 0
var limit_top := 0
var limit_bottom := 0


func _draw() -> void:
	get_viewport().canvas_transform = Transform2D(
		0.0,
		Vector2(Indications.zoom, Indications.zoom),
		0.0,
		-position * Indications.zoom
	)
