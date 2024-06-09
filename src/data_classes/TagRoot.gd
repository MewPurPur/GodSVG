class_name TagRoot extends TagSVG

signal attribute_somewhere_changed(xid: PackedInt32Array)
signal tags_added(xids: Array[PackedInt32Array])
signal tags_deleted(xids: Array[PackedInt32Array])
signal tags_moved_in_parent(parent_xid: PackedInt32Array, old_indices: Array[int])
signal tags_moved_to(xids: Array[PackedInt32Array], location: PackedInt32Array)
signal tag_layout_changed  # Emitted together with any of the above 5.


func get_all_tags() -> Array[Tag]:
	var tags: Array[Tag] = []
	var unchecked_tags: Array[Tag] = child_tags.duplicate()
	
	while not unchecked_tags.is_empty():
		var checked_tag: Tag = unchecked_tags.pop_back()
		for child_tag in checked_tag.child_tags:
			unchecked_tags.append(child_tag)
		tags.append(checked_tag)
	return tags

func get_tag(id: PackedInt32Array) -> Tag:
	var current_tag: Tag = self
	for idx in id:
		if idx >= current_tag.child_tags.size():
			return null
		current_tag = current_tag.child_tags[idx]
	return current_tag


func get_own_default(attribute_name: String) -> String:
	match attribute_name:
		"fill": return "black"
		"fill-opacity": return "1"
		"stroke": return "none"
		"stroke-opacity": return "1"
		"stroke-width": return "1"
		"stroke-linecap": return "butt"
		"stroke-linejoin": return "miter"
		_: return ""


func add_tag(new_tag: Tag, new_xid: PackedInt32Array) -> void:
	var parent_tag := get_tag(Utils.get_parent_xid(new_xid))
	new_tag.xid = new_xid
	new_tag.set_parent(parent_tag)
	parent_tag.child_tags.insert(new_xid[-1], new_tag)
	var new_xid_array: Array[PackedInt32Array] = [new_xid]
	tags_added.emit(new_xid_array)
	tag_layout_changed.emit()

func delete_tags(xids: Array[PackedInt32Array]) -> void:
	if xids.is_empty():
		return
	
	xids = Utils.filter_descendant_xids(xids)
	for id in xids:
		var parent_tag := get_tag(Utils.get_parent_xid(id))
		if is_instance_valid(parent_tag):
			var tag_idx := id[-1]
			if tag_idx < parent_tag.get_child_count():
				parent_tag.child_tags.remove_at(tag_idx)
	tags_deleted.emit(xids)
	tag_layout_changed.emit()

# Moves tags up or down, not to an arbitrary position.
func move_tags_in_parent(xids: Array[PackedInt32Array], down: bool) -> void:
	if xids.is_empty():
		return
	
	# For moving, all these tags must be direct children of the same parent.
	xids = Utils.filter_descendant_xids(xids)
	var depth := xids[0].size()
	var parent_xid := Utils.get_parent_xid(xids[0])
	for id in xids:
		if id.size() != depth or Utils.get_parent_xid(id) != parent_xid:
			return
	
	var xid_indices: Array[int] = []  # The last indices of the XIDs.
	for id in xids:
		xid_indices.append(id[-1])
	
	var parent_tag := get_tag(parent_xid)
	var parent_child_count := parent_tag.get_child_count()
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
				var moved_tag: Tag = parent_tag.child_tags.pop_at(i)
				while (i - 1) in xid_indices:
					i -= 1
				old_indices.insert(i, moved_i)
				parent_tag.child_tags.insert(i, moved_tag)
			i -= 1
	else:
		var i := 0
		while i < parent_child_count:
			if not i in xid_indices and (i + 1) in xid_indices:
				old_indices.remove_at(i)
				var moved_i := i
				var moved_tag: Tag = parent_tag.child_tags.pop_at(i)
				while (i + 1) in xid_indices:
					i += 1
				old_indices.insert(i, moved_i)
				parent_tag.child_tags.insert(i, moved_tag)
			i += 1
	# Check if indices were really changed after the operation.
	if old_indices != range(old_indices.size()):
		tags_moved_in_parent.emit(parent_xid, old_indices)
		tag_layout_changed.emit()

