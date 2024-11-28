class_name ElementRoot extends ElementSVG

@warning_ignore("unused_signal")
signal any_attribute_changed(xid: PackedInt32Array)

signal xnodes_added(xids: Array[PackedInt32Array])
signal xnodes_deleted(xids: Array[PackedInt32Array])
signal xnodes_moved_in_parent(parent_xid: PackedInt32Array, old_indices: Array[int])
signal xnodes_moved_to(xids: Array[PackedInt32Array], location: PackedInt32Array)
signal xnode_layout_changed  # Emitted together with any of the above 4.

@warning_ignore("unused_signal")
signal basic_xnode_text_changed(xid: PackedInt32Array)
@warning_ignore("unused_signal")
signal basic_xnode_rendered_text_changed(xid: PackedInt32Array)

var formatter: Formatter

func _init(new_formatter: Formatter = GlobalSettings.savedata.editor_formatter) -> void:
	super()
	xid = PackedInt32Array()
	root = self
	formatter = new_formatter

func get_xnode(loc: PackedInt32Array) -> XNode:
	var current_element: XNode = self
	for idx in loc:
		if idx >= current_element.get_child_count():
			return null
		current_element = current_element.get_child(idx)
	return current_element

func get_element_by_id(id: String) -> Element:
	for element in get_all_element_descendants():
		if element.get_attribute_value("id") == id:
			return element
	return null


func _get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"fill": return "black"
		"fill-opacity": return "1"
		"stroke": return "none"
		"stroke-opacity": return "1"
		"stroke-width": return "1"
		"stroke-linecap": return "butt"
		"stroke-linejoin": return "miter"
		_: return ""


func add_xnode(new_xnode: XNode, new_xid: PackedInt32Array) -> void:
	get_xnode(XIDUtils.get_parent_xid(new_xid)).insert_child(new_xid[-1], new_xnode)
	var new_xid_array: Array[PackedInt32Array] = [new_xid]
	xnodes_added.emit(new_xid_array)
	xnode_layout_changed.emit()

func delete_xnodes(xids: Array[PackedInt32Array]) -> void:
	if xids.is_empty():
		return
	
	xids = XIDUtils.filter_descendants(xids)
	for id in xids:
		get_xnode(id).parent.remove_child(id[-1])
	xnodes_deleted.emit(xids)
	xnode_layout_changed.emit()

# Moves elements up or down, not to an arbitrary position.
func move_xnodes_in_parent(xids: Array[PackedInt32Array], down: bool) -> void:
	if xids.is_empty():
		return
	
	# For moving, all these elements must be direct children of the same parent.
	xids = XIDUtils.filter_descendants(xids)
	var depth := xids[0].size()
	var parent_xid := XIDUtils.get_parent_xid(xids[0])
	for id in xids:
		if id.size() != depth or XIDUtils.get_parent_xid(id) != parent_xid:
			return
	
	var xid_indices: Array[int] = []  # The last indices of the XIDs.
	for id in xids:
		xid_indices.append(id[-1])
	
	var parent_element: Element = get_xnode(parent_xid)
	var parent_child_count := parent_element.get_child_count()
	var old_indices: Array[int] = []
	for i in parent_child_count:
		old_indices.append(i)
	# Do the moving.
	if down:
		var i := parent_child_count - 1
		while i >= 0:
			if not i in xid_indices and (i - 1) in xid_indices:
				old_indices.remove_at(i)
				var moved_i := i
				var moved_element := parent_element.pop_child(i)
				while (i - 1) in xid_indices:
					i -= 1
				old_indices.insert(i, moved_i)
				parent_element.insert_child(i, moved_element)
			i -= 1
	else:
		var i := 0
		while i < parent_child_count:
			if not i in xid_indices and (i + 1) in xid_indices:
				old_indices.remove_at(i)
				var moved_i := i
				var moved_element := parent_element.pop_child(i)
				while (i + 1) in xid_indices:
					i += 1
				old_indices.insert(i, moved_i)
				parent_element.insert_child(i, moved_element)
			i += 1
	# Check if indices were really changed after the operation.
	if old_indices != range(old_indices.size()):
		xnodes_moved_in_parent.emit(parent_xid, old_indices)
		xnode_layout_changed.emit()

# Moves elements to an arbitrary location.
# The first moved element will now be at the location XID.
func move_xnodes_to(xids: Array[PackedInt32Array], location: PackedInt32Array) -> void:
	xids = XIDUtils.filter_descendants(xids)
	# An element can't move deeper inside itself. Remove the descendants of the location.
	for i in range(xids.size() - 1, -1, -1):
		if XIDUtils.is_parent(xids[i], location):
			xids.remove_at(i)
	
	# Remove elements from their old locations.
	var xids_stored: Array[PackedInt32Array] = []
	var xnodes_stored: Array[XNode] = []
	for id in xids:
		# Shift the new location if elements before it were removed. An element is "before"
		# if it has the same parent as the new location, but is before that location.
		if id.size() <= location.size():
			var before := true
			for i in id.size() - 1:
				if id[i] != location[i]:
					before = false
					break
			if before and id[-1] < location[id.size() - 1]:
				location[id.size() - 1] -= 1
		xids_stored.append(id)
		xnodes_stored.append(get_xnode(XIDUtils.get_parent_xid(id)).pop_child(id[-1]))
	# Add the elements back in the new location.
	for xnode in xnodes_stored:
		get_xnode(XIDUtils.get_parent_xid(location)).insert_child(location[-1], xnode)
	# Check if this actually chagned the layout.
	for id in xids_stored:
		if not XIDUtils.are_siblings(id, location) or id[-1] < location[-1] or\
		id[-1] >= location[-1] + xids_stored.size():
			# If this condition is passed, then there was a layout change.
			xnodes_moved_to.emit(xids, location)
			xnode_layout_changed.emit()
			return

