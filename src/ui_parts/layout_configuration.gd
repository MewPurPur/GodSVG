extends Control

# This is the configuration area of the layout popup, which is just one node doing a lot of things.
# This helps with drag & drop which can be defined only here. Buttons are used too, but just for graphics.

class DragData:
	var layout_part: Utils.LayoutPart
	var layout_location: SaveData.LayoutLocation
	var idx: int
	
	func _init(new_layout_part: Utils.LayoutPart,
	new_layout_location: SaveData.LayoutLocation, new_idx: int) -> void:
		layout_part = new_layout_part
		layout_location = new_layout_location
		idx = new_idx

const PART_UI_SIZE = 30
const BUFFER_SIZE = 2

var ci := get_canvas_item()

# This is for the big rectangles.
var section_areas: Dictionary[SaveData.LayoutLocation, Rect2]

# This is for the small drag-and-drop squares.
var layout_part_areas: Dictionary[Utils.LayoutPart, Rect2]

var hovered_part := Utils.LayoutPart.NONE:
	set(new_value):
		if hovered_part != new_value:
			hovered_part = new_value
			mouse_default_cursor_shape = CURSOR_ARROW if hovered_part == Utils.LayoutPart.NONE else CURSOR_POINTING_HAND
			queue_redraw()

var proposed_drop_location_pivot := SaveData.LayoutLocation.NONE:
	set(new_value):
		if proposed_drop_location_pivot != new_value:
			proposed_drop_location_pivot = new_value
			queue_redraw()

enum DropDirection {NONE, BELOW, ABOVE, INSIDE}

var proposed_drop_location_direction := DropDirection.NONE:
	set(new_value):
		if proposed_drop_location_direction != new_value:
			proposed_drop_location_direction = new_value
			queue_redraw()

var proposed_drop_idx := -1:
	set(new_value):
		if proposed_drop_idx != new_value:
			proposed_drop_idx = new_value
			queue_redraw()

var dragged_data: DragData:
	set(new_value):
		if dragged_data != new_value:
			dragged_data = new_value
			if is_instance_valid(dragged_data):
				hovered_part = Utils.LayoutPart.NONE
			queue_redraw()


func _ready() -> void:
	get_window().mouse_exited.connect(_on_window_mouse_exited)
	update_areas()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not is_instance_valid(dragged_data):
			for layout_part in layout_part_areas:
				if layout_part_areas[layout_part].grow(-BUFFER_SIZE).has_point(event.position):
					hovered_part = layout_part
					return
			hovered_part = Utils.LayoutPart.NONE

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		dragged_data = null
		clear_proposed_drop()

func _on_window_mouse_exited() -> void:
	hovered_part = Utils.LayoutPart.NONE


# Drawing

