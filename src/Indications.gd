## This singleton handles editor information like zoom level and selections.
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

# The viewport listens for this signal to put you in handle-placing mode.
signal added_path_handle

# The PackedInt32Array holds the hierarchical orders. TID means Tag ID.
# For example, the 5th child of the 2nd child of the root tag would be (1, 4).
# PackedInt32Array() means it's invalid.
var hovered_tid := PackedInt32Array()
var selected_tids: Array[PackedInt32Array] = []
var selection_pivot_tid := PackedInt32Array()

# Semi-hovered means the tag has inner selections, but it is not selected itself.
# For example, individual path commands.
# Note that you can't have a selected tag and an inner selection simultaneously!
var semi_hovered_tid := PackedInt32Array()
var semi_selected_tid := PackedInt32Array()
# Inner stuff aren't in a tree, so they use an int. -1 means invalid.
var inner_hovered := -1
var inner_selections: Array[int] = []
var inner_selection_pivot := -1


signal zoom_changed
signal viewport_size_changed

var zoom := 0.0
var viewport_size := Vector2i.ZERO

func set_zoom(new_value):
	if zoom != new_value:
		zoom = new_value
		zoom_changed.emit()

func set_viewport_size(new_value):
	if viewport_size != new_value:
		viewport_size = new_value
		viewport_size_changed.emit()


func _ready() -> void:
	SVG.root_tag.tags_added.connect(_on_tags_added)
	SVG.root_tag.tags_deleted.connect(_on_tags_deleted)
	SVG.root_tag.tags_moved_in_parent.connect(_on_tags_moved_in_parent)
	SVG.root_tag.tags_moved_to.connect(_on_tags_moved_to)
	SVG.root_tag.changed_unknown.connect(clear_selection)

## A temporary normal_select for on click.
func temporary_normal_select(tid: PackedInt32Array) -> void:
	if not tid in selected_tids:
		selected_tids.append(tid.duplicate())
		selection_changed.emit()

## Override the selected tags with a single new selected tag.
## If inner_idx is given, this will be an inner selection.
func normal_select(tid: PackedInt32Array, inner_idx := -1) -> void:
	if tid.is_empty():
		return
	
	if inner_idx == -1:
		var old_selected_tids := selected_tids.duplicate()
		if not semi_selected_tid.is_empty():
			semi_selected_tid.clear()
			inner_selections.clear()
		if selected_tids.size() == 1 and selected_tids[0] == tid:
			return
		selection_pivot_tid = tid.duplicate()
		selected_tids = [tid.duplicate()]
		if old_selected_tids != selected_tids:
			selection_changed.emit()
	else:
		selected_tids.clear()
		var old_inner_selections := inner_selections.duplicate()
		if semi_selected_tid == tid and\
		inner_selections.size() == 1 and inner_selections[0] == inner_idx:
			return
		semi_selected_tid = tid.duplicate()
		inner_selection_pivot = inner_idx
		inner_selections = [inner_idx]
		if inner_selections != old_inner_selections:
			selection_changed.emit()

## If the tag was selected, unselect it. If it was unselected, select it.
## If inner_idx is given, this will be an inner selection.
func ctrl_select(tid: PackedInt32Array, inner_idx := -1) -> void:
	if tid.is_empty():
		return
	
	if inner_idx == -1:
		inner_selections.clear()
		var tid_idx := selected_tids.find(tid)
		if tid_idx == -1:
			selection_pivot_tid = tid.duplicate()
			selected_tids.append(tid.duplicate())
		else:
			selected_tids.remove_at(tid_idx)
			if selected_tids.is_empty():
				selection_pivot_tid = PackedInt32Array()
	else:
		if semi_selected_tid != tid:
			normal_select(tid, inner_idx)
		else:
			selected_tids.clear()
			var idx_idx := inner_selections.find(inner_idx)
			if idx_idx == -1:
				inner_selection_pivot = inner_idx
				inner_selections.append(inner_idx)
			else:
				inner_selections.remove_at(idx_idx)
				if inner_selections.is_empty():
					inner_selection_pivot = -1
	
	selection_changed.emit()