# Duplicates elements and puts them below.
func duplicate_xnodes(xids: Array[PackedInt32Array]) -> void:
	if xids.is_empty():
		return
	
	xids = XIDUtils.filter_descendants(xids)
	var xids_added: Array[PackedInt32Array] = []
	# Used to offset previously added XIDs in xids_added after duplicating an element before.
	var last_parent := PackedInt32Array([-1])  # Start with a XID that can't be matched.
	var added_to_last_parent := 0
	
	for id in xids:
		var new_xnode: XNode = get_xnode(id).duplicate()
		# Add the new element.
		var new_xid := id.duplicate()
		new_xid[-1] += 1
		var parent_xid := XIDUtils.get_parent_xid(new_xid)
		get_xnode(parent_xid).insert_child(new_xid[-1], new_xnode)
		# Add the XID and offset the other ones from the same parent.
		var added_xid_idx := xids_added.size()
		xids_added.append(new_xid)
		if last_parent == parent_xid:
			added_to_last_parent += 1
		else:
			last_parent = parent_xid
			added_to_last_parent = 0
		for xid_idx in range(added_xid_idx - added_to_last_parent , added_xid_idx):
			xids_added[xid_idx][-1] += 1
	xnodes_added.emit(xids_added)
	xnode_layout_changed.emit()

func replace_xnode(id: PackedInt32Array, new_xnode: XNode) -> void:
	get_xnode(id).parent.replace_child(id[-1], new_xnode)
	xnode_layout_changed.emit()


# Optimizes the SVG text in more ways than what formatting attributes allows.
# The return value is true if the SVG can be optimized, otherwise false.
# If apply_changes is false, you'll only get the return value.
func optimize(not_applied := false) -> bool:
	for xnode in get_all_xnode_descendants():
		if not xnode.is_element():
			var basic_xnode: BasicXNode = xnode
			var xids_to_remove: Array[PackedInt32Array] = []
			if basic_xnode.get_type() in [BasicXNode.NodeType.COMMENT,
			BasicXNode.NodeType.UNKNOWN]:
				if not_applied:
					return true
				xids_to_remove.append(xnode.xid)
			else:
				continue  # The logic for removing these safely is more particular.
			delete_xnodes(xids_to_remove)
			continue
		
		var element: Element = xnode
		match element.name:
			"ellipse":
				# If possible, turn ellipses into circles.
				if element.can_replace("circle"):
					if not_applied:
						return true
					replace_xnode(element.xid, element.get_replacement("circle"))
			"rect":
				# If possible, turn rounded rects into circles or ellipses.
				if element.can_replace("circle"):
					if not_applied:
						return true
					replace_xnode(element.xid, element.get_replacement("circle"))
				elif element.can_replace("ellipse"):
					if not_applied:
						return true
					replace_xnode(element.xid, element.get_replacement("ellipse"))
				elif element.get_rx() == 0:
					# If the rectangle is not rounded, turn it into a path.
					if not_applied:
						return true
					replace_xnode(element.xid, element.get_replacement("path"))
			"polygon", "line", "polyline":
				if not_applied:
					return true
				replace_xnode(element.xid, element.get_replacement("path"))
			"path":
				var pathdata: AttributePathdata = element.get_attribute("d")
				# Simplify A rotation to 0 degrees for circular arcs.
				for cmd_idx in pathdata.get_command_count():
					var command := pathdata.get_command(cmd_idx)
					var cmd_char := command.command_char
					if cmd_char in "Aa" and command.rx == command.ry and command.rot != 0:
						if not_applied:
							return true
						pathdata.set_command_property(cmd_idx, "rot", 0)
				
				# Replace L with H or V when possible.
				var conversion_indices := PackedInt32Array()
				var conversion_cmd_chars := PackedStringArray()
				
				for cmd_idx in pathdata.get_command_count():
					var command := pathdata.get_command(cmd_idx)
					var cmd_char := command.command_char
					
					if cmd_char == "l":
						if command.x == 0:
							if not_applied:
								return true
							conversion_indices.append(cmd_idx)
							conversion_cmd_chars.append("v")
						elif command.y == 0:
							if not_applied:
								return true
							conversion_indices.append(cmd_idx)
							conversion_cmd_chars.append("h")
					elif cmd_char == "L":
						if command.x == command.get_start_coords().x:
							if not_applied:
								return true
							conversion_indices.append(cmd_idx)
							conversion_cmd_chars.append("V")
						elif command.y == command.get_start_coords().y:
							if not_applied:
								return true
							conversion_indices.append(cmd_idx)
							conversion_cmd_chars.append("H")
				pathdata.convert_commands_optimized(conversion_indices, conversion_cmd_chars)
	
	return false
