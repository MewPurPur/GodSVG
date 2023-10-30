## A tag that may hold other tags within it, i.e. [code]<tag></tag>[/code]
class_name TagB extends Tag

signal child_tag_attribute_changed
signal tag_added
signal tags_deleted(tag_indices: Array[int])
signal tag_moved(old_idx: int, new_idx: int)
signal changed_unknown

var child_tags: Array[Tag]

func add_tag(new_tag: Tag) -> void:
	child_tags.append(new_tag)
	new_tag.attribute_changed.connect(emit_child_tag_attribute_changed)
	tag_added.emit()

func replace_self(new_tag: TagB) -> void:
	for attrib in attributes:
		attributes[attrib].set_value(new_tag.attributes[attrib].get_value(), false)
	
	child_tags.clear()
	for tag in new_tag.child_tags:
		child_tags.append(tag)
		tag.attribute_changed.connect(emit_child_tag_attribute_changed)
	changed_unknown.emit()


func delete_tags(idx_arr: Array[int]) -> void:
	idx_arr.sort()
	for idx_idx in range(idx_arr.size() - 1, -1, -1):
		var idx = idx_arr[idx_idx]
		if idx >= 0:
			child_tags.remove_at(idx)
	tags_deleted.emit(idx_arr)

func move_tag(old_idx: int, new_idx: int) -> void:
	var tag: Tag = child_tags.pop_at(old_idx)  # Should be inferrable, GDScript bug.
	child_tags.insert(new_idx, tag)
	tag_moved.emit(old_idx, new_idx)

func duplicate_tag(idx: int) -> void:
	# Custom logic for this... Blah.
	var tag_to_dupe := child_tags[idx]
	var type: GDScript = child_tags[idx].get_script()
	var new_tag = type.new()
	for attribute in new_tag.attributes:
		new_tag.attributes[attribute].set_value(
				tag_to_dupe.attributes[attribute].get_value())
	# Add the new tag.
	child_tags.insert(idx + 1, new_tag)
	new_tag.attribute_changed.connect(emit_child_tag_attribute_changed)
	tag_added.emit()


func emit_child_tag_attribute_changed() -> void:
	child_tag_attribute_changed.emit()

func get_child_count() -> int:
	return child_tags.size()
