extends CodeEdit

func _ready() -> void:
	auto_update_text()
	SVG.data.resized.connect(auto_update_text)
	SVG.data.attribute_changed.connect(auto_update_text)
	SVG.data.tag_added.connect(auto_update_text)
	SVG.data.tag_deleted.connect(auto_update_text)
	SVG.data.tag_moved.connect(auto_update_text)
	SVG.data.changed_unknown.connect(auto_update_text)

func auto_update_text() -> void:
	if not has_focus():
		text = SVG.tags_to_string()
