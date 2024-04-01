extends PanelContainer

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")

# Autoscroll area on drag and drop. As a factor from edge to center.
const autoscroll_frac = 0.35  # 35% of the screen will be taken by the autoscroll areas.
const autoscroll_speed = 1500.0

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var tags: VBoxContainer = %Tags
@onready var covering_rect: Control = $MoveToOverlay

func _process(delta: float) -> void:
	if Indications.proposed_drop_tid.is_empty():
		return
	
	# Autoscroll when the dragged object is near the edge of the screen.
	var full_area := scroll_container.get_global_rect()
	var mouse_y := get_global_mouse_position().y
	var center_y := full_area.get_center().y
	# A factor in the range [-1, 1] for how far away the mouse is from the center.
	var factor := (mouse_y - center_y) / (full_area.size.y / 2)
	# Remap values from [0, 1] to [1 - autoscroll_area, 1].
	var scroll_amount := maxf((absf(factor) - 1 + autoscroll_frac) / autoscroll_frac, 0)
	# Increase autoscroll speed the closer to the edge of the container.
	var scroll_value := int(delta * signf(factor) * scroll_amount * autoscroll_speed)
	# Check if autoscrolling happened; if it did, the drop location may need updating.
	var old_scroll_vertical := scroll_container.scroll_vertical
	scroll_container.scroll_vertical += scroll_value
	if scroll_container.scroll_vertical != old_scroll_vertical:
		update_proposed_tid()

func update_proposed_tid() -> void:
	var y_pos := get_local_mouse_position().y + scroll_container.scroll_vertical
	var in_top_buffer := false
	var in_bottom_buffer := false
	# Keep track of the last tag editor whose position is before y_pos.
	var prev_tid := PackedInt32Array([-1])
	var prev_y := -INF
	# Keep track of the first tag editor whose end is after y_pos.
	var next_tid := PackedInt32Array([SVG.root_tag.get_child_count()])
	var next_y := INF
	
	for tid in SVG.root_tag.get_all_tids():
		var tag_rect := get_tag_editor_rect(tid)
		var buffer := minf(tag_rect.size.y / 3, 26)
		var tag_end := tag_rect.end.y
		var tag_start := tag_rect.position.y
		if y_pos < tag_end and tag_end < next_y:
			next_y = tag_end
			next_tid = tid
			if y_pos > tag_end - buffer:
				in_bottom_buffer = true
		if y_pos > tag_start and tag_start > prev_y:
			prev_y = tag_start
			prev_tid = tid
			if y_pos < tag_start + buffer:
				in_top_buffer = true
	# Set the proposed drop TID based on what the previous and next tag editors are.
	if in_top_buffer:
		Indications.set_proposed_drop_tid(prev_tid)
	elif in_bottom_buffer:
		Indications.set_proposed_drop_tid(Utils.get_parent_tid(next_tid) +\
				PackedInt32Array([next_tid[-1] + 1]))
	elif next_tid[0] >= SVG.root_tag.get_child_count():
		Indications.set_proposed_drop_tid(next_tid)
	elif Utils.is_tid_parent_or_self(prev_tid, next_tid):
		for i in range(prev_tid.size(), next_tid.size()):
			if next_tid[i] != 0:
				return
		Indications.set_proposed_drop_tid(prev_tid + PackedInt32Array([0]))


func _notification(what: int) -> void:
	if is_inside_tree() and not get_tree().paused:
		if what == NOTIFICATION_DRAG_BEGIN:
			covering_rect.show()
			update_proposed_tid()
		elif what == NOTIFICATION_DRAG_END:
			covering_rect.hide()
			Indications.clear_proposed_drop_tid()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and\
		not (event.ctrl_pressed or event.shift_pressed):
			Indications.clear_all_selections()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			# Find where the new tag should be added.
			var location := 0
			var y_pos := get_local_mouse_position().y + scroll_container.scroll_vertical
			while location < SVG.root_tag.get_child_count() and\
			get_tag_editor_rect(PackedInt32Array([location])).end.y < y_pos:
				location += 1
			# Create the context popup.
			var btn_array: Array[Button] = []
			for tag_name in ["path", "circle", "ellipse", "rect", "line"]:
				var btn := Utils.create_btn(tag_name, add_tag.bind(tag_name, location),
						false, SVGDB.get_tag_icon(tag_name))
				btn.add_theme_font_override("font", load("res://visual/fonts/FontMono.ttf"))
				btn_array.append(btn)
			
			var add_popup := ContextPopup.instantiate()
			add_child(add_popup)
			add_popup.setup_with_title(btn_array, tr("New tag"), true)
			var viewport := get_viewport()
			Utils.popup_under_pos(add_popup, viewport.get_mouse_position(), viewport)

func add_tag(tag_name: String, tag_location: int) -> void:
	match tag_name:
		"path": SVG.root_tag.add_tag(TagPath.new(), PackedInt32Array([tag_location]))
		"circle": SVG.root_tag.add_tag(TagCircle.new(), PackedInt32Array([tag_location]))
		"ellipse": SVG.root_tag.add_tag(TagEllipse.new(), PackedInt32Array([tag_location]))
		"rect": SVG.root_tag.add_tag(TagRect.new(), PackedInt32Array([tag_location]))
		"line": SVG.root_tag.add_tag(TagLine.new(), PackedInt32Array([tag_location]))

# This function assumes there exists a tag editor for the corresponding TID.
func get_tag_editor_rect(tid: PackedInt32Array) -> Rect2:
	if tid.is_empty():
		return Rect2()
	
	var tag_editor: Control = tags.get_child(tid[0])
	for i in range(1, tid.size()):
		tag_editor = tag_editor.child_tags_container.get_child(tid[i])
	# Position relative to the tag container.
	return Rect2(tag_editor.global_position - scroll_container.global_position +\
			Vector2(0, scroll_container.scroll_vertical), tag_editor.size)
