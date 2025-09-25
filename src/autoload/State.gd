## An autoload that handles information that's session-wide, but not saved.
extends Node

const OptionsDialogScene = preload("res://src/ui_widgets/options_dialog.tscn")
const PathCommandPopupScene = preload("res://src/ui_widgets/path_popup.tscn")

signal any_attribute_changed(xid: PackedInt32Array)
signal xnode_layout_changed  # Emitted together with any of the above 4.
signal basic_xnode_text_changed
signal basic_xnode_rendered_text_changed
signal svg_unknown_change

signal parsing_finished
signal svg_edited
signal svg_switched_to_another
signal svg_changed

# "unstable_markup" is the current state, which might have errors (i.e., while using the code editor).
# "stable_markup" is the last state without errors, and is what the editor is synced to.
# These both differ from the TabData svg_text, which is the state as saved to file,
# which doesn't happen while dragging handles or typing in the code editor for example.
var last_parse_error: SVGParser.ParseError
var unstable_markup := ""
var stable_editor_markup := ""
var stable_export_markup := ""
var root_element := ElementRoot.new()

func _enter_tree() -> void:
	get_window().mouse_exited.connect(clear_all_hovered)
	svg_unknown_change.connect(clear_all_selections)
	svg_switched_to_another.connect(clear_all_selections)
	
	xnode_layout_changed.connect(_on_svg_edited)
	any_attribute_changed.connect(_on_svg_edited.unbind(1))
	basic_xnode_text_changed.connect(_on_svg_edited)
	basic_xnode_rendered_text_changed.connect(_on_svg_edited)
	svg_unknown_change.connect(_on_svg_edited)
	
	svg_edited.connect(svg_changed.emit)
	svg_switched_to_another.connect(svg_changed.emit)
	
	Configs.active_tab_changed.connect(setup_from_tab)
	setup_from_tab.call_deferred()  # Let everything load before emitting signals.
	
	# Need to wait a frame so the import warnings panel becomes available.
	await get_tree().process_frame
	FileUtils.apply_svgs_from_paths(OS.get_cmdline_args(), false)


func _on_svg_edited() -> void:
	stable_editor_markup = SVGParser.root_to_editor_markup(root_element)
	stable_export_markup = SVGParser.root_to_export_markup(root_element)
	svg_edited.emit()

func save_svg() -> void:
	if stable_export_markup.is_empty():
		Configs.savedata.get_active_tab().set_svg_text(unstable_markup)
	else:
		unstable_markup = ""
		Configs.savedata.get_active_tab().set_svg_text(stable_export_markup)


func sync_stable_editor_markup() -> void:
	if not stable_editor_markup.is_empty():
		apply_markup(stable_editor_markup, true)

func apply_markup(markup: String, is_edit: bool) -> void:
	var svg_parse_result := SVGParser.markup_to_root(markup)
	last_parse_error = svg_parse_result.error
	
	if last_parse_error == SVGParser.ParseError.OK:
		root_element = svg_parse_result.svg
		stable_editor_markup = SVGParser.root_to_editor_markup(root_element)
		stable_export_markup = SVGParser.root_to_export_markup(root_element)
		parsing_finished.emit()
		
		root_element.xnodes_added.connect(_on_xnodes_added)
		root_element.xnodes_deleted.connect(_on_xnodes_deleted)
		root_element.xnodes_moved_in_parent.connect(_on_xnodes_moved_in_parent)
		root_element.xnodes_moved_to.connect(_on_xnodes_moved_to)
		
		root_element.xnodes_added.connect(xnode_layout_changed.emit.unbind(1))
		root_element.xnodes_deleted.connect(xnode_layout_changed.emit.unbind(1))
		root_element.xnodes_moved_in_parent.connect(xnode_layout_changed.emit.unbind(2))
		root_element.xnodes_moved_to.connect(xnode_layout_changed.emit.unbind(2))
		root_element.miscellaneous_xnode_layout_change.connect(xnode_layout_changed.emit)
		root_element.any_attribute_changed.connect(any_attribute_changed.emit)
		root_element.basic_xnode_text_changed.connect(basic_xnode_text_changed.emit)
		root_element.basic_xnode_rendered_text_changed.connect(basic_xnode_rendered_text_changed.emit)
		
		(svg_unknown_change if is_edit else svg_switched_to_another).emit()
	else:
		unstable_markup = markup
		if stable_editor_markup.is_empty():
			root_element = ElementRoot.new()
			parsing_finished.emit()
			(svg_edited if is_edit else svg_switched_to_another).emit()
		else:
			parsing_finished.emit()

