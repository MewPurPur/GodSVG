extends Node

signal hover_changed
signal selection_changed

var hovered_tag := -1
var selected_tags: Array[int] = []

func _ready() -> void:
	SVG.root_tag.tag_deleted.connect(_on_tag_deleted)
	SVG.root_tag.tag_moved.connect(_on_tag_moved)

func toggle_selection(idx: int) -> void:
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

func set_hovered(idx: int) -> void:
	if hovered_tag != idx:
		hovered_tag = idx
		hover_changed.emit()

func remove_hovered(idx: int) -> void:
	if hovered_tag == idx:
		hovered_tag = -1
		hover_changed.emit()

func clear_hovered() -> void:
	if hovered_tag != -1:
		hovered_tag = -1
		hover_changed.emit()


func _on_tag_deleted(idx: int) -> void:
	selected_tags.erase(idx)

func _on_tag_moved(old_idx: int, new_idx: int) -> void:
	for i in selected_tags.size():
		var idx := selected_tags[i]
		if (idx < old_idx and idx < new_idx) or (idx > old_idx and idx > new_idx):
			continue
		elif idx > old_idx and idx < new_idx:
			selected_tags[i] += 1
		elif idx <= old_idx and idx > new_idx:
			selected_tags[i] -= 1
		elif idx == old_idx:
			selected_tags[i] = new_idx


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"delete"):
		for tag_idx in selected_tags:
			SVG.root_tag.delete_tag(tag_idx)
	elif event.is_action_pressed(&"move_up"):
		var unaffected := 0
		selected_tags.sort()
		for tag_idx in selected_tags:
			if tag_idx == unaffected:
				unaffected += 1
				continue
			SVG.root_tag.move_tag(tag_idx, tag_idx - 1)
	elif event.is_action_pressed(&"move_down"):
		var unaffected := SVG.root_tag.get_child_count() - 1
		selected_tags.sort()
		selected_tags.reverse()
		for tag_idx in selected_tags:
			if tag_idx == unaffected:
				unaffected -= 1
				continue
			SVG.root_tag.move_tag(tag_idx, tag_idx + 1)
