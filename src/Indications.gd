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

# The PackedInt32Array holds the hierarchical orders. TID means Tag ID.
# For example, the 5th child of the 2nd child of the root tag would be (1, 4).
# PackedInt32Array() means it's invalid.
var hovered_tid := PackedInt32Array()
var selected_tids: Array[PackedInt32Array] = []

# Semi-hovered means the tag has inner selections, but it is not selected itself.
# For example, individual path commands.
# Note that you can't have a selected tag and an inner selection simultaneously!
var semi_hovered_tid := PackedInt32Array()
var semi_selected_tid := PackedInt32Array()
# Inner stuff aren't in a tree, so they use an int. -1 means invalid.
var inner_hovered := -1
var inner_selections: Array[int] = []


func _ready() -> void:
	SVG.root_tag.tags_added.connect(_on_tags_added)
	SVG.root_tag.tags_deleted.connect(_on_tags_deleted)
	SVG.root_tag.tags_moved_in_parent.connect(_on_tags_moved_in_parent)
	#SVG.root_tag.tags_moved_to.connect(_on_tags_moved_to)  # TODO
	SVG.root_tag.changed_unknown.connect(clear_selection)
	SVG.root_tag.child_attribute_changed.connect(clear_inner_selection)

## If the tag was selected, unselect it. If it was unselected, select it.
func toggle_selection(tid: PackedInt32Array) -> void:
	if tid.is_empty():
		return
	
	var tid_idx := selected_tids.find(tid)
	if tid_idx == -1:
		selected_tids.append(tid.duplicate())
	else:
		selected_tids.remove_at(tid_idx)
	inner_selections.clear()
	selection_changed.emit()

## If the inner tag was selected, unselect it. If it was unselected, select it.
func toggle_inner_selection(tid: PackedInt32Array, inner_idx: int) -> void:
	if tid.is_empty():
		return
	
	var idx_idx := inner_selections.find(inner_idx)
	if idx_idx == -1:
		inner_selections.append(inner_idx)
	else:
		inner_selections.remove_at(idx_idx)
	selected_tids.clear()
	selection_changed.emit()

## Override the selected tags with a single new selected tag.
func set_selection(tid: PackedInt32Array) -> void:
	if selected_tids.size() != 1 or selected_tids[0] != tid:
		if not semi_selected_tid.is_empty():
			semi_selected_tid.clear()
			inner_selections.clear()
		selected_tids = [tid.duplicate()]
		selection_changed.emit()

## Override the inner selections with a single new inner selection.
func set_inner_selection(tid: PackedInt32Array, inner_idx: int) -> void:
	semi_selected_tid = tid.duplicate()
	inner_selections = [inner_idx]
	selected_tids.clear()
	selection_changed.emit()

## Clear the selected tags.
func clear_selection() -> void:
	if not selected_tids.is_empty():
		selected_tids.clear()
		selection_changed.emit()

## Clear the inner selection.
func clear_inner_selection() -> void:
	if not inner_selections.is_empty() or not semi_selected_tid.is_empty():
		inner_selections.clear()
		semi_selected_tid.clear()
		selection_changed.emit()

## Clear the selected tags or the inner selection.
func clear_all_selections() -> void:
	if not inner_selections.is_empty() or not semi_selected_tid.is_empty() or\
	not selected_tids.is_empty():
		selected_tids.clear()
		inner_selections.clear()
		semi_selected_tid.clear()
		selection_changed.emit()


## Set the hovered tag.
func set_hovered(tid: PackedInt32Array) -> void:
	if hovered_tid != tid:
		hovered_tid = tid.duplicate()
		hover_changed.emit()

## Set the inner hover.
func set_inner_hovered(tid: PackedInt32Array, inner_idx: int) -> void:
	if semi_hovered_tid != tid:
		semi_hovered_tid = tid.duplicate()
		inner_hovered = inner_idx
		if not tid.is_empty() and inner_idx != -1:
			hovered_tid.clear()
		hover_changed.emit()
	elif inner_hovered != inner_idx:
		inner_hovered = inner_idx
		if not tid.is_empty() and inner_idx != -1:
			hovered_tid.clear()
		hover_changed.emit()

