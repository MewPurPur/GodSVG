# This singleton handles temporary editor information like zoom level and selections.
extends Node

# Not a good idea to preload scenes inside a singleton.
var PathCommandPopup = load("res://src/ui_widgets/path_popup.tscn")

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

signal requested_scroll_to_element_editor(xid: PackedInt32Array)

# The viewport listens for this signal to put you in handle-placing mode.
signal handle_added

# The PackedInt32Array holds the hierarchical orders. XID means XMLNode ID.
# For example, the 5th child of the 2nd child of the root element would be (1, 4).
# PackedInt32Array() means it's invalid.
var hovered_xid := PackedInt32Array()
var selected_xids: Array[PackedInt32Array] = []
var selection_pivot_xid := PackedInt32Array()

# Semi-hovered means the element has inner selections, but it is not selected itself.
# For example, individual path commands.
# Note that you can't have a selected element and an inner selection simultaneously!
var semi_hovered_xid := PackedInt32Array()
var semi_selected_xid := PackedInt32Array()
# Inner stuff aren't in a tree, so they use an int. -1 means invalid.
var inner_hovered := -1
var inner_selections: Array[int] = []
var inner_selection_pivot := -1

# When dragging elements in the inspector.
var proposed_drop_xid := PackedInt32Array()


signal zoom_changed
signal viewport_size_changed

var zoom := 0.0
var viewport_size := Vector2i.ZERO

func set_zoom(new_value: float) -> void:
	if zoom != new_value:
		zoom = new_value
		zoom_changed.emit()

func set_viewport_size(new_value: Vector2i) -> void:
	if viewport_size != new_value:
		viewport_size = new_value
		viewport_size_changed.emit()


func _ready() -> void:
	SVG.xnodes_added.connect(_on_xnodes_added)
	SVG.xnodes_deleted.connect(_on_xnodes_deleted)
	SVG.xnodes_moved_in_parent.connect(_on_xnodes_moved_in_parent)
	SVG.xnodes_moved_to.connect(_on_xnodes_moved_to)
	SVG.changed_unknown.connect(clear_all_selections)


# Override the selected elements with a single new selected element.
# If inner_idx is given, this will be an inner selection.
func normal_select(xid: PackedInt32Array, inner_idx := -1) -> void:
	if xid.is_empty():
		return
	
	if inner_idx == -1:
		var old_selected_xids := selected_xids.duplicate()
		if not semi_selected_xid.is_empty():
			semi_selected_xid.clear()
			inner_selections.clear()
		if selected_xids.size() == 1 and selected_xids[0] == xid:
			return
		selection_pivot_xid = xid.duplicate()
		selected_xids = [xid.duplicate()]
		if old_selected_xids != selected_xids:
			selection_changed.emit()
	else:
		selected_xids.clear()
		var old_inner_selections := inner_selections.duplicate()
		if semi_selected_xid == xid and\
		inner_selections.size() == 1 and inner_selections[0] == inner_idx:
			return
		semi_selected_xid = xid.duplicate()
		inner_selection_pivot = inner_idx
		inner_selections = [inner_idx]
		if inner_selections != old_inner_selections:
			selection_changed.emit()

# If the element was selected, unselect it. If it was unselected, select it.
# If inner_idx is given, this will be an inner selection.
func ctrl_select(xid: PackedInt32Array, inner_idx := -1) -> void:
	if xid.is_empty():
		return
	
	if inner_idx == -1:
		inner_selections.clear()
		var xid_idx := selected_xids.find(xid)
		if xid_idx == -1:
			selection_pivot_xid = xid.duplicate()
			selected_xids.append(xid.duplicate())
		else:
			selected_xids.remove_at(xid_idx)
			if selected_xids.is_empty():
				selection_pivot_xid = PackedInt32Array()
	else:
		if semi_selected_xid != xid:
			normal_select(xid, inner_idx)
		else:
			selected_xids.clear()
			var idx_idx := inner_selections.find(inner_idx)
			if idx_idx == -1:
				inner_selection_pivot = inner_idx
				inner_selections.append(inner_idx)
			else:
				inner_selections.remove_at(idx_idx)
				if inner_selections.is_empty():
					inner_selection_pivot = -1
	
	selection_changed.emit()

