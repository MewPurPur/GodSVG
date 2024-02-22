## A <svg></svg> tag.
class_name TagSVG extends Tag

var width: float
var height: float
var viewbox: Rect2
var canvas_transform: Transform2D

# The difference between attribute_changed() and resized() is that
# resized() will emit even after unknown changes.
signal resized

signal child_attribute_changed(undo_redo: bool)
signal changed_unknown

signal tags_added(tids: Array[PackedInt32Array])
signal tags_deleted(tids: Array[PackedInt32Array])
signal tags_moved_in_parent(parent_tid: PackedInt32Array, old_indices: Array[int])
signal tags_moved_to(tids: Array[PackedInt32Array], location: PackedInt32Array)
signal tag_changed(tid: PackedInt32Array)
signal tag_layout_changed  # Emitted together with any of the above 5.

# This list is currently only used by the highlighter, so xmlns is here.
const known_attributes = ["width", "height", "viewBox", "xmlns"]
const name = "svg"

func _init() -> void:
	attributes = {
		"height": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, ""),
		"width": AttributeNumeric.new(AttributeNumeric.Mode.UFLOAT, ""),
		"viewBox": AttributeList.new(),
	}
	unknown_attributes.append(AttributeUnknown.new("xmlns", "http://www.w3.org/2000/svg"))
	attribute_changed.connect(update_cache.unbind(1))
	changed_unknown.connect(update_cache)
	update_cache()
	super()

func update_cache() -> void:
	# Cache width.
	if is_finite(attributes.width.get_num()):
		width = attributes.width.get_num()
	else:
		width = attributes.viewBox.get_list_element(2)
	# Cache height.
	if is_finite(attributes.height.get_num()):
		height = attributes.height.get_num()
	else:
		height = attributes.viewBox.get_list_element(3)
	# Cache viewbox.
	if attributes.viewBox.get_list_size() >= 4:
		viewbox = Rect2(attributes.viewBox.get_list_element(0),
				attributes.viewBox.get_list_element(1),
				attributes.viewBox.get_list_element(2),
				attributes.viewBox.get_list_element(3))
	else:
		if is_finite(attributes.width.get_num()) and is_finite(attributes.height.get_num()):
			viewbox = Rect2(0, 0, attributes.width.get_num(), attributes.height.get_num())
		else:
			viewbox = Rect2(0, 0, 0, 0)
	# Cache canvas transform.
	var width_ratio := width / viewbox.size.x
	var height_ratio := height / viewbox.size.y
	if width_ratio < height_ratio:
		canvas_transform = Transform2D(0.0, Vector2(width_ratio, width_ratio), 0.0,
				-viewbox.position * width_ratio +\
				Vector2(0, (height - width_ratio * viewbox.size.y) / 2))
	else:
		canvas_transform = Transform2D(0.0, Vector2(height_ratio, height_ratio), 0.0,
				-viewbox.position * height_ratio +\
				Vector2((width - height_ratio * viewbox.size.x) / 2, 0))


func canvas_to_world(pos: Vector2) -> Vector2:
	return canvas_transform * pos

func world_to_canvas(pos: Vector2) -> Vector2:
	return canvas_transform.affine_inverse() * pos


func get_size() -> Vector2:
	return Vector2(width, height)


func get_all_tids() -> Array[PackedInt32Array]:
	var tids: Array[PackedInt32Array] = []
	var unchecked_tids: Array[PackedInt32Array] = []
	for idx in get_child_count():
		unchecked_tids.append(PackedInt32Array([idx]))
	
	while not unchecked_tids.is_empty():
		var checked_tid: PackedInt32Array = unchecked_tids.pop_back()
		var checked_tag: Tag = get_tag(checked_tid)
		for idx in checked_tag.get_child_count():
			var new_tid := checked_tid.duplicate()
			new_tid.append(idx)
			unchecked_tids.append(new_tid)
		tids.append(checked_tid)
	return tids

func get_tag(tid: PackedInt32Array) -> Tag:
	var current_tag: Tag = self
	for idx in tid:
		if idx >= current_tag.child_tags.size():
			return null
		current_tag = current_tag.child_tags[idx]
	return current_tag


func add_tag(new_tag: Tag, new_tid: PackedInt32Array) -> void:
	var parent_tid := Utils.get_parent_tid(new_tid)
	get_tag(parent_tid).child_tags.insert(new_tid[-1], new_tag)
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
		get_tag(tid).attribute_changed.connect(emit_child_attribute_changed)
	
	changed_unknown.emit()
	if old_size != get_size():
		resized.emit()