func setup_from_tab() -> void:
	var active_tab := Configs.savedata.get_active_tab()
	var tab_text := active_tab.get_svg_text()
	
	if not tab_text.is_empty():
		stable_editor_markup = ""
		stable_export_markup = ""
		apply_markup(tab_text, false)
		return
	
	apply_markup(TabData.DEFAULT_SVG, false)
	if not active_tab.empty_unsaved and FileAccess.file_exists(active_tab.get_edited_file_path()):
		var user_facing_path := active_tab.svg_file_path
		var message := Translator.translate("The last edited state of this tab could not be found.")
		
		var options_dialog := OptionsDialogScene.instantiate()
		HandlerGUI.add_dialog(options_dialog)
		if user_facing_path.is_empty() or not FileAccess.file_exists(user_facing_path):
			options_dialog.setup(Translator.translate("Alert!"), message)
			options_dialog.add_option(Translator.translate("Close tab"), Configs.savedata.remove_active_tab)
		else:
			options_dialog.setup(Translator.translate("Alert!"), message + "\n\n" + Translator.translate(
					"The tab is bound to the file path {file_path}. Do you want to restore the SVG from this path?").format({"file_path": user_facing_path}))
			options_dialog.add_option(Translator.translate("Close tab"), Configs.savedata.remove_active_tab)
			options_dialog.add_option(Translator.translate("Restore"), FileUtils.reset_svg, true)
	save_svg()


func optimize() -> void:
	root_element.optimize(Configs.savedata.default_optimizer)
	save_svg()

func get_export_text() -> String:
	return unstable_markup if stable_export_markup.is_empty() else stable_export_markup


signal hover_changed
signal selection_changed

signal requested_scroll_to_selection(xid: PackedInt32Array, inner_idx: int)

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
var is_xnode_selection_dragged := false
var proposed_drop_xid := PackedInt32Array()

signal xnode_dragging_state_changed
signal proposed_drop_changed

func set_selection_dragged(new_value: bool) -> void:
	if is_xnode_selection_dragged != new_value:
		is_xnode_selection_dragged = new_value
		xnode_dragging_state_changed.emit()

func set_proposed_drop_xid(xid: PackedInt32Array) -> void:
	if proposed_drop_xid != xid:
		proposed_drop_xid = xid.duplicate()
		proposed_drop_changed.emit()

func clear_proposed_drop_xid() -> void:
	if not proposed_drop_xid.is_empty():
		proposed_drop_xid.clear()
		proposed_drop_changed.emit()


# Override the selected elements with a single new selected element.
# If inner_idx is given, this will be an inner selection.
func normal_select(xid: PackedInt32Array, inner_idx := -1) -> void:
	if xid.is_empty():
		return
	
	if inner_idx == -1:
		var old_selected_xids := selected_xids.duplicate()
		if not semi_selected_xid.is_empty():
			_clear_inner_selection_no_signal()
		if selected_xids.size() == 1 and selected_xids[0] == xid:
			return
		selection_pivot_xid = xid.duplicate()
		selected_xids = [xid.duplicate()]
		if XIDUtils.are_xid_lists_same(old_selected_xids, selected_xids):
			return
	else:
		var old_inner_selections := inner_selections.duplicate()
		var old_semi_selected_xid := semi_selected_xid.duplicate()
		xid = xid.duplicate()
		_clear_selection_no_signal()
		
		if semi_selected_xid == xid and inner_selections.size() == 1 and inner_selections[0] == inner_idx:
			return
		
		semi_selected_xid = xid.duplicate()
		inner_selection_pivot = inner_idx
		inner_selections = [inner_idx]
		if inner_selections == old_inner_selections and old_semi_selected_xid == xid:
			return
	
	selection_changed.emit()