# Select all elements with the same depth from the element to the last selected element.
# Similarly for inner selections if inner_idx is given, but without tree logic.
func shift_select(xid: PackedInt32Array, inner_idx := -1) -> void:
	if xid.is_empty():
		return
	
	if inner_idx == -1:
		if selection_pivot_xid.is_empty():
			if selected_xids.is_empty():
				normal_select(xid, inner_idx)
			return
		
		if xid == selection_pivot_xid:
			return
		
		var old_selected_xids := selected_xids.duplicate()
		
		if xid.size() != selection_pivot_xid.size():
			if not xid in selected_xids:
				selected_xids.append(xid)
				selection_changed.emit()
				return
		
		var parent_element := xid.duplicate()
		parent_element.resize(parent_element.size() - 1)
		var xid_idx := xid[-1]
		var selection_pivot_xid_idx := selection_pivot_xid[-1]
		
		var first_idx := mini(xid_idx, selection_pivot_xid_idx)
		var last_idx := maxi(xid_idx, selection_pivot_xid_idx)
		for i in range(first_idx, last_idx + 1):
			var new_xid := parent_element.duplicate()
			new_xid.append(i)
			if not new_xid in selected_xids:
				selected_xids.append(new_xid)
		
		if selected_xids == old_selected_xids:
			return
	
	else:
		if inner_selection_pivot == -1:
			if inner_selections.is_empty():
				normal_select(xid, inner_idx)
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

# Select all elements.
func select_all() -> void:
	clear_inner_selection()
	var xnode_list: Array[XNode] = SVG.root_element.get_all_xnode_descendants()
	var xid_list: Array = xnode_list.map(func(xnode): return xnode.xid)
	if selected_xids == xid_list:
		return
	
	for xid in xid_list:
		if not xid in selected_xids:
			selected_xids.append(xid)
	selection_changed.emit()


# Clear the selected elements.
func clear_selection() -> void:
	if not selected_xids.is_empty():
		selected_xids.clear()
		selection_pivot_xid.clear()
		selection_changed.emit()

# Clear the inner selection.
func clear_inner_selection() -> void:
	if not inner_selections.is_empty() or not semi_selected_xid.is_empty():
		inner_selections.clear()
		semi_selected_xid.clear()
		inner_selection_pivot = -1
		selection_changed.emit()

# Clear the selected elements or the inner selection.
func clear_all_selections() -> void:
	if not inner_selections.is_empty() or not semi_selected_xid.is_empty() or\
	not selected_xids.is_empty():
		selected_xids.clear()
		inner_selections.clear()
		semi_selected_xid.clear()
		selection_changed.emit()


# Set the hovered element.
func set_hovered(xid: PackedInt32Array, inner_idx := -1) -> void:
	if inner_idx == -1:
		if hovered_xid != xid:
			hovered_xid = xid.duplicate()
			if not xid.is_empty():
				inner_hovered = -1
				semi_hovered_xid = PackedInt32Array()
			hover_changed.emit()
	else:
		if semi_hovered_xid != xid:
			semi_hovered_xid = xid.duplicate()
			inner_hovered = inner_idx
			if not xid.is_empty():
				hovered_xid.clear()
			hover_changed.emit()
		elif inner_hovered != inner_idx:
			inner_hovered = inner_idx
			if not xid.is_empty():
				hovered_xid.clear()
			hover_changed.emit()

