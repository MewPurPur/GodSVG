extends VBoxContainer

const safe_margin = 0.18

@onready var scroll_container: ScrollContainer = %ScrollContainer

var is_drag_begin := false
var to_refresh_mouse_exit: Control


func _process(_delta: float) -> void:
	# Scroll with moving draged object.
	if scroll_container != null and is_drag_begin:
		var working_area := scroll_container.get_global_rect()
		var shrink_ratio := safe_margin * float(working_area.size.y)
		var safe_area := working_area.grow_individual(0, -shrink_ratio, 0, -shrink_ratio)
		working_area = working_area.grow_individual(0, shrink_ratio/3, 0, shrink_ratio/3)
		var mouse_position := get_global_mouse_position()
		if working_area.has_point(mouse_position) and not safe_area.has_point(mouse_position):
			if safe_area.position.y < mouse_position.y:
				scroll_container.scroll_vertical += 5
			else:
				scroll_container.scroll_vertical -= 5


func _can_drop_data(_at_position: Vector2, current_tid: Variant) -> bool:
	if current_tid is Array[PackedInt32Array]:
		var child := calculate_drop_location()
		if child != null:
			if child.tid in current_tid:
				return false
			child.determine_selection_highlight(child.DropState.DOWN)
			to_refresh_mouse_exit = child
		return true
	return false


func _drop_data(_at_position: Vector2, current_tid: Variant):
	var child := calculate_drop_location()
	var new_tid: PackedInt32Array
	if child:
		new_tid = child.tid.duplicate()
		new_tid[-1] += 1
	else:
		new_tid = PackedInt32Array([SVG.root_tag.get_child_count()])
	SVG.root_tag.move_tags_to(current_tid,new_tid)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		is_drag_begin = true
	elif what == NOTIFICATION_DRAG_END:
		is_drag_begin = false


func calculate_drop_location() -> Control:
	var at_position := get_global_mouse_position()
	var child: Control
	for child_i in get_children():
		if at_position.y > child_i.global_position.y:
			child = child_i
	return child


func _on_mouse_exited() -> void:
	if to_refresh_mouse_exit != null:
		if is_drag_begin:
			var state = to_refresh_mouse_exit.calculate_drop_location(get_global_mouse_position())
			to_refresh_mouse_exit.determine_selection_highlight(state)
		else:
			to_refresh_mouse_exit.determine_selection_highlight()
		to_refresh_mouse_exit = null