# If the element was selected, unselect it. If it was unselected, select it.
# If inner_idx is given, this will be an inner selection.
func ctrl_select(xid: PackedInt32Array, inner_idx := -1) -> void:
	if xid.is_empty():
		return
	
	if inner_idx == -1:
		_clear_inner_selection_no_signal()
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
			_clear_selection_no_signal()
			
			var idx_idx := inner_selections.find(inner_idx)
			if idx_idx == -1:
				inner_selection_pivot = inner_idx
				inner_selections.append(inner_idx)
			else:
				inner_selections.remove_at(idx_idx)
				if inner_selections.is_empty():
					inner_selection_pivot = -1
	
	selection_changed.emit()

# Select all elements between the element and the last selected element (pivot).
# Similarly for inner selections if inner_idx is given, but without tree logic.
func shift_select(xid: PackedInt32Array, inner_idx := -1) -> void:
	if xid.is_empty():
		return
	
	if inner_idx == -1:
		if xid == selection_pivot_xid:
			return
		
		if selection_pivot_xid.is_empty():
			normal_select(xid, inner_idx)
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
		
		if XIDUtils.are_xid_lists_same(selected_xids, old_selected_xids):
			return
	
	else:
		if inner_selection_pivot == -1 or xid != semi_selected_xid:
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
	_clear_inner_selection_no_signal()
	var xnode_list: Array[XNode] = root_element.get_all_xnode_descendants()
	var xid_list: Array = xnode_list.map(
			func(xnode: XNode) -> PackedInt32Array: return xnode.xid)
	# The order might not be the same, so ensure like this.
	if XIDUtils.are_xid_lists_same(xid_list, selected_xids):
		return
	
	for xid in xid_list:
		if not xid in selected_xids:
			selected_xids.append(xid)
	selection_changed.emit()


# Clear the selected elements.
func clear_selection() -> void:
	if not selected_xids.is_empty():
		_clear_selection_no_signal()
		selection_changed.emit()

func _clear_selection_no_signal() -> void:
	selected_xids.clear()
	selection_pivot_xid.clear()

# Clear the inner selection.
func clear_inner_selection() -> void:
	if not inner_selections.is_empty() or not semi_selected_xid.is_empty():
		_clear_inner_selection_no_signal()
		selection_changed.emit()

func _clear_inner_selection_no_signal() -> void:
	inner_selections.clear()
	semi_selected_xid.clear()
	inner_selection_pivot = -1

# Clear the selected elements or the inner selection.
func clear_all_selections() -> void:
	if not inner_selections.is_empty() or not semi_selected_xid.is_empty() or not selected_xids.is_empty():
		_clear_selection_no_signal()
		_clear_inner_selection_no_signal()
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
		semi_hovered_xid.clear()
		hover_changed.emit()

func clear_all_hovered() -> void:
	if not hovered_xid.is_empty() or inner_hovered != -1:
		hovered_xid.clear()
		inner_hovered = -1
		semi_hovered_xid.clear()
		hover_changed.emit()

# Returns whether the given element or inner editor is hovered.
func is_hovered(xid: PackedInt32Array, inner_idx := -1, propagate := false) -> bool:
	if propagate:
		if XIDUtils.is_ancestor_or_self(hovered_xid, xid):
			return true
		if inner_idx == -1:
			return false
		return inner_hovered == inner_idx and semi_hovered_xid == xid
	if inner_idx == -1:
		return hovered_xid == xid
	return inner_hovered == inner_idx and semi_hovered_xid == xid

