class_name SVGData extends RefCounted

signal attribute_changed
signal resized
signal tag_added
signal tag_deleted
signal tag_moved  # TODO
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
	tags.remove_at(idx)
	tag_deleted.emit()