# If the element is hovered, make it not hovered.
func remove_hovered(xid: PackedInt32Array, inner_idx := -1) -> void:
	if inner_idx == -1:
		if hovered_xid == xid:
			hovered_xid.clear()
			hover_changed.emit()
	else:
		if semi_hovered_xid == xid and inner_hovered == inner_idx:
			semi_hovered_xid.clear()
			inner_hovered = -1
			hover_changed.emit()

# Clear the hovered element.
func clear_hovered() -> void:
	if not hovered_xid.is_empty():
		hovered_xid.clear()
		hover_changed.emit()

# Clear the inner hover.
func clear_inner_hovered() -> void:
	if inner_hovered != -1:
		inner_hovered = -1
		hover_changed.emit()

# Returns whether the given element or inner editor is hovered.
func is_hovered(xid: PackedInt32Array, inner_idx := -1, propagate := false) -> bool:
	if propagate:
		if inner_idx == -1:
			return XIDUtils.is_parent_or_self(hovered_xid, xid)
		else:
			return XIDUtils.is_parent_or_self(hovered_xid, xid) or\
					(semi_hovered_xid == xid and inner_hovered == inner_idx)
	else:
		if inner_idx == -1:
			return hovered_xid == xid
		else:
			return semi_hovered_xid == xid and inner_hovered == inner_idx

# Returns whether the given element or inner editor is selected.
func is_selected(xid: PackedInt32Array, inner_idx := -1, propagate := false) -> bool:
	if propagate:
		if inner_idx == -1:
			for selected_xid in selected_xids:
				if XIDUtils.is_parent_or_self(selected_xid, xid):
					return true
			return false
		else:
			for selected_xid in selected_xids:
				if XIDUtils.is_parent_or_self(selected_xid, xid):
					return true
			return semi_selected_xid == xid and inner_idx in inner_selections
	else:
		if inner_idx == -1:
			return xid in selected_xids
		else:
			return semi_selected_xid == xid and inner_idx in inner_selections


func set_proposed_drop_xid(xid: PackedInt32Array) -> void:
	if proposed_drop_xid != xid:
		proposed_drop_xid = xid.duplicate()
		proposed_drop_changed.emit()

func clear_proposed_drop_xid() -> void:
	if not proposed_drop_xid.is_empty():
		proposed_drop_xid.clear()
		proposed_drop_changed.emit()


func _on_xnodes_added(xids: Array[PackedInt32Array]) -> void:
	selected_xids = xids.duplicate()

# If selected elements were deleted, remove them from the list of selected elements.
func _on_xnodes_deleted(xids: Array[PackedInt32Array]) -> void:
	xids = xids.duplicate()  # For some reason, it breaks without this.
	var old_selected_xids := selected_xids.duplicate()
	for deleted_xid in xids:
		for i in range(selected_xids.size() - 1, -1, -1):
			var xid := selected_xids[i]
			if XIDUtils.is_parent_or_self(deleted_xid, xid):
				selected_xids.remove_at(i)
	if old_selected_xids != selected_xids:
		selection_changed.emit()

# If selected elements were moved up or down, change the XIDs and their children.
func _on_xnodes_moved_in_parent(parent_xid: PackedInt32Array, indices: Array[int]) -> void:
	var old_selected_xids := selected_xids.duplicate()
	var xids_to_select: Array[PackedInt32Array] = []
	var xids_to_unselect: Array[PackedInt32Array] = []
	
	for index_idx in indices.size():
		if index_idx == indices[index_idx]:
			continue
		
		# For the elements that have moved, get their old.
		var old_moved_xid := parent_xid.duplicate()
		old_moved_xid.append(indices[index_idx])
		
		# If the XID or a child of it is found, append it.
		for xid in selected_xids:
			if XIDUtils.is_parent_or_self(old_moved_xid, xid):
				var new_selected_xid := xid.duplicate()
				new_selected_xid[parent_xid.size()] = index_idx
				xids_to_unselect.append(xid)
				xids_to_select.append(new_selected_xid)
	for xid in xids_to_unselect:
		selected_xids.erase(xid)
	selected_xids += xids_to_select
	
	if old_selected_xids != selected_xids:
		selection_changed.emit()