func _draw() -> void:
	var half_width := size.x / 2.0
	var right_rect := Rect2(half_width, 18, half_width, half_width * 1.25)
	
	# Fixed viewport location for now.
	
	get_theme_stylebox("disabled", "TranslucentButton").draw(ci, right_rect.grow(-BUFFER_SIZE))
	var viewport_icon := Utils.get_layout_part_icon(Utils.LayoutPart.VIEWPORT)
	viewport_icon.draw(ci, (right_rect.get_center() - viewport_icon.get_size() / 2).round(), ThemeUtils.tinted_contrast_color)
	
	for layout_location in section_areas:
		var area := section_areas[layout_location].grow(-BUFFER_SIZE)
		get_theme_stylebox("normal", "TranslucentButton").draw(ci, area)
		if proposed_drop_location_pivot == layout_location:
			var drop_sb := StyleBoxFlat.new()
			drop_sb.set_corner_radius_all(5)
			drop_sb.draw_center = false
			drop_sb.border_color = Configs.savedata.basic_color_valid
			if proposed_drop_location_direction == DropDirection.ABOVE:
				drop_sb.border_width_top = 2
			elif proposed_drop_location_direction == DropDirection.BELOW:
				drop_sb.border_width_bottom = 2
			elif proposed_drop_location_direction == DropDirection.INSIDE:
				drop_sb.set_border_width_all(2)
				if not Configs.savedata.get_layout_parts(proposed_drop_location_pivot).is_empty():
					drop_sb.border_color.a *= 0.4
			drop_sb.draw(ci, area)
	
	var parts_in_proposed_drop: Array[Utils.LayoutPart] = []
	if proposed_drop_location_direction == DropDirection.INSIDE:
		parts_in_proposed_drop = Configs.savedata.get_layout_parts(proposed_drop_location_pivot)
	
	for layout_part in layout_part_areas:
		var rect := layout_part_areas[layout_part].grow(-BUFFER_SIZE)
		var icon := Utils.get_layout_part_icon(layout_part)
		
		if is_instance_valid(dragged_data) and dragged_data.layout_part == layout_part:
			get_theme_stylebox("disabled", "TranslucentButton").draw(ci, rect)
		elif hovered_part == layout_part:
			get_theme_stylebox("hover", "TranslucentButton").draw(ci, rect)
		else:
			get_theme_stylebox("normal", "TranslucentButton").draw(ci, rect)
			if proposed_drop_idx >= 0:
				if parts_in_proposed_drop.size() > proposed_drop_idx and parts_in_proposed_drop[proposed_drop_idx] == layout_part:
					var drop_sb := StyleBoxFlat.new()
					drop_sb.set_corner_radius_all(5)
					drop_sb.draw_center = false
					drop_sb.border_color = Configs.savedata.basic_color_valid
					drop_sb.border_width_left = 2
					drop_sb.draw(ci, rect)
				elif proposed_drop_idx >= 1 and parts_in_proposed_drop.size() > proposed_drop_idx - 1 and\
				parts_in_proposed_drop[proposed_drop_idx - 1] == layout_part:
					var drop_sb := StyleBoxFlat.new()
					drop_sb.set_corner_radius_all(5)
					drop_sb.draw_center = false
					drop_sb.border_color = Configs.savedata.basic_color_valid
					drop_sb.border_width_right = 2
					drop_sb.draw(ci, rect)
			
		icon.draw(ci, (rect.get_center() - icon.get_size() / 2.0).round(), ThemeUtils.tinted_contrast_color)
	
	ThemeUtils.main_font.draw_string(ci, Vector2(0, 12),
			Translator.translate("Layout") + ":", HORIZONTAL_ALIGNMENT_CENTER, size.x,
			get_theme_font_size("font_size", "Label"), ThemeUtils.text_color)
	
	ThemeUtils.main_font.draw_string(ci, Vector2(0, size.x * 0.625 + 33),
			Translator.translate("Excluded") + ":", HORIZONTAL_ALIGNMENT_CENTER, size.x,
			get_theme_font_size("font_size", "Label"), ThemeUtils.text_color)


# Drag and drop