func delete_tags(tids: Array[PackedInt32Array]) -> void:
	if tids.is_empty():
		return
	
	tids = Utils.filter_descendant_tids(tids)
	for tid in tids:
		var parent_tid := Utils.get_parent_tid(tid)
		var parent_tag := get_tag(parent_tid)
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
	
	# For moving, all these tags must be direct children of the same parent.
	tids = Utils.filter_descendant_tids(tids)
	var depth := tids[0].size()
	var parent_tid := Utils.get_parent_tid(tids[0])
	for tid in tids:
		if tid.size() != depth or Utils.get_parent_tid(tid) != parent_tid:
			return
	
	var tid_indices: Array[int] = []  # The last indices of the TIDs.
	for tid in tids:
		tid_indices.append(tid[-1])
	
	var parent_tag := get_tag(parent_tid)
	var parent_child_count := parent_tag.get_child_count()
	var old_indices: Array[int] = []
	for k in parent_child_count:
		old_indices.append(k)
	# Do the moving.
	if down:
		var i := parent_child_count - 1
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
		var i := 0
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
	# Check if indices were really changed after the operation.
	if old_indices != range(old_indices.size()):
		tags_moved_in_parent.emit(parent_tid, old_indices)
		tag_layout_changed.emit()

# Moves tags to an arbitrary position. The first moved tag will move to the location TID.
func move_tags_to(tids: Array[PackedInt32Array], location: PackedInt32Array) -> void:
	tids = Utils.filter_descendant_tids(tids)
	# A tag can't move deeper inside itself. Remove the descendants of the location.
	for i in range(tids.size() - 1, -1, -1):
		if Utils.is_tid_parent(tids[i], location):
			tids.remove_at(i)
	
	# Remove tags from their old locations.
	var tids_stored: Array[PackedInt32Array] = []
	var tags_stored: Array[Tag] = []
	for tid in tids:
		# Shift the new location if tags before it were removed. A tag is "before"
		# if it has the same parent as the new location, but is before that location.
		if tid.size() <= location.size():
			var before := true
			for i in tid.size() - 1:
				if tid[i] != location[i]:
					before = false
					break
			if before and tid[-1] < location[tid.size() - 1]:
				location[tid.size() - 1] -= 1
		tids_stored.append(tid)
		tags_stored.append(get_tag(Utils.get_parent_tid(tid)).child_tags.pop_at(tid[-1]))
	# Add the tags back in the new location.
	for tag in tags_stored:
		get_tag(Utils.get_parent_tid(location)).child_tags.insert(location[-1], tag)
	# Check if this actually chagned the layout.
	for tid in tids_stored:
		if not Utils.are_tid_parents_same(tid, location) or tid[-1] < location[-1] or\
		tid[-1] >= location[-1] + tids_stored.size():
			# If this condition is passed, then there was a layout change.
			tags_moved_to.emit(tids, location)
			tag_layout_changed.emit()
			return

# Duplicates tags and puts them below.
func duplicate_tags(tids: Array[PackedInt32Array]) -> void:
	if tids.is_empty():
		return
	
	tids = Utils.filter_descendant_tids(tids)
	var tids_added: Array[PackedInt32Array] = []
	# Used to offset previously added TIDs in tids_added after duplicating a tag before.
	var last_parent := PackedInt32Array([-1])  # Start with a TID that can't be matched.
	var added_to_last_parent := 0
	
	for tid in tids:
		var new_tag := get_tag(tid).create_duplicate()
		# Add the new tag.
		var new_tid := tid.duplicate()
		new_tid[-1] += 1
		var parent_tid := Utils.get_parent_tid(new_tid)
		get_tag(parent_tid).child_tags.insert(new_tid[-1], new_tag)
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

func replace_tag(tid: PackedInt32Array, new_tag: Tag) -> void:
	if tid.is_empty():
		replace_self(new_tag)
	get_tag(Utils.get_parent_tid(tid)).child_tags[tid[-1]] = new_tag
	new_tag.attribute_changed.connect(emit_child_attribute_changed)
	tag_changed.emit(tid)
	tag_layout_changed.emit()

func emit_child_attribute_changed(undo_redo: bool) -> void:
	child_attribute_changed.emit(undo_redo)

func emit_attribute_changed(undo_redo: bool) -> void:
	super(undo_redo)
	resized.emit()