# Returns whether the given element or inner editor is selected.
func is_selected(xid: PackedInt32Array, inner_idx := -1, propagate := false) -> bool:
	if propagate:
		for selected_xid in selected_xids:
			if XIDUtils.is_ancestor_or_self(selected_xid, xid):
				return true
		if inner_idx == -1:
			return false
		return semi_selected_xid == xid and inner_idx in inner_selections
	if inner_idx == -1:
		return xid in selected_xids
	return semi_selected_xid == xid and inner_idx in inner_selections

# Returns whether the selection matches a subpath.
func is_selection_subpath() -> bool:
	if semi_selected_xid.is_empty() or inner_selections.is_empty():
		return false

	var element_ref := root_element.get_xnode(semi_selected_xid)
	if not element_ref is ElementPath:
		return false

	var subpath: Vector2i = element_ref.get_attribute("d").get_subpath(inner_selections[0])
	for i in range(subpath.x, subpath.y):
		if not i in inner_selections:
			return false
	return true


func _on_xnodes_added(xids: Array[PackedInt32Array]) -> void:
	selected_xids = xids.duplicate()
	selection_pivot_xid = xids[-1]
	selection_changed.emit()

# If selected elements were deleted, remove them from the list of selected elements.
func _on_xnodes_deleted(xids: Array[PackedInt32Array]) -> void:
	xids = xids.duplicate()  # For some reason, it breaks without this.
	var old_selected_xids := selected_xids.duplicate()
	for deleted_xid in xids:
		for i in range(selected_xids.size() - 1, -1, -1):
			var xid := selected_xids[i]
			if XIDUtils.is_ancestor_or_self(deleted_xid, xid):
				selected_xids.remove_at(i)
	if not XIDUtils.are_xid_lists_same(old_selected_xids, selected_xids):
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
			if XIDUtils.is_ancestor_or_self(old_moved_xid, xid):
				var new_selected_xid := xid.duplicate()
				new_selected_xid[parent_xid.size()] = index_idx
				xids_to_unselect.append(xid)
				xids_to_select.append(new_selected_xid)
	for xid in xids_to_unselect:
		selected_xids.erase(xid)
	selected_xids += xids_to_select
	
	if not XIDUtils.are_xid_lists_same(old_selected_xids, selected_xids):
		selection_changed.emit()

# If selected elements were moved to a location, change the XIDs and their children.
func _on_xnodes_moved_to(xids: Array[PackedInt32Array], location: PackedInt32Array) -> void:
	xids = xids.duplicate()
	var new_selected_xids: Array[PackedInt32Array] = []
	for moved_idx in xids.size():
		var moved_xid := xids[moved_idx]
		for xid in selected_xids:
			if XIDUtils.is_ancestor_or_self(moved_xid, xid):
				var new_location := XIDUtils.get_parent_xid(location)
				new_location.append(moved_idx + location[-1])
				for ii in range(moved_xid.size(), xid.size()):
					new_location.append(xid[ii])
				new_selected_xids.append(new_location)
	if not XIDUtils.are_xid_lists_same(selected_xids, new_selected_xids):
		selected_xids = new_selected_xids
		selection_changed.emit()


