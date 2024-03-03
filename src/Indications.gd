## This singleton handles editor information like zoom level and selections.
extends Node

const ContextPopup = preload("res://src/ui_elements/context_popup.tscn")
const PathCommandPopup = preload("res://src/ui_elements/path_popup.tscn")

const path_actions_dict := {
	"move_absolute": "M", "move_relative": "m",
	"line_absolute": "L", "line_relative": "l",
	"horizontal_line_absolute": "H", "horizontal_line_relative": "h",
	"vertical_line_absolute": "V", "vertical_line_relative": "v",
	"close_path_absolute": "Z", "close_path_relative": "z",
	"elliptical_arc_absolute": "A", "elliptical_arc_relative": "a",
	"cubic_bezier_absolute": "C", "cubic_bezier_relative": "c",
	"shorthand_cubic_bezier_absolute": "S", "shorthand_cubic_bezier_relative": "s",
	"quadratic_bezier_absolute": "Q", "quadratic_bezier_relative": "q",
	"shorthand_quadratic_bezier_absolute": "T", "shorthand_quadratic_bezier_relative": "t"
}

signal hover_changed
signal selection_changed
signal proposed_drop_changed

# The viewport listens for this signal to put you in handle-placing mode.
signal handle_added

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

# When dragging tags in the inspector.
var proposed_drop_tid := PackedInt32Array()


signal zoom_changed
signal viewport_size_changed

var zoom := 0.0
var viewport_size := Vector2i.ZERO

func set_zoom(new_value) -> void:
	if zoom != new_value:
		zoom = new_value
		zoom_changed.emit()

func set_viewport_size(new_value) -> void:
	if viewport_size != new_value:
		viewport_size = new_value
		viewport_size_changed.emit()


func _ready() -> void:
	SVG.root_tag.tags_added.connect(_on_tags_added)
	SVG.root_tag.tags_deleted.connect(_on_tags_deleted)
	SVG.root_tag.tags_moved_in_parent.connect(_on_tags_moved_in_parent)
	SVG.root_tag.tags_moved_to.connect(_on_tags_moved_to)
	SVG.root_tag.changed_unknown.connect(clear_all_selections)


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
func set_hovered(tid: PackedInt32Array, inner_idx := -1) -> void:
	if inner_idx == -1:
		if hovered_tid != tid:
			hovered_tid = tid.duplicate()
			if not tid.is_empty():
				inner_hovered = -1
				semi_hovered_tid = PackedInt32Array()
			hover_changed.emit()
	else:
		if semi_hovered_tid != tid:
			semi_hovered_tid = tid.duplicate()
			inner_hovered = inner_idx
			if not tid.is_empty():
				hovered_tid.clear()
			hover_changed.emit()
		elif inner_hovered != inner_idx:
			inner_hovered = inner_idx
			if not tid.is_empty():
				hovered_tid.clear()
			hover_changed.emit()

## If the tag is hovered, make it not hovered.
func remove_hovered(tid: PackedInt32Array, inner_idx := -1) -> void:
	if inner_idx == -1:
		if hovered_tid == tid:
			hovered_tid.clear()
			hover_changed.emit()
	else:
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


func set_proposed_drop_tid(tid: PackedInt32Array) -> void:
	if proposed_drop_tid != tid:
		proposed_drop_tid = tid.duplicate()
		proposed_drop_changed.emit()

func clear_proposed_drop_tid() -> void:
	if not proposed_drop_tid.is_empty():
		proposed_drop_tid.clear()
		proposed_drop_changed.emit()


func _on_tags_added(tids: Array[PackedInt32Array]) -> void:
	selected_tids = tids.duplicate()

# If selected tags were deleted, remove them from the list of selected tags.
func _on_tags_deleted(tids: Array[PackedInt32Array]) -> void:
	tids = tids.duplicate()  # For some reason, it breaks without this.
	var old_selected_tids := selected_tids.duplicate()
	for deleted_tid in tids:
		for i in range(selected_tids.size() - 1, -1, -1):
			var tid := selected_tids[i]
			if Utils.is_tid_parent_or_self(deleted_tid, tid):
				selected_tids.remove_at(i)
	if old_selected_tids != selected_tids:
		selection_changed.emit()

# If selected tags were moved up or down, change the TIDs and their children.
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
			if Utils.is_tid_parent_or_self(old_moved_tid, tid):
				var new_selected_tid := tid.duplicate()
				new_selected_tid[parent_tid.size()] = index_idx
				tids_to_unselect.append(tid)
				tids_to_select.append(new_selected_tid)
	for tid in tids_to_unselect:
		selected_tids.erase(tid)
	selected_tids += tids_to_select
	
	if old_selected_tids != selected_tids:
		selection_changed.emit()

