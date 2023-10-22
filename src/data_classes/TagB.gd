class_name TagB extends Tag  # B as in branch.

signal child_tag_attribute_changed
signal tag_added
signal tag_deleted(tag_idx: int)
signal tag_moved(old_idx: int, new_idx: int)
signal changed_unknown

var child_tags: Array[Tag]

func add_tag(new_tag: Tag,create_undo_redo:bool = true) -> void:
	if create_undo_redo:
		EditorUndoRedo.undo_redo.create_action("Add tag")
		EditorUndoRedo.undo_redo.add_do_reference(new_tag)
		EditorUndoRedo.undo_redo.add_undo_reference(new_tag)
		EditorUndoRedo.undo_redo.add_do_method(add_tag.bind(new_tag,false))
		EditorUndoRedo.undo_redo.add_undo_method(delete_tag_with_reference.bind(new_tag,false))
		EditorUndoRedo.undo_redo.commit_action()
		return
	child_tags.append(new_tag)
	new_tag.attribute_changed.connect(emit_child_tag_attribute_changed)
	tag_added.emit()

func add_tag_and_move_to(new_tag:Tag,to_idx:int):
	add_tag(new_tag)
	var from_idx = child_tags.find(new_tag)
	move_tag(from_idx,to_idx)

func replace_tags(new_tags: Array[Tag]) -> void:
	child_tags.clear()
	for tag in new_tags:
		child_tags.append(tag)
		tag.attribute_changed.connect(emit_child_tag_attribute_changed)
	changed_unknown.emit()

func delete_tag(idx: int,create_undo_redo:bool = true) -> void:
	if create_undo_redo:
		var tag:Tag = child_tags[idx]
		EditorUndoRedo.undo_redo.create_action("delete tag")
		EditorUndoRedo.undo_redo.add_do_reference(tag)
		EditorUndoRedo.undo_redo.add_undo_reference(tag)
		EditorUndoRedo.undo_redo.add_do_method(delete_tag_with_reference.bind(tag,false))
		EditorUndoRedo.undo_redo.add_undo_method(add_tag_and_move_to.bind(tag,idx))
		EditorUndoRedo.undo_redo.commit_action()
		return
	if idx >= 0:
		child_tags.remove_at(idx)
		tag_deleted.emit(idx)

func delete_tag_with_reference(tag:Tag,create_undo_redo:bool = true) -> void:
	var idx = child_tags.find(tag)
	delete_tag(idx,create_undo_redo)

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
		new_tag.attributes[attribute].value = tag_to_dupe.attributes[attribute].value
	# Add the new tag.
	child_tags.insert(idx + 1, new_tag)
	new_tag.attribute_changed.connect(emit_child_tag_attribute_changed)
	tag_added.emit()


func emit_child_tag_attribute_changed() -> void:
	child_tag_attribute_changed.emit()

func get_child_count() -> int:
	return child_tags.size()
