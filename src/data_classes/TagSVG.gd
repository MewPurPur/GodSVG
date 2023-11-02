## A <svg></svg> tag.
class_name TagSVG extends Tag

signal child_attribute_changed
signal tags_added(tids: Array[PackedInt32Array])
signal tags_deleted(tids: Array[PackedInt32Array])
signal tags_moved(parent_tid: PackedInt32Array, new_indices: Array[int])
signal changed_unknown

const known_attributes = ["width", "height", "viewBox", "xmlns"]

func _init() -> void:
	name = "svg"
	attributes = {
		"height": Attribute.new(Attribute.Type.UFLOAT, null, 16.0),
		"width": Attribute.new(Attribute.Type.UFLOAT, null, 16.0),
		"viewBox": AttributeRect.new(null, Rect2(0, 0, 16, 16)),
	}
	super()


func get_all_tids() -> Array[PackedInt32Array]:
	var tids: Array[PackedInt32Array] = []
	var unchecked_tids: Array[PackedInt32Array] = []
	for idx in get_child_count():
		unchecked_tids.append(PackedInt32Array([idx]))
	
	while not unchecked_tids.is_empty():
		var checked_tid: PackedInt32Array = unchecked_tids.pop_back()
		var checked_tag: Tag = get_by_tid(checked_tid)
		for idx in checked_tag.get_child_count():
			var new_tid := checked_tid.duplicate()
			new_tid.append(idx)
			unchecked_tids.append(new_tid)
		tids.append(checked_tid)
	return tids

func get_by_tid(tid: PackedInt32Array) -> Tag:
	var current_tag: Tag = self
	for idx in tid:
		if idx > current_tag.child_tags.size() + 1:
			return null
		current_tag = current_tag.child_tags[idx]
	return current_tag


func add_tag(new_tag: Tag, new_tid: PackedInt32Array) -> void:
	var parent_tid := Utils.get_parent_tid(new_tid)
	get_by_tid(parent_tid).child_tags.insert(new_tid[-1], new_tag)
	new_tag.attribute_changed.connect(emit_child_attribute_changed)
	var new_tid_array: Array[PackedInt32Array] = [new_tid]
	tags_added.emit(new_tid_array)

func replace_self(new_tag: Tag) -> void:
	for attrib in attributes:
		attributes[attrib].set_value(new_tag.attributes[attrib].get_value(), false)
	child_tags.clear()
	
	for tag in new_tag.child_tags:
		child_tags.append(tag)
	
	for tid in get_all_tids():
		get_by_tid(tid).attribute_changed.connect(emit_child_attribute_changed)
	changed_unknown.emit()

func delete_tags(tids: Array[PackedInt32Array]) -> void:
	if tids.is_empty():
		return
	
	tids.sort_custom(Utils.compare_tids_r)
	# Linear scan to get the minimal set of TIDs to remove.
	var last_accepted := tids[0]
	var i := 1
	while i < tids.size():
		var tid := tids[i]
		if Utils.is_tid_parent(last_accepted, tid) or last_accepted == tid:
			tids.remove_at(i)
		else:
			last_accepted = tids[i]
			i += 1
	
	# Delete the remaining tags.
	for tid in tids:
		var parent_tid := Utils.get_parent_tid(tid)
		var parent_tag := get_by_tid(parent_tid)
		if parent_tag != null:
			var tag_idx := tid[-1]
			if tag_idx < parent_tag.get_child_count():
				parent_tag.child_tags.remove_at(tag_idx)
	tags_deleted.emit(tids)

# TODO
# Moves tags up or down, not to an arbitrary position.
func move_tags(tids: Array[PackedInt32Array], down: bool) -> void:
	if tids.is_empty():
		return
	
	tids.sort_custom(Utils.compare_tids_r)
	# Linear scan to get the minimal set of TIDs to move.
	var last_accepted := tids[0]
	var i := 1
	while i < tids.size():
		var tid := tids[i]
		if Utils.is_tid_parent(last_accepted, tid) or last_accepted == tid:
			tids.remove_at(i)
		else:
			last_accepted = tids[i]
			i += 1
	
	# For moving, all these tags must be direct children of the same parent.
	var depth := tids[0].size()
	var parent_tid := Utils.get_parent_tid(tids[0])
	for tid in tids:
		if tid.size() != depth or Utils.get_parent_tid(tid) != parent_tid:
			return
	
	# The set of tags on the bottom shouldn't be moved.
	var parent_tag := get_by_tid(parent_tid)
	var parent_child_count := parent_tag.get_child_count()
	if down:
		var unaffected := parent_child_count - 1
		tids.reverse()
		for tid_idx in tids.size():
			if tids[tid_idx][-1] == unaffected:
				unaffected -= 1
				tids.remove_at(tid_idx)
			else:
				break
	else:
		var unaffected := 0
		for tid_idx in tids.size():
			if tids[tid_idx][-1] == unaffected:
				unaffected += 1
				tids.remove_at(tid_idx)
			else:
				break
	
	var new_indices := range(parent_tag.get_child_count())
	# Do the moving.
	for tid in tids:
		var new_tid := tid.duplicate()
		new_tid[-1] += (1 if down else -1)
		var new_tag: Tag = parent_tag.child_tags.pop_at(tid[-1])
		parent_tag.child_tags.insert(new_tid[-1], new_tag)
	tags_moved.emit(parent_tid, new_indices)

func move_tags_to(tids: Array[PackedInt32Array], pos: PackedInt32Array) -> void:
	pass  # TODO implement this.

func duplicate_tags(tids: Array[PackedInt32Array]) -> void:
	if tids.is_empty():
		return
	
	tids.sort_custom(Utils.compare_tids_r)
	# Linear scan to get the minimal set of TIDs to duplicate.
	var last_accepted := tids[0]
	var i := 1
	while i < tids.size():
		var tid := tids[i]
		if Utils.is_tid_parent(last_accepted, tid) or last_accepted == tid:
			tids.remove_at(i)
		else:
			last_accepted = tids[i]
			i += 1
	
	var tids_added: Array[PackedInt32Array] = []
	# Used to offset previously added TIDs in tids_added after duplicating a tag before.
	var last_parent := PackedInt32Array([-1])  # Start with a TID that can't be matched.
	var added_to_last_parent := 0
	
	for tid in tids:
		var new_tag := get_by_tid(tid).create_duplicate()
		# Add the new tag.
		var new_tid := tid.duplicate()
		new_tid[-1] += 1
		var parent_tid := Utils.get_parent_tid(new_tid)
		get_by_tid(parent_tid).child_tags.insert(new_tid[-1], new_tag)
		new_tag.attribute_changed.connect(emit_child_attribute_changed)
		# Add the TID and offset the other ones from the same parent.
		var added_tid_idx := tids_added.size()
		tids_added.append(new_tid)
		if last_parent == parent_tid:
			added_to_last_parent += 1
		else:
			last_parent = parent_tid
			added_to_last_parent = 0
		for tid_idx in range(added_tid_idx - added_to_last_parent , added_tid_idx):
			tids_added[tid_idx][-1] += 1
	tags_added.emit(tids_added)


func emit_child_attribute_changed() -> void:
	child_attribute_changed.emit()