# If selected tags were moved to a location, change the TIDs and their children.
func _on_tags_moved_to(tids: Array[PackedInt32Array], location: PackedInt32Array) -> void:
	tids = tids.duplicate()
	var new_selected_tids: Array[PackedInt32Array] = []
	for moved_idx in tids.size():
		var moved_tid := tids[moved_idx]
		for tid in selected_tids:
			if Utils.is_tid_parent_or_self(moved_tid, tid):
				var new_location := Utils.get_parent_tid(location)
				new_location.append(moved_idx + location[-1])
				for ii in range(moved_tid.size(), tid.size()):
					new_location.append(tid[ii])
				new_selected_tids.append(new_location)
	if selected_tids != new_selected_tids:
		selected_tids = new_selected_tids
		selection_changed.emit()


func respond_to_key_input(event: InputEventKey) -> void:
	# Path commands using keys.
	if inner_selections.is_empty() or event.is_command_or_control_pressed():
		# If a single path tag is selected, add the new command at the end.
		if selected_tids.size() == 1:
			var tag_ref := SVG.root_tag.get_tag(selected_tids[0])
			if tag_ref.name == "path":
				var path_attrib: AttributePath = tag_ref.attributes.d
				for action_name in path_actions_dict.keys():
					if event.is_action_pressed(action_name):
						var path_cmd_count := path_attrib.get_command_count()
						var path_cmd_char: String = path_actions_dict[action_name]
						# Z after a Z is syntactically invalid.
						if (path_cmd_count == 0 and not path_cmd_char in "Mm") or\
						(path_cmd_char in "Zz" and path_cmd_count > 0 and\
						path_attrib.get_command(path_cmd_count - 1) is\
						PathCommand.CloseCommand):
							return
						path_attrib.insert_command(path_cmd_count, path_cmd_char, Vector2.ZERO,
								Attribute.SyncMode.INTERMEDIATE)
						normal_select(selected_tids[0], path_cmd_count)
						handle_added.emit()
						break
		return
	# If path commands are selected, insert after the last one.
	for action_name in path_actions_dict.keys():
		var tag_ref := SVG.root_tag.get_tag(semi_selected_tid)
		if tag_ref.name == "path":
			if event.is_action_pressed(action_name):
				var path_attrib: AttributePath = tag_ref.attributes.d
				var path_cmd_char: String = path_actions_dict[action_name]
				var last_selection: int = inner_selections.max()
				# Z after a Z is syntactically invalid.
				if path_attrib.get_command(last_selection) is PathCommand.CloseCommand and\
				path_cmd_char in "Zz":
					return
				path_attrib.insert_command(last_selection + 1, path_cmd_char, Vector2.ZERO,
						Attribute.SyncMode.INTERMEDIATE)
				normal_select(semi_selected_tid, last_selection + 1)
				handle_added.emit()
				break


# Operations on selected tags.

func delete_selected() -> void:
	if not selected_tids.is_empty():
		SVG.root_tag.delete_tags(selected_tids)
	elif not inner_selections.is_empty() and not semi_selected_tid.is_empty():
		inner_selections.sort()
		inner_selections.reverse()
		var tag_ref := SVG.root_tag.get_tag(semi_selected_tid)
		match tag_ref.name:
			"path": tag_ref.attributes.d.delete_commands(inner_selections)
		clear_inner_selection()
		clear_inner_hovered()

func move_up_selected() -> void:
	SVG.root_tag.move_tags_in_parent(selected_tids, false)

func move_down_selected() -> void:
	SVG.root_tag.move_tags_in_parent(selected_tids, true)

func duplicate_selected() -> void:
	SVG.root_tag.duplicate_tags(selected_tids)

func insert_inner_after_selection(new_command: String) -> void:
	var tag_ref := SVG.root_tag.get_tag(semi_selected_tid)
	match tag_ref.name:
		"path":
			var path_attrib: AttributePath = tag_ref.attributes.d
			var last_selection: int = inner_selections.max()
			# Z after a Z is syntactically invalid.
			if path_attrib.get_command(last_selection) is PathCommand.CloseCommand and\
			new_command in "Zz":
				return
			path_attrib.insert_command(last_selection + 1, new_command)
			normal_select(semi_selected_tid, last_selection + 1)