# Path commands using keys.
func respond_to_key_input(path_cmd_char: String) -> void:
	if inner_selections.is_empty():
		# If a single path element is selected, add the new command at the end.
		if selected_xids.size() == 1:
			var xnode_ref := root_element.get_xnode(selected_xids[0])
			if xnode_ref is ElementPath:
				var path_attrib: AttributePathdata = xnode_ref.get_attribute("d")
				var path_cmd_count := path_attrib.get_command_count()
				# Z after a Z is syntactically invalid.
				if (path_cmd_count == 0 and not path_cmd_char in "Mm") or (path_cmd_char in "Zz" and path_cmd_count > 0 and\
				path_attrib.get_command(path_cmd_count - 1) is PathCommand.CloseCommand):
					return
				path_attrib.insert_command(path_cmd_count, path_cmd_char, Vector2.ZERO)
				normal_select(selected_xids[0], path_cmd_count)
				handle_added.emit()
	else:
		# If path commands are selected, insert after the last one.
		var xnode_ref := root_element.get_xnode(semi_selected_xid)
		if xnode_ref is ElementPath:
			var path_attrib: AttributePathdata = xnode_ref.get_attribute("d")
			var last_selection: int = inner_selections.max()
			# Z after a Z is syntactically invalid.
			if path_cmd_char in "Zz" and (path_attrib.get_command(last_selection) is PathCommand.CloseCommand or\
			(path_attrib.get_command_count() > last_selection + 1 and path_attrib.get_command(last_selection + 1) is PathCommand.CloseCommand)):
				return
			path_attrib.insert_command(last_selection + 1, path_cmd_char, Vector2.ZERO)
			normal_select(semi_selected_xid, last_selection + 1)
			handle_added.emit()


# Operations on selected elements.

func delete_selected() -> void:
	if not selected_xids.is_empty():
		root_element.delete_xnodes(selected_xids)
		save_svg()
	elif not inner_selections.is_empty() and not semi_selected_xid.is_empty():
		inner_selections.sort()
		inner_selections.reverse()
		var element_ref := root_element.get_xnode(semi_selected_xid)
		match element_ref.name:
			"path": element_ref.get_attribute("d").delete_commands(inner_selections)
			"polygon", "polyline":
				var indices_to_delete := PackedInt64Array()
				for idx in inner_selections:
					indices_to_delete.append(idx * 2)
					indices_to_delete.append(idx * 2 + 1)
				element_ref.get_attribute("points").delete_elements(indices_to_delete)
		clear_inner_selection()
		clear_inner_hovered()
		save_svg()

func move_up_selected() -> void:
	_move_selected(false)

func move_down_selected() -> void:
	_move_selected(true)

func _move_selected(down: bool) -> void:
	if not selected_xids.is_empty():
		root_element.move_xnodes_in_parent(selected_xids, down)
	elif not semi_selected_xid.is_empty():
		var xnode := root_element.get_xnode(semi_selected_xid)
		if not xnode is ElementPath:
			return
		# TODO
		#xnode.get_attribute("d").move_subpath(inner_selections[0], down)
	save_svg()

func view_in_inspector(xid: PackedInt32Array, inner_index := -1) -> void:
	if xid.is_empty():
		return
	requested_scroll_to_selection.emit(xid, inner_index)

func duplicate_selected() -> void:
	root_element.duplicate_xnodes(selected_xids)
	save_svg()

func insert_path_command_after_selection(new_command: String) -> void:
	var path_attrib: AttributePathdata = root_element.get_xnode(
			semi_selected_xid).get_attribute("d")
	var last_selection: int = inner_selections.max()
	# Z after a Z is syntactically invalid.
	if path_attrib.get_command(last_selection) is PathCommand.CloseCommand and new_command in "Zz":
		return
	path_attrib.insert_command(last_selection + 1, new_command)
	normal_select(semi_selected_xid, last_selection + 1)
	save_svg()

func insert_point_after_selection() -> void:
	var element_ref: Element = root_element.get_xnode(semi_selected_xid)
	var last_selection_next: int = inner_selections.max() + 1
	element_ref.get_attribute("points").insert_element(last_selection_next * 2, 0.0)
	element_ref.get_attribute("points").insert_element(last_selection_next * 2, 0.0)
	normal_select(semi_selected_xid, last_selection_next)
	save_svg()


