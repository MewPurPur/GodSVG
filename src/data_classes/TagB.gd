class_name TagB extends Tag  # B as in branch.

signal child_tag_attribute_changed
signal tag_added
signal tag_deleted(tag_idx: int)
signal tag_moved(old_idx: int, new_idx: int)
signal changed_unknown

var child_tags: Array[Tag]

func add_tag(new_tag: Tag,create_undo_redo:bool = true) -> void:
	if create_undo_redo:
		tagb_undo_redo_action(
			"Add tag",
			add_tag.bind(new_tag,false),
			delete_tag_with_reference.bind(new_tag,false),
			new_tag)
		return
	child_tags.append(new_tag)
	new_tag.attribute_changed.connect(emit_child_tag_attribute_changed)
	tag_added.emit()

func add_tag_and_move_to(new_tag:Tag,to_idx:int) -> void:
	child_tags.insert(to_idx, new_tag)
	tag_added.emit()

func replace_tags(new_tags: Array[Tag]) -> void:
	child_tags.clear()
	for tag in new_tags:
		child_tags.append(tag)
		tag.attribute_changed.connect(emit_child_tag_attribute_changed)
	changed_unknown.emit()

func delete_tag(idx: int,create_undo_redo:bool = true) -> void:
	if create_undo_redo:
		var tag:Tag = child_tags[idx]
		tagb_undo_redo_action(
			"Delete tag",
			delete_tag_with_reference.bind(tag,false),
			add_tag_and_move_to.bind(tag,idx),
			tag)
		return
	if idx >= 0:
		child_tags.remove_at(idx)
		tag_deleted.emit(idx)

func delete_tag_with_reference(tag:Tag,create_undo_redo:bool = true) -> void:
	var idx = child_tags.find(tag)
	delete_tag(idx,create_undo_redo)

func move_tag(old_idx: int, new_idx: int,create_undo_redo:bool = true) -> void:
	if create_undo_redo:
		tagb_undo_redo_action(
			"Move tag",
			move_tag.bind(old_idx , new_idx,false),
			move_tag.bind(new_idx, old_idx,false))
		return
	var tag: Tag = child_tags.pop_at(old_idx)  # Should be inferrable, GDScript bug.
	child_tags.insert(new_idx, tag)
	tag_moved.emit(old_idx, new_idx)

func duplicate_tag(idx: int, create_undo_redo:bool = true) -> void:
	var new_tag :Tag = child_tags[idx].duplicate()
	new_tag.attribute_changed.connect(emit_child_tag_attribute_changed)
	if create_undo_redo:
		tagb_undo_redo_action(
			"Duplicate tag",
			add_tag_and_move_to.bind(new_tag,idx + 1),
			delete_tag_with_reference.bind(new_tag,false),
			new_tag)
		return
	add_tag_and_move_to(new_tag,idx + 1)
	
func emit_child_tag_attribute_changed() -> void:
	child_tag_attribute_changed.emit()

func get_child_count() -> int:
	return child_tags.size()

func tagb_undo_redo_action(name:String,do:Callable,undo:Callable,add_reference:Object = null) -> void:
	UndoRedoManager.create_action(name)
	UndoRedoManager.add_do_reference(add_reference)
	UndoRedoManager.add_undo_reference(add_reference)
	UndoRedoManager.add_do_method(do)
	UndoRedoManager.add_undo_method(undo)
	UndoRedoManager.commit_action()