# If selected elements were moved to a location, change the XIDs and their children.
func _on_xnodes_moved_to(xids: Array[PackedInt32Array], location: PackedInt32Array) -> void:
	xids = xids.duplicate()
	var new_selected_xids: Array[PackedInt32Array] = []
	for moved_idx in xids.size():
		var moved_xid := xids[moved_idx]
		for xid in selected_xids:
			if XIDUtils.is_parent_or_self(moved_xid, xid):
				var new_location := XIDUtils.get_parent_xid(location)
				new_location.append(moved_idx + location[-1])
				for ii in range(moved_xid.size(), xid.size()):
					new_location.append(xid[ii])
				new_selected_xids.append(new_location)
	if selected_xids != new_selected_xids:
		selected_xids = new_selected_xids
		selection_changed.emit()


func respond_to_key_input(event: InputEventKey) -> void:
	# Path commands using keys.
	if inner_selections.is_empty() or event.is_command_or_control_pressed():
		# If a single path element is selected, add the new command at the end.
		if selected_xids.size() == 1:
			var xnode_ref := SVG.root_element.get_xnode(selected_xids[0])
			if xnode_ref is ElementPath:
				var path_attrib: AttributePathdata = xnode_ref.get_attribute("d")
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
						path_attrib.insert_command(path_cmd_count, path_cmd_char, Vector2.ZERO)
						normal_select(selected_xids[0], path_cmd_count)
						handle_added.emit()
						break
				
		return
	# If path commands are selected, insert after the last one.
	for action_name in path_actions_dict.keys():
		var element_ref := SVG.root_element.get_xnode(semi_selected_xid)
		if element_ref.name == "path":
			if event.is_action_pressed(action_name):
				var path_attrib: AttributePathdata = element_ref.get_attribute("d")
				var path_cmd_char: String = path_actions_dict[action_name]
				var last_selection: int = inner_selections.max()
				# Z after a Z is syntactically invalid.
				if path_attrib.get_command(last_selection) is PathCommand.CloseCommand and\
				path_cmd_char in "Zz":
					return
				path_attrib.insert_command(last_selection + 1, path_cmd_char, Vector2.ZERO)
				normal_select(semi_selected_xid, last_selection + 1)
				handle_added.emit()
				break


# Operations on selected elements.

func delete_selected() -> void:
	if not selected_xids.is_empty():
		SVG.root_element.delete_xnodes(selected_xids)
		SVG.queue_save()
	elif not inner_selections.is_empty() and not semi_selected_xid.is_empty():
		inner_selections.sort()
		inner_selections.reverse()
		var element_ref := SVG.root_element.get_xnode(semi_selected_xid)
		match element_ref.name:
			"path": element_ref.get_attribute("d").delete_commands(inner_selections)
			"polygon", "polyline":
				var indices_to_delete: Array[int] = []
				for idx in inner_selections:
					indices_to_delete.append(idx * 2)
					indices_to_delete.append(idx * 2 + 1)
				element_ref.get_attribute("points").delete_elements(indices_to_delete)
		clear_inner_selection()
		clear_inner_hovered()
		SVG.queue_save()

func move_up_selected() -> void:
	SVG.root_element.move_xnodes_in_parent(selected_xids, false)
	SVG.queue_save()

func move_down_selected() -> void:
	SVG.root_element.move_xnodes_in_parent(selected_xids, true)
	SVG.queue_save()

func view_in_list(xid: PackedInt32Array) -> void:
	if xid.is_empty():
		return
	requested_scroll_to_element_editor.emit(xid)

func duplicate_selected() -> void:
	SVG.root_element.duplicate_xnodes(selected_xids)
	SVG.queue_save()

