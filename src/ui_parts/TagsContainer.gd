extends VBoxContainer


func _can_drop_data(_at_position: Vector2, current_tid: Variant):
	if current_tid is Array:
		drop_location_indicator()
		return true
	return false


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
	
