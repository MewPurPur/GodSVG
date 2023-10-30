## This singleton handles hovering and selections.
## The information is used to synchronize the inspector and handles.
extends Node

const path_actions_dict := {
	&"move_absolute": "M", &"move_relative": "m",
	&"line_absolute": "L", &"line_relative": "l",
	&"horizontal_line_absolute": "H", &"horizontal_line_relative": "h",
	&"vertical_line_absolute": "V", &"vertical_line_relative": "v",
	&"close_path_absolute": "Z", &"close_path_relative": "z",
	&"elliptical_arc_absolute": "A", &"elliptical_arc_relative": "a",
	&"cubic_bezier_absolute": "C", &"cubic_bezier_relative": "c",
	&"shorthand_cubic_bezier_absolute": "S", &"shorthand_cubic_bezier_relative": "s",
	&"quadratic_bezier_absolute": "Q", &"quadratic_bezier_relative": "q",
	&"shorthand_quadratic_bezier_absolute": "T", &"shorthand_quadratic_bezier_relative": "t"
}

signal hover_changed
signal selection_changed

var hovered_tag := -1
var selected_tags: Array[int] = []

# Semi-hovered means the tag has inner selections, but it is not selected itself.
# For example, individual path commands.
var semi_selected_tag: int = -1
var inner_selections: Array[int] = []
var semi_hovered_tag: int = -1
var inner_hovered: int = -1


func _ready() -> void:
	SVG.root_tag.tags_deleted.connect(_on_tags_deleted)
	SVG.root_tag.tag_moved.connect(_on_tag_moved)
	SVG.root_tag.child_tag_attribute_changed.connect(_on_child_tag_attribute_changed)

func toggle_selection(idx: int) -> void:
	if idx >= 0:
		var idx_idx := selected_tags.find(idx)
		if idx_idx == -1:
			selected_tags.append(idx)
		else:
			selected_tags.remove_at(idx_idx)
		inner_selections.clear()
		selection_changed.emit()

func toggle_inner_selection(idx: int, inner_idx: int) -> void:
	if idx >= 0:
		var idx_idx := inner_selections.find(inner_idx)
		if idx_idx == -1:
			inner_selections.append(inner_idx)
		else:
			inner_selections.remove_at(idx_idx)
		selected_tags.clear()
		selection_changed.emit()

func set_selection(idx: int) -> void:
	if selected_tags.size() != 1 or selected_tags[0] != idx:
		if semi_selected_tag != -1:
			semi_selected_tag = -1
			inner_selections.clear()
		selected_tags = [idx]
		selection_changed.emit()

func set_inner_selection(idx: int, inner_idx: int) -> void:
	semi_selected_tag = idx
	inner_selections = [inner_idx]
	selected_tags.clear()
	selection_changed.emit()

func clear_selection() -> void:
	selected_tags.clear()
	selection_changed.emit()

func clear_inner_selection() -> void:
	inner_selections.clear()
	semi_selected_tag = -1
	selection_changed.emit()


func set_hovered(idx: int) -> void:
	if hovered_tag != idx:
		hovered_tag = idx
		hover_changed.emit()

func set_inner_hovered(idx: int, inner_idx: int) -> void:
	if semi_hovered_tag != idx:
		semi_hovered_tag = idx
		inner_hovered = inner_idx
		if idx != -1 and inner_idx != -1:
			hovered_tag = -1
		hover_changed.emit()
	elif inner_hovered != inner_idx:
		inner_hovered = inner_idx
		if idx != -1 and inner_idx != -1:
			hovered_tag = -1
		hover_changed.emit()

func remove_hovered(idx: int) -> void:
	if hovered_tag == idx:
		hovered_tag = -1
		hover_changed.emit()

func remove_inner_hovered(idx: int, inner_idx: int) -> void:
	if semi_hovered_tag == idx and inner_hovered == inner_idx:
		semi_hovered_tag = -1
		inner_hovered = -1
		hover_changed.emit()

func clear_hovered() -> void:
	if hovered_tag != -1:
		hovered_tag = -1
		hover_changed.emit()

func clear_inner_hovered() -> void:
	if inner_hovered != -1:
		inner_hovered = -1
		hover_changed.emit()

# If selected tags were deleted, remove them from the list of selected tags.
func _on_tags_deleted(indices_arr: Array[int]) -> void:
	indices_arr = indices_arr.duplicate()  # For some reason, it breaks without this.
	for idx in indices_arr:
		selected_tags.erase(idx)
	selection_changed.emit()

func _on_tag_moved(old_idx: int, new_idx: int) -> void:
	for i in selected_tags.size():
		var idx := selected_tags[i]
		if (idx < old_idx and idx < new_idx) or (idx > old_idx and idx > new_idx):
			continue
		elif idx > old_idx and idx < new_idx:
			selected_tags[i] += 1
		elif idx <= old_idx and idx > new_idx:
			selected_tags[i] -= 1
		elif idx == old_idx:
			selected_tags[i] = new_idx

func _on_child_tag_attribute_changed() -> void:
	clear_inner_selection()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"delete"):
		if !selected_tags.is_empty():
			SVG.root_tag.delete_tags(selected_tags)
		elif !inner_selections.is_empty() and semi_selected_tag != -1:
			inner_selections.sort()
			inner_selections.reverse()
			for cmd_idx in inner_selections:
				var tag_ref := SVG.root_tag.child_tags[semi_selected_tag]
				match tag_ref.title:
					"path": tag_ref.attributes.d.delete_command(cmd_idx)
	elif event.is_action_pressed(&"move_up"):
		var unaffected := 0
		selected_tags.sort()
		for tag_idx in selected_tags:
			if tag_idx == unaffected:
				unaffected += 1
				continue
			SVG.root_tag.move_tag(tag_idx, tag_idx - 1)
	elif event.is_action_pressed(&"move_down"):
		var unaffected := SVG.root_tag.get_child_count() - 1
		selected_tags.sort()
		selected_tags.reverse()
		for tag_idx in selected_tags:
			if tag_idx == unaffected:
				unaffected -= 1
				continue
			SVG.root_tag.move_tag(tag_idx, tag_idx + 1)
	elif event.is_action_pressed(&"duplicate"):
		selected_tags.sort()
		selected_tags.reverse()
		for tag_idx in selected_tags:
			SVG.root_tag.duplicate_tag(tag_idx)
	else:
		if !inner_selections.is_empty():
			for action_name in path_actions_dict.keys():
				if event.is_action_pressed(action_name):
					var last_inner_selection = inner_selections.max()
					var real_tag := SVG.root_tag.child_tags[semi_selected_tag]
					real_tag.attributes.d.insert_command(
							last_inner_selection + 1, path_actions_dict[action_name])
					break