# Moves tags to an arbitrary position. The first moved tag will move to the location XID.
func move_tags_to(xids: Array[PackedInt32Array], location: PackedInt32Array) -> void:
	xids = Utils.filter_descendant_xids(xids)
	# A tag can't move deeper inside itself. Remove the descendants of the location.
	for i in range(xids.size() - 1, -1, -1):
		if Utils.is_xid_parent(xids[i], location):
			xids.remove_at(i)
	
	# Remove tags from their old locations.
	var xids_stored: Array[PackedInt32Array] = []
	var tags_stored: Array[Tag] = []
	for id in xids:
		# Shift the new location if tags before it were removed. A tag is "before"
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
		tags_stored.append(get_tag(Utils.get_parent_xid(id)).child_tags.pop_at(id[-1]))
	# Add the tags back in the new location.
	for tag in tags_stored:
		get_tag(Utils.get_parent_xid(location)).child_tags.insert(location[-1], tag)
	# Check if this actually chagned the layout.
	for id in xids_stored:
		if not Utils.are_xid_parents_same(id, location) or id[-1] < location[-1] or\
		id[-1] >= location[-1] + xids_stored.size():
			# If this condition is passed, then there was a layout change.
			tags_moved_to.emit(xids, location)
			tag_layout_changed.emit()
			return

# Duplicates tags and puts them below.
func duplicate_tags(xids: Array[PackedInt32Array]) -> void:
	if xids.is_empty():
		return
	
	xids = Utils.filter_descendant_xids(xids)
	var xids_added: Array[PackedInt32Array] = []
	# Used to offset previously added XIDs in xids_added after duplicating a tag before.
	var last_parent := PackedInt32Array([-1])  # Start with a XID that can't be matched.
	var added_to_last_parent := 0
	
	for id in xids:
		var new_tag := get_tag(id).duplicate()
		# Add the new tag.
		var new_xid := id.duplicate()
		new_xid[-1] += 1
		var parent_xid := Utils.get_parent_xid(new_xid)
		get_tag(parent_xid).child_tags.insert(new_xid[-1], new_tag)
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
	tags_added.emit(xids_added)
	tag_layout_changed.emit()

func replace_tag(id: PackedInt32Array, new_tag: Tag) -> void:
	get_tag(Utils.get_parent_xid(id)).child_tags[id[-1]] = new_tag
	tag_layout_changed.emit()

# Optimizes the SVG text in more ways than what formatting attributes allows.
# The return value is true if the SVG can be optimized, otherwise false.
# If apply_changes is false, you'll only get the return value.
func optimize(not_applied := false) -> bool:
	for tag in get_all_tags():
		match tag.name:
			"ellipse":
				# If possible, turn ellipses into circles.
				if tag.can_replace("circle"):
					if not_applied:
						return true
					replace_tag(tag.xid, tag.get_replacement("circle"))
			"line":
				# Turn lines into paths.
				if not_applied:
					return true
				replace_tag(tag.xid, tag.get_replacement("path"))
			"rect":
				# If possible, turn rounded rects into circles or ellipses.
				if tag.can_replace("circle"):
					if not_applied:
						return true
					replace_tag(tag.xid, tag.get_replacement("circle"))
				elif tag.can_replace("ellipse"):
					if not_applied:
						return true
					replace_tag(tag.xid, tag.get_replacement("ellipse"))
				elif tag.rx == 0:
					# If the rectangle is not rounded, turn it into a path.
					if not_applied:
						return true
					replace_tag(tag.xid, tag.get_replacement("path"))
			"path":
				var pathdata: AttributePathdata = tag.get_attribute("d")
				# Simplify A rotation to 0 degrees for circular arcs.
				for cmd_idx in pathdata.get_command_count():
					var command := pathdata.get_command(cmd_idx)
					var cmd_char := command.command_char
					if cmd_char in "Aa" and command.rx == command.ry and command.rot != 0:
						if not_applied:
							return true
						pathdata.set_command_property(cmd_idx, "rot", 0)
				# Replace L with H or V when possible.
				for cmd_idx in pathdata.get_command_count():
					var command := pathdata.get_command(cmd_idx)
					var cmd_char := command.command_char
					if cmd_char == "l":
						if command.x == 0:
							if not_applied:
								return true
							pathdata.convert_command(cmd_idx, "v")
						elif command.y == 0:
							if not_applied:
								return true
							pathdata.convert_command(cmd_idx, "h")
					elif cmd_char == "L":
						if command.x == command.start.x:
							if not_applied:
								return true
							pathdata.convert_command(cmd_idx, "V")
						elif command.y == command.start.y:
							if not_applied:
								return true
							pathdata.convert_command(cmd_idx, "H")
	return false