## Select all tags with the same depth from the tag to the last selected tag.
## Similarly for inner selections if inner_idx is given, but without tree logic.
func shift_select(tid: PackedInt32Array, inner_idx := -1) -> void:
	if tid.is_empty():
		return
	
	if inner_idx == -1:
		if selection_pivot_tid.is_empty():
			if selected_tids.is_empty():
				normal_select(tid, inner_idx)
			return
		
		if tid == selection_pivot_tid:
			return
		
		var old_selected_tids := selected_tids.duplicate()
		
		if tid.size() != selection_pivot_tid.size():
			if not tid in selected_tids:
				selected_tids.append(tid)
				selection_changed.emit()
				return
		
		var parent_tag := tid.duplicate()
		parent_tag.resize(parent_tag.size() - 1)
		var tid_idx := tid[-1]
		var selection_pivot_tid_idx := selection_pivot_tid[-1]
		
		var first_idx := mini(tid_idx, selection_pivot_tid_idx)
		var last_idx := maxi(tid_idx, selection_pivot_tid_idx)
		for i in range(first_idx, last_idx + 1):
			var new_tid := parent_tag.duplicate()
			new_tid.append(i)
			if not new_tid in selected_tids:
				selected_tids.append(new_tid)
		
		if selected_tids == old_selected_tids:
			return
	
	else:
		if inner_selection_pivot == -1:
			if inner_selections.is_empty():
				normal_select(tid, inner_idx)
			return
		
		var old_inner_selections := inner_selections.duplicate()
		var first_idx := mini(inner_selection_pivot, inner_idx)
		var last_idx := maxi(inner_selection_pivot, inner_idx)
		for i in range(first_idx, last_idx + 1):
			if not i in inner_selections:
				inner_selections.append(i)
		
		if inner_selections == old_inner_selections:
			return
	
	selection_changed.emit()

## Select all tags.
func select_all() -> void:
	clear_inner_selection()
	var tid_list := SVG.root_tag.get_all_tids()
	if selected_tids == tid_list:
		return
	
	for tid in SVG.root_tag.get_all_tids():
		if not tid in selected_tids:
			selected_tids.append(tid)
	selection_changed.emit()


## Clear the selected tags.
func clear_selection() -> void:
	if not selected_tids.is_empty():
		selected_tids.clear()
		selection_pivot_tid.clear()
		selection_changed.emit()

## Clear the inner selection.
func clear_inner_selection() -> void:
	if not inner_selections.is_empty() or not semi_selected_tid.is_empty():
		inner_selections.clear()
		semi_selected_tid.clear()
		inner_selection_pivot = -1
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

# If selected tags were moved, change the TIDs and their children.
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

func _on_tags_moved_to(new_tids: Array[PackedInt32Array]) -> void:
	selected_tids.clear()
	selected_tids.append_array(new_tids.duplicate())
	selection_changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if get_viewport().gui_is_dragging():
		return
	if event.is_action_pressed(&"delete"):
		delete_selected()
	elif event.is_action_pressed(&"move_up"):
		move_up_selected()
	elif event.is_action_pressed(&"move_down"):
		move_down_selected()
	elif event.is_action_pressed(&"duplicate"):
		duplicate_selected()
	elif event.is_action_pressed(&"select_all"):
		select_all()
	elif event is InputEventKey:
		# Path commands using keys.
		if inner_selections.is_empty() or event.is_command_or_control_pressed():
			# If a single path tag is selected, add the new command at the end.
			if selected_tids.size() == 1:
				var tag_ref := SVG.root_tag.get_by_tid(selected_tids[0])
				if tag_ref.name == "path":
					var path_attrib: AttributePath = tag_ref.attributes.d
					for action_name in path_actions_dict.keys():
						if event.is_action_pressed(action_name):
							path_attrib.insert_command(path_attrib.get_command_count(),
									path_actions_dict[action_name])
							normal_select(selected_tids[0], path_attrib.get_command_count() - 1)
							added_path_handle.emit()
							break
			return
		
		for action_name in path_actions_dict.keys():
			if event.is_action_pressed(action_name):
				var real_tag := SVG.root_tag.get_by_tid(semi_selected_tid)
				real_tag.attributes.d.insert_command(inner_selections.max() + 1,
						path_actions_dict[action_name])
				normal_select(semi_selected_tid, inner_selections.max() + 1)
				added_path_handle.emit()
				break


# Operations on selected tags.

func delete_selected() -> void:
	if not selected_tids.is_empty():
		SVG.root_tag.delete_tags(selected_tids)
	elif not inner_selections.is_empty() and not semi_selected_tid.is_empty():
		inner_selections.sort()
		inner_selections.reverse()
		var tag_ref := SVG.root_tag.get_by_tid(semi_selected_tid)
		match tag_ref.name:
			"path": tag_ref.attributes.d.delete_commands(inner_selections)
		clear_inner_selection()

func move_up_selected() -> void:
	SVG.root_tag.move_tags_in_parent(selected_tids, false)

func move_down_selected() -> void:
	SVG.root_tag.move_tags_in_parent(selected_tids, true)

func duplicate_selected() -> void:
	SVG.root_tag.duplicate_tags(selected_tids)
