## A <svg></svg> tag.
class_name TagSVG extends Tag

# The difference between attribute_changed() and resized() is that
# resized will emit even after unknown changes.
signal resized

signal child_attribute_changed(undo_redo: bool)
signal changed_unknown

signal tags_added(tids: Array[PackedInt32Array])
signal tags_deleted(tids: Array[PackedInt32Array])
signal tags_moved_in_parent(parent_tid: PackedInt32Array, old_indices: Array[int])
signal tags_moved_to(tid: PackedInt32Array, old_tids: Array[PackedInt32Array])
signal tag_layout_changed  # Emitted together with any of the above 4.

# This list is currently only used by the highlighter, so xmlns is here.
const known_attributes = ["width", "height", "viewBox", "xmlns"]

func _init() -> void:
	name = "svg"
	attributes = {
		"height": Attribute.new(Attribute.Type.UFLOAT, NAN),
		"width": Attribute.new(Attribute.Type.UFLOAT, NAN),
		"viewBox": AttributeViewbox.new(),
	}
	unknown_attributes.append(AttributeUnknown.new("xmlns", "http://www.w3.org/2000/svg"))
	super()

# Functions for getting the dimensions.
func get_width() -> float:
	if !is_nan(attributes.width.get_value()):
		return attributes.width.get_value()
	else:
		return attributes.viewBox.rect.size.x

func get_height() -> float:
	if !is_nan(attributes.height.get_value()):
		return attributes.height.get_value()
	else:
		return attributes.viewBox.rect.size.y

func get_size() -> Vector2:
	return Vector2(get_width(), get_height())

func get_viewbox() -> Rect2:
	if attributes.viewBox.get_value() != null:
		return attributes.viewBox.rect
	else:
		if is_nan(attributes.width.get_value()) or is_nan(attributes.height.get_value()):
			return Rect2(0, 0, 0, 0)
		else:
			return Rect2(0, 0, attributes.width.get_value(), attributes.height.get_value())


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
	tag_layout_changed.emit()

func replace_self(new_tag: Tag) -> void:
	var old_size := get_size()
	for attrib in attributes:
		attributes[attrib].set_value(new_tag.attributes[attrib].get_value(),
				Attribute.SyncMode.SILENT)
	
	unknown_attributes.clear()
	for attrib in new_tag.unknown_attributes:
		unknown_attributes.append(attrib)
	child_tags.clear()
	
	for tag in new_tag.child_tags:
		child_tags.append(tag)
	
	for tid in get_all_tids():
		get_by_tid(tid).attribute_changed.connect(emit_child_attribute_changed)
	
	changed_unknown.emit()
	if old_size != get_size():
		resized.emit()

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
	tag_layout_changed.emit()

# Moves tags up or down, not to an arbitrary position.
func move_tags_in_parent(tids: Array[PackedInt32Array], down: bool) -> void:
	if tids.is_empty():
		return
	
	tids = tids.duplicate()
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
	
	var tid_indices: Array[int] = []  # The last indices of the TIDs.
	for tid in tids:
		tid_indices.append(tid[-1])
	
	var parent_tag := get_by_tid(parent_tid)
	var parent_child_count := parent_tag.get_child_count()
	var old_indices: Array[int] = []
	for k in parent_child_count:
		old_indices.append(k)
	# Do the moving.
	if down:
		i = parent_child_count - 1
		while i >= 0:
			if not i in tid_indices and (i - 1) in tid_indices:
				old_indices.remove_at(i)
				var moved_i := i
				var moved_tag: Tag = parent_tag.child_tags.pop_at(i)
				while (i - 1) in tid_indices:
					i -= 1
				old_indices.insert(i, moved_i)
				parent_tag.child_tags.insert(i, moved_tag)
			i -= 1
	else:
		i = 0
		while i < parent_child_count:
			if not i in tid_indices and (i + 1) in tid_indices:
				old_indices.remove_at(i)
				var moved_i := i
				var moved_tag: Tag = parent_tag.child_tags.pop_at(i)
				while (i + 1) in tid_indices:
					i += 1
				old_indices.insert(i, moved_i)
				parent_tag.child_tags.insert(i, moved_tag)
			i += 1
	tags_moved_in_parent.emit(parent_tid, old_indices)
	tag_layout_changed.emit()

#func move_tags_to(tids: Array[PackedInt32Array], pos: PackedInt32Array) -> void:
	#pass  # TODO implement this.

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
	tag_layout_changed.emit()


func emit_child_attribute_changed(undo_redo: bool) -> void:
	child_attribute_changed.emit(undo_redo)

func emit_attribute_changed(undo_redo: bool) -> void:
	super(undo_redo)
	resized.emit()