func _get_drag_data(at_position: Vector2) -> Variant:
	for part in layout_part_areas:
		if layout_part_areas[part].has_point(at_position):
			var btn := Button.new()
			btn.icon = Utils.get_layout_part_icon(part)
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.theme_type_variation = "TranslucentButton"
			btn.size = Vector2(PART_UI_SIZE, PART_UI_SIZE)
			set_drag_preview(btn)
			
			var location := Configs.savedata.get_layout_part_location(part)
			var index := Configs.savedata.get_layout_part_index(part)
			dragged_data = DragData.new(part, location, index)
			return dragged_data
	return null

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data == dragged_data:
		return
	
	if proposed_drop_location_direction == DropDirection.INSIDE and proposed_drop_location_pivot == dragged_data.layout_location:
		var parts := Configs.savedata.get_layout_parts(proposed_drop_location_pivot)
		# We're just rearranging tabs.
		parts.remove_at(dragged_data.idx)
		parts.insert(proposed_drop_idx if proposed_drop_idx <= dragged_data.idx else proposed_drop_idx - 1, dragged_data.layout_part)
		Configs.savedata.set_layout_parts(proposed_drop_location_pivot, parts)
	else:
		var old_parts := Configs.savedata.get_layout_parts(dragged_data.layout_location)
		old_parts.remove_at(dragged_data.idx)
		Configs.savedata.set_layout_parts(dragged_data.layout_location, old_parts, false)
		# We're moving part of the layout to another location.
		match proposed_drop_location_direction:
			DropDirection.INSIDE:
				var parts := Configs.savedata.get_layout_parts(proposed_drop_location_pivot)
				parts.insert(proposed_drop_idx, dragged_data.layout_part)
				Configs.savedata.set_layout_parts(proposed_drop_location_pivot, parts)
			DropDirection.BELOW:
				var bottom_left_parts := Configs.savedata.get_layout_parts(SaveData.LayoutLocation.BOTTOM_LEFT)
				if not bottom_left_parts.is_empty():
					# If everything is on the bottom, then move them to the top so the
					# new dragged layout part can be on the bottom.
					# If there are layout parts both on the top and the bottom, for this drop
					# to be valid, then the dragged part should be the only one on the top side.
					# In either case, the stuff on the bottom should be moved to the top,
					# and the dragged one should move to the bottom.
					Configs.savedata.set_layout_parts(SaveData.LayoutLocation.TOP_LEFT, bottom_left_parts, false)
				Configs.savedata.set_layout_parts(SaveData.LayoutLocation.BOTTOM_LEFT, [dragged_data.layout_part])
			DropDirection.ABOVE:
				# Same logic as above, but with top and bottom flipped.
				var top_left_parts := Configs.savedata.get_layout_parts(SaveData.LayoutLocation.TOP_LEFT)
				if not top_left_parts.is_empty():
					Configs.savedata.set_layout_parts(SaveData.LayoutLocation.BOTTOM_LEFT, top_left_parts, false)
				Configs.savedata.set_layout_parts(SaveData.LayoutLocation.TOP_LEFT, [dragged_data.layout_part])
	
	clear_proposed_drop()
	update_areas()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data == dragged_data:
		return false
	
	var top_left_parts := Configs.savedata.get_layout_parts(SaveData.LayoutLocation.TOP_LEFT)
	var bottom_left_parts := Configs.savedata.get_layout_parts(SaveData.LayoutLocation.BOTTOM_LEFT)
	var is_dragged_part_the_only_top_left := (top_left_parts == [dragged_data.layout_part])
	var is_dragged_part_the_only_bottom_left := (bottom_left_parts == [dragged_data.layout_part])
	
	for section in section_areas:
		var section_area := section_areas[section]
		if not section_area.has_point(at_position):
			continue
		
		proposed_drop_location_pivot = section
		
		if at_position.y < lerpf(section_area.position.y, section_area.end.y, 0.25) and ((section == SaveData.LayoutLocation.TOP_LEFT and\
		not is_dragged_part_the_only_top_left and (bottom_left_parts.is_empty() or is_dragged_part_the_only_bottom_left)) or\
		(section == SaveData.LayoutLocation.BOTTOM_LEFT and top_left_parts.is_empty() and not is_dragged_part_the_only_top_left)):
			# Hovering over the top side of the section, when one of the following is true:
			# Case 1: The section is top left, and there's either nothing on the bottom left,
			# or the only thing on the bottom left is the dragged layout part.
			# Case 2: The section is bottom left, there's nothing on the top left, and
			# the dragged layout part is not the only thing on the bottom left.
			proposed_drop_location_direction = DropDirection.ABOVE
			proposed_drop_idx = -1
		elif at_position.y > lerpf(section_area.position.y, section_area.end.y, 0.75) and ((section == SaveData.LayoutLocation.BOTTOM_LEFT and\
		not is_dragged_part_the_only_bottom_left and (top_left_parts.is_empty() or is_dragged_part_the_only_top_left)) or\
		(section == SaveData.LayoutLocation.TOP_LEFT and bottom_left_parts.is_empty() and not is_dragged_part_the_only_bottom_left)):
			# Same logic as the previous big condition, but top and bottom are flipped.
			proposed_drop_location_direction = DropDirection.BELOW
			proposed_drop_idx = -1
		elif not (section == SaveData.LayoutLocation.EXCLUDED and ((is_dragged_part_the_only_top_left and bottom_left_parts.is_empty()) or\
		(is_dragged_part_the_only_bottom_left and top_left_parts.is_empty()))):
			# Ensure we're not dragging the last layout part into excluded.
			proposed_drop_location_direction = DropDirection.INSIDE
			var layout_parts_count := Configs.savedata.get_layout_parts(section).size()
			if proposed_drop_location_pivot == SaveData.LayoutLocation.EXCLUDED:
				proposed_drop_idx = clampi(roundi(at_position.x / (PART_UI_SIZE + 8)), 0, layout_parts_count)
			else:
				proposed_drop_idx = clampi(roundi(((at_position.x - section_areas[section].get_center().x) / PART_UI_SIZE) + layout_parts_count / 2.0),
						0, layout_parts_count)
			
			if proposed_drop_location_pivot == dragged_data.layout_location and\
			(proposed_drop_idx == dragged_data.idx or proposed_drop_idx == dragged_data.idx + 1):
				proposed_drop_idx = -1
		else:
			clear_proposed_drop()
			return false
		
		if proposed_drop_idx != -1 or proposed_drop_location_direction != DropDirection.INSIDE or\
		proposed_drop_location_pivot != dragged_data.layout_location:
			return true
		else:
			clear_proposed_drop()
			return false
	clear_proposed_drop()
	return false

