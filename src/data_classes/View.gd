class_name View extends RefCounted

signal transform_changed(transform: Transform2D)

var position :=  Vector2.ZERO
var zoom := 1.0
var limit_left := 0
var limit_right := 0
var limit_top := 0
var limit_bottom := 0


func get_transform() -> Transform2D:
	var p := -position * zoom
	var z := Vector2(zoom, zoom)
	var t = Transform2D(0.0, z, 0.0, p)
	return t


func queue_redraw() -> void:
	transform_changed.emit(get_transform())
