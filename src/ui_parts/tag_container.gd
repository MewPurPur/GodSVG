extends PanelContainer

const safe_margin = 1 / 6.0

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var tags: VBoxContainer = %Tags

var is_drag_begin := false
var to_refresh_mouse_exit: Control


func _process(_delta: float) -> void:
	# Scroll with moving dragged object.
	if scroll_container != null and is_drag_begin:
		var full_area := scroll_container.get_global_rect()
		var no_scroll_area := full_area.grow_individual(
				0, -safe_margin * full_area.size.y, 0, -safe_margin * full_area.size.y)
		var mouse_pos := get_global_mouse_position()
		if full_area.has_point(mouse_pos) and not no_scroll_area.has_point(mouse_pos):
			if no_scroll_area.position.y < mouse_pos.y:
				scroll_container.scroll_vertical += 6
			else:
				scroll_container.scroll_vertical -= 6


func _can_drop_data(_at_position: Vector2, current_tid: Variant) -> bool:
	if current_tid is Array[PackedInt32Array]:
		var child := calculate_drop_location()
		if child != null:
			if child.tid in current_tid:
				return false
			child.drop_state = child.DropState.DOWN
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
	for child_i in tags.get_children():
		if at_position.y > child_i.global_position.y:
			child = child_i
	return child


func _on_mouse_exited() -> void:
	if to_refresh_mouse_exit != null:
		if is_drag_begin:
			var state = to_refresh_mouse_exit.calculate_drop_location(get_global_mouse_position())
			to_refresh_mouse_exit.drop_state = state
		else:
			to_refresh_mouse_exit.drop_state = to_refresh_mouse_exit.DropState.OUTSIDE
			
		to_refresh_mouse_exit = null


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and\
	event.button_index == MOUSE_BUTTON_LEFT and not event.ctrl_pressed:
		Indications.clear_selection()
		Indications.clear_inner_selection()