func insert_path_command_after_selection(new_command: String) -> void:
	var path_attrib: AttributePathdata = SVG.root_element.get_xnode(
			semi_selected_xid).get_attribute("d")
	var last_selection: int = inner_selections.max()
	# Z after a Z is syntactically invalid.
	if path_attrib.get_command(last_selection) is PathCommand.CloseCommand and\
	new_command in "Zz":
		return
	path_attrib.insert_command(last_selection + 1, new_command)
	normal_select(semi_selected_xid, last_selection + 1)
	SVG.queue_save()

func insert_point_after_selection() -> void:
	var element_ref: Element = SVG.root_element.get_xnode(semi_selected_xid)
	var last_selection: int = inner_selections.max()
	element_ref.get_attribute("points").insert_element(last_selection * 2, 0)
	element_ref.get_attribute("points").insert_element(last_selection * 2, 0)
	SVG.queue_save()


enum Context {
	VIEWPORT,
	LIST,
}

func get_selection_context(popup_method: Callable, context: Context) -> ContextPopup:
	var btn_arr: Array[Button] = []
	
	if not selected_xids.is_empty():
		var filtered_xids := XIDUtils.filter_descendants(selected_xids)
		var can_move_down := true
		var can_move_up := true
		for base_xid in filtered_xids:
			if not XIDUtils.are_siblings(base_xid, filtered_xids[0]):
				can_move_down = false
				can_move_up = false
				break
		
		if can_move_up or can_move_down:
			can_move_down = false
			can_move_up = false
			var parent_xid := XIDUtils.get_parent_xid(filtered_xids[0])
			var filtered_count := filtered_xids.size()
			var parent_child_count: int = SVG.root_element.get_xnode(parent_xid).get_child_count()
			for base_xid in filtered_xids:
				if not can_move_up and base_xid[-1] >= filtered_count:
					can_move_up = true
				if not can_move_down and base_xid[-1] < parent_child_count - filtered_count:
					can_move_down = true
		if context == Context.VIEWPORT:
			btn_arr.append(ContextPopup.create_button(
					TranslationServer.translate("View In List"),
					view_in_list.bind(selected_xids[0]), false,
					load("res://visual/icons/ViewInList.svg")))

		btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Duplicate"),
				duplicate_selected, false, load("res://visual/icons/Duplicate.svg"),
				"duplicate"))
		
		var xnode := SVG.root_element.get_xnode(selected_xids[0])
		if (selected_xids.size() == 1 and not xnode.is_element()) or\
		(xnode.is_element() and not xnode.possible_conversions.is_empty()):
			btn_arr.append(ContextPopup.create_button(
					TranslationServer.translate("Convert To"),
					popup_convert_to_context.bind(popup_method), false,
					load("res://visual/icons/Reload.svg")))
		
		if can_move_up:
			btn_arr.append(ContextPopup.create_button(
					TranslationServer.translate("Move Up"),
					move_up_selected, false,
					load("res://visual/icons/MoveUp.svg"), "move_up"))
		if can_move_down:
			btn_arr.append(ContextPopup.create_button(
					TranslationServer.translate("Move Down"),
					move_down_selected, false,
					load("res://visual/icons/MoveDown.svg"), "move_down"))
		
		btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Delete"),
				delete_selected, false, load("res://visual/icons/Delete.svg"), "delete"))
	
	elif not inner_selections.is_empty() and not semi_selected_xid.is_empty():
		var element_ref := SVG.root_element.get_xnode(semi_selected_xid)
		
		if context == Context.VIEWPORT:
			btn_arr.append(ContextPopup.create_button(
					TranslationServer.translate("View In List"),
					view_in_list.bind(semi_selected_xid), false,
					load("res://visual/icons/ViewInList.svg")))
		match element_ref.name:
			"path":
				if inner_selections.size() == 1:
					btn_arr.append(ContextPopup.create_button(
							TranslationServer.translate("Insert After"),
							popup_insert_command_after_context.bind(popup_method), false,
							load("res://visual/icons/Plus.svg")))
					btn_arr.append(ContextPopup.create_button(
							TranslationServer.translate("Convert To"),
							popup_convert_to_context.bind(popup_method), false,
							load("res://visual/icons/Reload.svg")))
			"polygon", "polyline":
				if inner_selections.size() == 1:
					btn_arr.append(ContextPopup.create_button(
							TranslationServer.translate("Insert After"),
							insert_point_after_selection, false,
							load("res://visual/icons/Plus.svg")))
		
		btn_arr.append(ContextPopup.create_button(TranslationServer.translate("Delete"),
				delete_selected, false, load("res://visual/icons/Delete.svg"), "delete"))
	
	var element_context := ContextPopup.new()
	element_context.setup(btn_arr, true)
	return element_context

