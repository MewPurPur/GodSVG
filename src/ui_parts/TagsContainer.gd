extends VBoxContainer

@export var scroll_container:ScrollContainer
var is_drag_begin:bool = false
const safe_margin:float = 0.18 # 0 - 1

func _process(_delta):
	#does auto scroll with moving draged object
	if  not scroll_container == null and is_drag_begin:
		var working_area:Rect2 = scroll_container.get_global_rect() 
		var shrink_ratio:float = safe_margin * float(working_area.size.y)
		var safe_area:Rect2 = working_area.grow_individual(0,- shrink_ratio,0,- shrink_ratio)
		working_area = working_area.grow_individual(0,shrink_ratio/3,0,shrink_ratio/3)#slightly forgiving
		var mouse_position:Vector2 = get_global_mouse_position()
		if working_area.has_point(mouse_position) and not safe_area.has_point(mouse_position):
			if safe_area.position.y < mouse_position.y:
				scroll_container.scroll_vertical += 5
			else:
				scroll_container.scroll_vertical -= 5

func _can_drop_data(_at_position: Vector2, current_tid: Variant):
	if current_tid is Array:
		drop_location_indicator()
		return true
	return false

func _notification(what:int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		is_drag_begin = true
	elif what == NOTIFICATION_DRAG_END:
		is_drag_begin = false

func _drop_data(at_position: Vector2, current_tid: Variant):
	var new_tid := PackedInt32Array([SVG.root_tag.get_child_count()])
	SVG.root_tag.move_tags_to(current_tid,new_tid)


func drop_location_indicator() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.set_corner_radius_all(4)
	stylebox.set_content_margin_all(5)
	stylebox.bg_color = Color.from_hsv(0.625, 0.5, 0.25)
	stylebox.border_color = Color("yellow")
	stylebox.set_border_width_all(0)
	stylebox.border_width_bottom = 2
	var children:Array[Node] = get_children()
	if  not children.is_empty():
		children[-1].add_theme_stylebox_override(&"panel", stylebox)
	