func clear_proposed_drop() -> void:
	proposed_drop_location_pivot = SaveData.LayoutLocation.NONE
	proposed_drop_location_direction = DropDirection.NONE
	proposed_drop_idx = -1


# Tooltips

func _get_tooltip(at_position: Vector2) -> String:
	# TODO Hack for the viewport tooltip.
	var half_width := size.x / 2.0
	if Rect2(half_width, 18, half_width, half_width * 1.25).grow(-BUFFER_SIZE).has_point(at_position):
		return TranslationUtils.get_layout_part_name(Utils.LayoutPart.VIEWPORT)
	
	for layout_part in layout_part_areas:
		if layout_part_areas[layout_part].grow(-BUFFER_SIZE).has_point(at_position):
			return TranslationUtils.get_layout_part_name(layout_part)
	return ""

func _make_custom_tooltip(for_text: String) -> Object:
	if for_text.is_empty():
		return null
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	var main_label := Label.new()
	main_label.text = for_text
	# TODO The condition is a hack for the viewport tooltip.
	vbox.add_child(main_label)
	if for_text != TranslationUtils.get_layout_part_name(Utils.LayoutPart.VIEWPORT):
		var dim_label := Label.new()
		dim_label.add_theme_color_override("font_color", ThemeUtils.dimmer_text_color)
		dim_label.text = Translator.translate("Drag and drop to change the layout")
		vbox.add_child(dim_label)
	return vbox


# Sync

func update_areas() -> void:
	for child in get_children():
		child.queue_free()
	
	var top_left := Configs.savedata.get_layout_parts(SaveData.LayoutLocation.TOP_LEFT)
	var bottom_left := Configs.savedata.get_layout_parts(SaveData.LayoutLocation.BOTTOM_LEFT)
	var excluded := Configs.savedata.get_layout_parts(SaveData.LayoutLocation.EXCLUDED)
	
	var included_rect_height := size.x * 0.625
	var half_width := size.x / 2.0
	var included_rect_half_height := included_rect_height / 2.0
	var v_offset := 18.0
	
	section_areas.clear()
	section_areas[SaveData.LayoutLocation.EXCLUDED] = Rect2(0, v_offset * 2 + included_rect_height + 2, size.x, PART_UI_SIZE + 8)
	
	if not top_left.is_empty() and not bottom_left.is_empty():
		section_areas[SaveData.LayoutLocation.TOP_LEFT] = Rect2(0, v_offset, half_width, included_rect_half_height)
		section_areas[SaveData.LayoutLocation.BOTTOM_LEFT] = Rect2(0, v_offset + included_rect_half_height, half_width, included_rect_half_height)
	elif bottom_left.is_empty():
		section_areas[SaveData.LayoutLocation.TOP_LEFT] = Rect2(0, v_offset, half_width, included_rect_height)
	elif top_left.is_empty():
		section_areas[SaveData.LayoutLocation.BOTTOM_LEFT] = Rect2(0, v_offset, half_width, included_rect_height)
	
	if not top_left.is_empty():
		var top_left_count := top_left.size()
		var top_left_rect_center := section_areas[SaveData.LayoutLocation.TOP_LEFT].get_center()
		for i in top_left_count:
			layout_part_areas[top_left[i]] = Rect2(top_left_rect_center.x - PART_UI_SIZE * (top_left_count * 0.5 - i),
					top_left_rect_center.y - PART_UI_SIZE / 2.0, PART_UI_SIZE, PART_UI_SIZE)
	
	if not bottom_left.is_empty():
		var bottom_left_count := bottom_left.size()
		var bottom_left_rect_center := section_areas[SaveData.LayoutLocation.BOTTOM_LEFT].get_center()
		for i in bottom_left_count:
			layout_part_areas[bottom_left[i]] = Rect2(bottom_left_rect_center.x - PART_UI_SIZE * (bottom_left_count * 0.5 - i),
					bottom_left_rect_center.y - PART_UI_SIZE / 2.0, PART_UI_SIZE, PART_UI_SIZE)
	
	var excluded_count := excluded.size()
	for i in excluded_count:
		var part := excluded[i]
		var rect := Rect2(section_areas[SaveData.LayoutLocation.EXCLUDED].position + Vector2((PART_UI_SIZE + 4) * i, 0),
				Vector2(PART_UI_SIZE + 8, PART_UI_SIZE + 8)).grow(-4)
		layout_part_areas[part] = rect
	
	queue_redraw()
