extends VBoxContainer


func _can_drop_data(_at_position: Vector2, current_tid: Variant):
	if current_tid is Array:
		return true
	return false


func _drop_data(at_position: Vector2, current_tid: Variant):
	var new_tid := PackedInt32Array([SVG.root_tag.get_child_count()])
	SVG.root_tag.move_tags_to(current_tid,new_tid)