## If the tag is hovered, make it not hovered.
func remove_hovered(tid: PackedInt32Array) -> void:
	if hovered_tid == tid:
		hovered_tid.clear()
		hover_changed.emit()

## If it's an inner hover, make it not hovered.
func remove_inner_hovered(tid: PackedInt32Array, inner_idx: int) -> void:
	if semi_hovered_tid == tid and inner_hovered == inner_idx:
		semi_hovered_tid.clear()
		inner_hovered = -1
		hover_changed.emit()

## Clear the hovered tag.
func clear_hovered() -> void:
	if not hovered_tid.is_empty():
		hovered_tid.clear()
		hover_changed.emit()

## Clear the inner hover.
func clear_inner_hovered() -> void:
	if inner_hovered != -1:
		inner_hovered = -1
		hover_changed.emit()

func _on_tags_added(tids: Array[PackedInt32Array]) -> void:
	selected_tids = tids.duplicate()

# If selected tags were deleted, remove them from the list of selected tags.
func _on_tags_deleted(tids: Array[PackedInt32Array]) -> void:
	tids = tids.duplicate()  # For some reason, it breaks without this.
	var old_selected_tids := selected_tids.duplicate()
	for deleted_tid in tids:
		for tid in selected_tids:
			if Utils.is_tid_parent(deleted_tid, tid) or deleted_tid == tid:
				selected_tids.erase(tid)
	if old_selected_tids != selected_tids:
		selection_changed.emit()

func _on_tags_moved_in_parent(parent_tid: PackedInt32Array, indices: Array[int]) -> void:
	var old_selected_tids := selected_tids.duplicate()
	var tids_to_select: Array[PackedInt32Array] = []
	var tids_to_unselect: Array[PackedInt32Array] = []
	
	for index_idx in indices.size():
		if index_idx == indices[index_idx]:
			continue
		
		# For the tags that have moved, get their old.
		var old_moved_tid := parent_tid.duplicate()
		old_moved_tid.append(indices[index_idx])
		
		# If the TID or a child of it is found, append it.
		for tid in selected_tids:
			if Utils.is_tid_parent(old_moved_tid, tid) or old_moved_tid == tid:
				var new_selected_tid := tid.duplicate()
				new_selected_tid[parent_tid.size()] = index_idx
				tids_to_unselect.append(tid)
				tids_to_select.append(new_selected_tid)
	for tid in tids_to_unselect:
		selected_tids.erase(tid)
	selected_tids += tids_to_select
	
	if old_selected_tids != selected_tids:
		selection_changed.emit()

# TODO implement this.
#func _on_tags_moved_to(tid: PackedInt32Array, old_tids: Array[PackedInt32Array]) -> void:
	#return


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"delete"):
		if not selected_tids.is_empty():
			SVG.root_tag.delete_tags(selected_tids)
		elif not inner_selections.is_empty() and not semi_selected_tid.is_empty():
			inner_selections.sort()
			inner_selections.reverse()
			var tag_ref := SVG.root_tag.get_by_tid(semi_selected_tid)
			match tag_ref.name:
				"path":
					for cmd_idx in inner_selections:
						tag_ref.attributes.d.delete_command(cmd_idx)
	elif event.is_action_pressed(&"move_up"):
		SVG.root_tag.move_tags_in_parent(selected_tids, false)
	elif event.is_action_pressed(&"move_down"):
		SVG.root_tag.move_tags_in_parent(selected_tids, true)
	elif event.is_action_pressed(&"duplicate"):
		SVG.root_tag.duplicate_tags(selected_tids)
	else:
		# Path commands using keys.
		if inner_selections.is_empty():
			return
		for action_name in path_actions_dict.keys():
			if event.is_action_pressed(action_name):
				var last_inner_selection = inner_selections.max()
				var real_tag := SVG.root_tag.get_by_tid(semi_selected_tid)
				real_tag.attributes.d.insert_command(
						last_inner_selection + 1, path_actions_dict[action_name])
				break
