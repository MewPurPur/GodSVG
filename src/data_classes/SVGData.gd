class_name SVGData extends RefCounted

signal attribute_changed
signal resized
signal tag_added
signal tag_deleted(idx: int)
signal tag_moved
signal changed_unknown

var width := 16.0
var height := 16.0
var tags: Array[SVGTag]


func set_dimensions(new_width: float, new_height: float) -> void:
	var is_width_different := width != new_width
	var is_height_different := height != new_height
	# Ensure the signal is not emitted unless dimensions have really changed.
	if is_width_different or is_height_different:
		if is_width_different:
			width = new_width
		if is_height_different:
			height = new_height
		resized.emit()

func set_width(new_width: float) -> void:
	if width != new_width:
		width = new_width
		resized.emit()

func set_height(new_height: float) -> void:
	if height != new_height:
		height = new_height
		resized.emit()


func emit_attribute_changed() -> void:
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