func popup_convert_to_context(popup_method: Callable) -> void:
	# The "Convert To" context popup.
	if not selected_xids.is_empty():
		var btn_arr: Array[Button] = []
		var xnode := SVG.root_element.get_xnode(selected_xids[0])
		if not xnode.is_element():
			for xnode_type in xnode.get_possible_conversions():
				var btn := ContextPopup.create_button(BasicXNode.get_type_string(xnode_type),
						convert_selected_xnode_to.bind(xnode_type),
						false, DB.get_xnode_icon(xnode_type))
				btn.add_theme_font_override("font", ThemeUtils.mono_font)
				btn_arr.append(btn)
		else:
			for element_name in xnode.possible_conversions:
				var btn := ContextPopup.create_button(element_name,
						convert_selected_element_to.bind(element_name),
						!xnode.can_replace(element_name), DB.get_element_icon(element_name))
				btn.add_theme_font_override("font", ThemeUtils.mono_font)
				btn_arr.append(btn)
		var context_popup := ContextPopup.new()
		context_popup.setup(btn_arr, true)
		popup_method.call(context_popup)
	elif not inner_selections.is_empty() and not semi_selected_xid.is_empty():
		var cmd_char: String = SVG.root_element.get_xnode(semi_selected_xid).\
				get_attribute("d").get_command(inner_selections[0]).command_char
		var command_picker = PathCommandPopup.instantiate()
		popup_method.call(command_picker)
		command_picker.force_relativity(Utils.is_string_lower(cmd_char))
		command_picker.disable_invalid([cmd_char.to_upper()])
		command_picker.path_command_picked.connect(convert_selected_command_to)

func popup_insert_command_after_context(popup_method: Callable) -> void:
	var cmd_char: String = SVG.root_element.get_xnode(semi_selected_xid).\
			get_attribute("d").get_command(inner_selections.max()).command_char
	
	var command_picker = PathCommandPopup.instantiate()
	popup_method.call(command_picker)
	command_picker.path_command_picked.connect(insert_path_command_after_selection)
	match cmd_char.to_upper():
		"M": command_picker.disable_invalid(["M", "Z", "T"])
		"Z": command_picker.disable_invalid(["Z"])
		"L", "H", "V", "A": command_picker.disable_invalid(["S", "T"])
		"C", "S": command_picker.disable_invalid(["T"])
		"Q", "T": command_picker.disable_invalid(["S"])

func convert_selected_element_to(element_name: String) -> void:
	var xid := selected_xids[0]
	SVG.root_element.replace_xnode(xid,
			SVG.root_element.get_xnode(xid).get_replacement(element_name))
	SVG.queue_save()

func convert_selected_xnode_to(xnode_type: BasicXNode.NodeType) -> void:
	var xid := selected_xids[0]
	SVG.root_element.replace_xnode(xid,
			SVG.root_element.get_xnode(xid).get_replacement(xnode_type))
	SVG.queue_save()

func convert_selected_command_to(cmd_type: String) -> void:
	SVG.root_element.get_xnode(semi_selected_xid).get_attribute("d").convert_command(
			inner_selections[0], cmd_type)
	SVG.queue_save()