func get_selection_context(popup_method: Callable, context: Utils.LayoutPart) -> ContextPopup:
	var btn_arr: Array[Button] = []
	
	if not selected_xids.is_empty():
		var filtered_xids := XIDUtils.filter_descendants(selected_xids)
		var can_move_down := true
		var can_move_up := true
		for base_xid in filtered_xids:
			if not XIDUtils.are_siblings_or_same(base_xid, filtered_xids[0]):
				can_move_down = false
				can_move_up = false
				break
		
		if can_move_up or can_move_down:
			can_move_down = false
			can_move_up = false
			var parent_xid := XIDUtils.get_parent_xid(filtered_xids[0])
			var filtered_count := filtered_xids.size()
			var parent_child_count: int = root_element.get_xnode(parent_xid).get_child_count()
			for base_xid in filtered_xids:
				if not can_move_up and base_xid[-1] >= filtered_count:
					can_move_up = true
				if not can_move_down and base_xid[-1] < parent_child_count - filtered_count:
					can_move_down = true
		if context == Utils.LayoutPart.VIEWPORT:
			btn_arr.append(ContextPopup.create_button(Translator.translate("View in Inspector"),
					view_in_inspector.bind(selected_xids[0]), false,
					load("res://assets/icons/Inspector.svg")))
		
		btn_arr.append(ContextPopup.create_shortcut_button("duplicate"))
		
		var xnode := root_element.get_xnode(selected_xids[0])
		if selected_xids.size() == 1 and (not xnode.is_element() or (xnode.is_element() and not xnode.possible_conversions.is_empty())):
			btn_arr.append(ContextPopup.create_button(Translator.translate("Convert To"),
					popup_convert_to_context.bind(popup_method), false,
					load("res://assets/icons/Reload.svg")))
		
		if can_move_up:
			btn_arr.append(ContextPopup.create_shortcut_button("move_up"))
		if can_move_down:
			btn_arr.append(ContextPopup.create_shortcut_button("move_down"))
		
		btn_arr.append(ContextPopup.create_shortcut_button("delete"))
	
	elif not inner_selections.is_empty() and not semi_selected_xid.is_empty():
		var element_ref := root_element.get_xnode(semi_selected_xid)
		
		if context == Utils.LayoutPart.VIEWPORT:
			var inner_idx := inner_selections[0]
			for idx in inner_selections:
				if idx < inner_idx:
					inner_idx = idx
			btn_arr.append(ContextPopup.create_button(Translator.translate("View in Inspector"),
					view_in_inspector.bind(semi_selected_xid, inner_idx), false,
					load("res://assets/icons/Inspector.svg")))
		match element_ref.name:
			"path":
				if inner_selections.size() == 1:
					btn_arr.append(ContextPopup.create_button(Translator.translate("Insert After"),
							popup_insert_command_after_context.bind(popup_method), false,
							load("res://assets/icons/Plus.svg")))
					if inner_selections[0] != 0 or element_ref.get_attribute("d").get_command(0).command_char != "M":
						btn_arr.append(ContextPopup.create_button(Translator.translate("Convert To"),
								popup_convert_to_context.bind(popup_method), false,
								load("res://assets/icons/Reload.svg")))
				if is_selection_subpath():
					# TODO
					var can_move_up := false
					var can_move_down := false
					if can_move_up:
						btn_arr.append(ContextPopup.create_shortcut_button("move_up"))
						# , "Move Subpath Up"
					if can_move_down:
						btn_arr.append(ContextPopup.create_shortcut_button("move_down"))
						# , "Move Subpath Down"
			"polygon", "polyline":
				if inner_selections.size() == 1:
					btn_arr.append(ContextPopup.create_button(Translator.translate("Insert After"),
							insert_point_after_selection, false, load("res://assets/icons/Plus.svg")))
		
		btn_arr.append(ContextPopup.create_shortcut_button("delete"))
	
	var element_context := ContextPopup.new()
	element_context.setup(btn_arr, true)
	return element_context