func get_selection_context(popup_method: Callable) -> Popup:
	var btn_arr: Array[Button] = []
	
	if not selected_tids.is_empty():
		var filtered_tids := Utils.filter_descendant_tids(selected_tids)
		var can_move_down := true
		var can_move_up := true
		for base_tid in filtered_tids:
			if not Utils.are_tid_parents_same(base_tid, filtered_tids[0]):
				can_move_down = false
				can_move_up = false
				break
		
		if can_move_up or can_move_down:
			can_move_down = false
			can_move_up = false
			var parent_tid := Utils.get_parent_tid(filtered_tids[0])
			var filtered_count := filtered_tids.size()
			var parent_child_count := SVG.root_tag.get_tag(parent_tid).get_child_count()
			for base_tid in filtered_tids:
				if not can_move_up and base_tid[-1] >= filtered_count:
					can_move_up = true
				if not can_move_down and base_tid[-1] < parent_child_count - filtered_count:
					can_move_down = true
		
		btn_arr.append(Utils.create_btn(tr("Duplicate"), duplicate_selected,
				false, load("res://visual/icons/Duplicate.svg")))
		
		if selected_tids.size() == 1 and not SVG.root_tag.get_tag(
		selected_tids[0]).possible_conversions.is_empty():
			btn_arr.append(Utils.create_btn(tr("Convert To"),
					popup_convert_to_context.bind(popup_method), false,
					load("res://visual/icons/Reload.svg")))
		
		if can_move_up:
			btn_arr.append(Utils.create_btn(tr("Move Up"), move_up_selected,
					false, load("res://visual/icons/MoveUp.svg")))
		if can_move_down:
			btn_arr.append(Utils.create_btn(tr("Move Down"), move_down_selected,
					false, load("res://visual/icons/MoveDown.svg")))
		
		btn_arr.append(Utils.create_btn(tr("Delete"), delete_selected,
				false, load("res://visual/icons/Delete.svg")))
	elif not inner_selections.is_empty() and not semi_selected_tid.is_empty():
		if inner_selections.size() == 1:
			btn_arr.append(Utils.create_btn(tr("Insert After"),
					popup_insert_command_after_context.bind(popup_method),
					false, load("res://visual/icons/Plus.svg")))
			btn_arr.append(Utils.create_btn(tr("Convert To"),
					popup_convert_to_context.bind(popup_method), false,
					load("res://visual/icons/Reload.svg")))
		
		btn_arr.append(Utils.create_btn(tr("Delete"), delete_selected, false,
				load("res://visual/icons/Delete.svg")))
	
	var tag_context := ContextPopup.instantiate()
	add_child(tag_context)
	tag_context.set_button_array(btn_arr, true)
	return tag_context

func popup_convert_to_context(popup_method: Callable) -> void:
	# The "Convert To" context popup.
	if not selected_tids.is_empty():
		var btn_arr: Array[Button] = []
		var tag := SVG.root_tag.get_tag(selected_tids[0])
		for tag_name in tag.possible_conversions:
			var btn := Utils.create_btn(tag_name, convert_selected_tag_to.bind(tag_name),
					!tag.can_replace(tag_name), load("res://visual/icons/tag/%s.svg" % tag_name))
			btn.add_theme_font_override("font", load("res://visual/fonts/FontMono.ttf"))
			btn_arr.append(btn)
		var context_popup := ContextPopup.instantiate()
		add_child(context_popup)
		context_popup.set_button_array(btn_arr, true)
		popup_method.call(context_popup)
	elif not inner_selections.is_empty() and not semi_selected_tid.is_empty():
		var cmd_char: String = SVG.root_tag.get_tag(semi_selected_tid).\
				attributes.d.get_command(inner_selections[0]).command_char
		var command_picker := PathCommandPopup.instantiate()
		add_child(command_picker)
		command_picker.force_relativity(Utils.is_string_lower(cmd_char))
		command_picker.disable_invalid([cmd_char.to_upper()])
		command_picker.path_command_picked.connect(convert_selected_command_to)
		popup_method.call(command_picker)

func popup_insert_command_after_context(popup_method: Callable) -> void:
	var cmd_char: String = SVG.root_tag.get_tag(semi_selected_tid).attributes.d.\
			get_command(inner_selections.max()).command_char
	
	var command_picker := PathCommandPopup.instantiate()
	add_child(command_picker)
	match cmd_char.to_upper():
		"M": command_picker.disable_invalid(["M", "Z", "T"])
		"Z": command_picker.disable_invalid(["Z"])
		"L", "H", "V", "A": command_picker.disable_invalid(["S", "T"])
		"C", "S": command_picker.disable_invalid(["T"])
		"Q", "T": command_picker.disable_invalid(["S"])
	command_picker.path_command_picked.connect(insert_inner_after_selection)
	popup_method.call(command_picker)

func convert_selected_tag_to(tag_name: String) -> void:
	var tid := selected_tids[0]
	SVG.root_tag.replace_tag(tid, SVG.root_tag.get_tag(tid).get_replacement(tag_name))

func convert_selected_command_to(cmd_type: String) -> void:
	var tag_ref := SVG.root_tag.get_tag(semi_selected_tid)
	match tag_ref.name:
		"path": tag_ref.attributes.d.convert_command(inner_selections[0], cmd_type)
