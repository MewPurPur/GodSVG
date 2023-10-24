class_name TagB extends Tag  # B as in branch.

signal child_tag_attribute_changed(child:Tag)
signal tag_added(child:Tag)
signal tag_deleted(tag_idx: int, child:Tag,)
signal tag_moved(old_idx: int, new_idx: int)
signal changed_unknown

var child_tags: Array[Tag]

func add_tag(new_tag: Tag) -> void:
	child_tags.append(new_tag)
	new_tag.attribute_changed.connect(emit_child_tag_attribute_changed.bind(new_tag))
	tag_added.emit(new_tag)

func add_tag_and_move_to(new_tag:Tag,to_idx:int) -> void:
	child_tags.insert(to_idx, new_tag)
	tag_added.emit(new_tag)

func replace_tags(new_tags: Array[Tag]) -> void:
	child_tags.clear()
	for tag in new_tags:
		child_tags.append(tag)
		tag.attribute_changed.connect(emit_child_tag_attribute_changed.bind(tag))
	changed_unknown.emit()

func delete_tag(idx: int) -> void:
	if idx >= 0:
		var deleted_tag = get_child_tag(idx)
		child_tags.remove_at(idx)
		tag_deleted.emit(idx,deleted_tag)

func move_tag(old_idx: int, new_idx: int) -> void:
	var tag: Tag = child_tags.pop_at(old_idx)  # Should be inferrable, GDScript bug.
	child_tags.insert(new_idx, tag)
	tag_moved.emit(old_idx, new_idx)

func duplicate_tag(idx: int) -> void:
	var new_tag :Tag = get_child_tag(idx).duplicate()
	new_tag.attribute_changed.connect(emit_child_tag_attribute_changed.bind(new_tag))
	add_tag_and_move_to(new_tag,idx + 1)

func delete_tag_with_reference(tag:Tag) -> void:
	delete_tag(find_child_tag(tag))

func emit_child_tag_attribute_changed(changed_tag:Tag) -> void:
	child_tag_attribute_changed.emit(changed_tag)

func get_child_count() -> int:
	return child_tags.size()

func find_child_tag(child:Tag) -> int:
	return child_tags.find(child)

func get_child_tag(idx:int) -> Tag:
	return child_tags[idx]

