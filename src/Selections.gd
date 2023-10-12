extends Node

signal selection_changed

var selected_tags: Array[int] = []

func _ready() -> void:
	SVG.data.tag_deleted.connect(_on_tag_deleted)

func toggle_index(idx: int) -> void:
	if idx >= 0:
		var idx_idx := selected_tags.find(idx)
		if idx_idx == -1:
			selected_tags.append(idx)
			selection_changed.emit()
		else:
			selected_tags.remove_at(idx_idx)
			selection_changed.emit()

func set_selection(idx: int) -> void:
	if selected_tags.size() != 1 or selected_tags[0] != idx:
		selected_tags = [idx]
		selection_changed.emit()

func clear_selection() -> void:
	selected_tags.clear()
	selection_changed.emit()

func _on_tag_deleted(idx: int) -> void:
	selected_tags.erase(idx)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_DELETE:
			for tag_idx in Selections.selected_tags:
				SVG.data.delete_tag(tag_idx)
