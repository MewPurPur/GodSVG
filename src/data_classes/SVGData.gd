class_name SVGData extends RefCounted

signal attribute_changed
signal resized
signal tag_added
signal tag_deleted(idx: int)
signal tag_moved
signal changed_unknown

var w := 16.0:
	set(new_w):
		if w != new_w:
			w = new_w
			resized.emit()

var h := 16.0:
	set(new_h):
		if h != new_h:
			h = new_h
			resized.emit()

var tags: Array[SVGTag]

func emit_attribute_changed():
	attribute_changed.emit()


func add_tag(new_tag: SVGTag) -> void:
	tags.append(new_tag)
	new_tag.attribute_changed.connect(emit_attribute_changed)
	tag_added.emit()

func replace_tags(new_tags: Array[SVGTag]) -> void:
	tags.clear()
	for tag in new_tags:
		tags.append(tag)
		tag.attribute_changed.connect(emit_attribute_changed)
	changed_unknown.emit()

func delete_tag(idx: int) -> void:
	if idx >= 0:
		tags.remove_at(idx)
		tag_deleted.emit(idx)

func move_tag(old_idx: int, new_idx: int) -> void:
	var tag: SVGTag = tags.pop_at(old_idx)  # Should be inferrable, GDScript bug.
	tags.insert(new_idx, tag)
	tag_moved.emit()


func get_tag_count() -> int:
	return tags.size()
