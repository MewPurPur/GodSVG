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


func add_tag(tag: SVGTag) -> void:
	tag.attribute_changed.connect(emit_attribute_changed)
	tags.append(tag)
	tag_added.emit()

func delete_tag(idx: int) -> void:
	tags.remove_at(idx)
	tag_deleted.emit()