func popup_convert_to_context(popup_method: Callable) -> void:
	# The "Convert To" context popup.
	if not selected_xids.is_empty():
		var btn_arr: Array[Button] = []
		var xnode := root_element.get_xnode(selected_xids[0])
		if not xnode.is_element():
			for xnode_type in xnode.get_possible_conversions():
				var btn := ContextPopup.create_button(BasicXNode.get_type_string(xnode_type),
						convert_selected_xnode_to.bind(xnode_type), false, DB.get_xnode_icon(xnode_type))
				btn.add_theme_font_override("font", ThemeUtils.mono_font)
				btn_arr.append(btn)
		else:
			for element_name in xnode.possible_conversions:
				var btn := ContextPopup.create_button(element_name,
						convert_selected_element_to.bind(element_name),
						not xnode.can_replace(element_name), DB.get_element_icon(element_name))
				btn.add_theme_font_override("font", ThemeUtils.mono_font)
				btn_arr.append(btn)
		var context_popup := ContextPopup.new()
		context_popup.setup(btn_arr, true)
		popup_method.call(context_popup)
	elif not inner_selections.is_empty() and not semi_selected_xid.is_empty():
		var path_attrib: AttributePathdata = root_element.get_xnode(semi_selected_xid).get_attribute("d")
		var selection_idx: int = inner_selections.max()
		var cmd_char := path_attrib.get_command(selection_idx).command_char
		
		var command_picker := PathCommandPopupScene.instantiate()
		popup_method.call(command_picker)
		command_picker.force_relativity(Utils.is_string_lower(cmd_char))
		
		var cmd_char_upper := cmd_char.to_upper()
		var disabled_commands: PackedStringArray
		if selection_idx == 0:
			disabled_commands = PackedStringArray(["L", "H", "V", "A", "Z", "Q", "T", "C", "S"])
		else:
			disabled_commands = PackedStringArray([cmd_char.to_upper()])
			if cmd_char_upper != "Z" and path_attrib.get_command_count() > selection_idx + 1 and\
			path_attrib.get_command(selection_idx + 1).command_char.to_upper() == "Z":
				disabled_commands.append("Z")
		
		command_picker.mark_invalid(PackedStringArray(), disabled_commands)
		command_picker.path_command_picked.connect(convert_selected_command_to)

func popup_insert_command_after_context(popup_method: Callable) -> void:
	var path_attrib: AttributePathdata = root_element.get_xnode(semi_selected_xid).get_attribute("d")
	var selection_idx: int = inner_selections.max()
	var cmd_char := path_attrib.get_command(selection_idx).command_char
	
	var command_picker := PathCommandPopupScene.instantiate()
	popup_method.call(command_picker)
	command_picker.path_command_picked.connect(insert_path_command_after_selection)
	# Disable invalid commands. Z is syntactically invalid, so disallow it even harder.
	var warned_commands: PackedStringArray
	var disabled_commands: PackedStringArray
	# S commands are deliberately warned against in most cases, even though there is some sense in using them without a C or S command before them.
	# Same for T commands in most cases, even though there is a notion of letting them determine the next shorthand quadratic curve.
	match cmd_char.to_upper():
		"M": warned_commands = PackedStringArray(["M", "Z", "S", "T"])
		"L", "H", "V", "A": warned_commands = PackedStringArray(["S", "T"])
		"C", "S": warned_commands = PackedStringArray(["T"])
		"Q", "T": warned_commands = PackedStringArray(["S"])
	
	if (cmd_char in "Zz") or (path_attrib.get_command_count() > selection_idx + 1 and path_attrib.get_command(selection_idx + 1).command_char.to_upper() == "Z"):
		disabled_commands = PackedStringArray(["Z"])
	
	command_picker.mark_invalid(warned_commands, disabled_commands)

func convert_selected_element_to(element_name: String) -> void:
	var xid := selected_xids[0]
	root_element.replace_xnode(xid, root_element.get_xnode(xid).get_replacement(element_name))
	save_svg()

func convert_selected_xnode_to(xnode_type: BasicXNode.NodeType) -> void:
	var xid := selected_xids[0]
	root_element.replace_xnode(xid, root_element.get_xnode(xid).get_replacement(xnode_type))
	save_svg()

func convert_selected_command_to(cmd_type: String) -> void:
	root_element.get_xnode(semi_selected_xid).get_attribute("d").convert_command(inner_selections[0], cmd_type)
	save_svg()
